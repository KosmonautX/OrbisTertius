const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
  region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');
const { territory_markers, tableNames } = require('../config/ddb.config');
const MAX_TERRITORIES = 3 //
const COOLDOWN = 86400 * 7 // unix time for 7 days
var Graph = {} // maps
Graph.Edge = (function () {
  `use strict`

  //init state
  var state = {TableName: tableNames.orb_table};
  var patternStr;
  //add public facing interface
  var interface_dao = {};
  //wishes present state to change by map
  var wish = async() => {
    state.ReturnValues = 'ALL_NEW'
    return await docClient.update(state).promise();
  }


  //recalls present state of Location
  var recall = async() => {
    return await docClient.get(state).promise();
  }
  //map that is mutation vector for location prefs
  var map ={
    rebirth : function(addresses){
      if(state.UpdateExpression) state.UpdateExpression += `, #geoloc = :birthplace`;
      else {state.UpdateExpression = `SET #geoloc = :birthplace`;}
      state.ExpressionAttributeNames["#geoloc"]= "geohash"
      state.ExpressionAttributeValues[":birthplace"] = addresses
    },
    set : function(geoName,address){
      if(state.UpdateExpression) state.UpdateExpression += `, #geoloc.#${geoName} = :${geoName}`;
      else {state.UpdateExpression = `SET #geoloc.#${geoName} = :${geoName}`;}
      state.ExpressionAttributeNames["#geoloc"]= "geohash"
      state.ExpressionAttributeNames["#"+ geoName] = geoName
      state.ExpressionAttributeValues[":" + geoName] = address
    },
    remove : function(geoName, address){
      if(state.UpdateExpression) state.UpdateExpression += ', #geoloc = :geoloc';
      else {state.UpdateExpression = 'REMOVE #geoloc = :geoloc';}
      state.ExpressionAttributeNames["#geoloc"]= "geohash"
      state.ExpressionAttributeValues[":geoAddr"] = address
    }
  }
  //Entity with Geofields that need to be Mapped
  var entity_init  = function(_archetype, _id, _access=false, _bridge=false){
    state = {TableName: tableNames.orb_table,
             ExpressionAttributeNames: {},
             ExpressionAttributeValues: {}
            };
    patternStr = "Key" // update
    state[patternStr]= {}
    if(_bridge){
      state[patternStr].PK = _archetype + '#' + _id;
      state[patternStr].SK = state[patternStr].PK+ '#' + _access  + '#' + _bridge;
    }
    else if (_access) {
      state[patternStr].PK = _archetype + '#' + _id;
      state[patternStr].SK = state[patternStr].PK+ '#' + _access;

    } else {
      state[patternStr].PK = _archetype + '#' + _id;
      state[patternStr].SK = state[patternStr].PK
    }
  }
  var map_editor  = async (locmap, radius= territory_markers[0]) => {
    territory = {}
    Object.entries(locmap).slice(0,MAX_TERRITORIES).forEach(([name, address]) =>{
      address = geohasher(address, radius)
      map.set(name, address)
      territory[name] = {}
      territory[name].geohashing = address.geohashing
      territory[name].geohashingtiny = address.geohashingtiny
      territory[name].chronolock = moment().unix();
    })
    return territory
  };

  var map_creator  = async (locmap, radius=territory_markers[0]) => {
    territory = {}
    Object.entries(locmap).slice(0,MAX_TERRITORIES).forEach(([name, address]) =>{
      addressed = geohasher(address, radius)
      locmap[name] = addressed
      territory[name]= {}
      territory[name].geohashing = addressed.geohashing
      territory[name].geohashingtiny = addressed.geohashingtiny
      territory[name].chronolock = moment().unix();
    })
    map.rebirth(locmap)
    return territory
  };

  var territorialization= async (agent, territory) => {
    territory.then((data) => {
      const params = {
        TableName: tableNames.orb_table,
        Key: {
          PK: "USR#" + agent,
          SK: "USR#" + agent + "#pub"
        },
        UpdateExpression: "set #geo = :ter, #birthtime = :genesis",
        ExpressionAttributeNames:{
          "#geo": "geohash",
          "#birthtime": "time"
        },
        ConditionExpression: "attribute_not_exists(geohash)",
        ExpressionAttributeValues: {
          ":ter": data,
          ":genesis": moment().unix()
        }
      };
      docClient.update(params, function(err, data) {
        if (err) console.log(err);
        else console.log(data);
      });
    })
  }

  var reterritorialization = async(agent, territory) => {
    territory.then((data)=>{
      let params = {
        TableName: tableNames.orb_table,
        Key: {
          PK: "USR#" + agent,
          SK: "USR#" + agent + "#pub"
        },
        ExpressionAttributeNames: {},
        ExpressionAttributeValues: {}
      }
      Object.entries(data).slice(0,MAX_TERRITORIES).forEach(([geoName, address]) => {
        if(geoName !== "live"){
          if(params.ConditionExpression) params.ConditionExpression += `AND (attributes_not_exists(#geoloc.#${geoName}.chronolock) OR #geoloc.#${geoName}.chronolock < :cooldown)`
          else params.ConditionExpression = `(attribute_not_exists(#geoloc.#${geoName}.chronolock) OR #geoloc.#${geoName}.chronolock < :cooldown)`
          params.ExpressionAttributeValues[":cooldown"] = address.chronolock - COOLDOWN
        }
        if(params.UpdateExpression) params.UpdateExpression += `, #geoloc.#${geoName} = :${geoName}`;
        else {params.UpdateExpression = `SET #geoloc.#${geoName} = :${geoName}`;}
        params.ExpressionAttributeNames["#geoloc"]= "geohash"
        params.ExpressionAttributeNames["#"+ geoName] = geoName
        params.ExpressionAttributeValues[":" + geoName] = address
      })
      docClient.update(params, function(err, data) {
        if (err) console.log(err);
      });
    })
  }
  var geohasher = function (address, radius){
    if(address.latlon){
      address.geohashing = {hash: geohash.latlon_to_geo(address.latlon, radius), radius};
      address.geohashingtiny = geohash.latlon_to_geotiny(address.latlon); //curry 52 in the future
    }
    else if(address.postal)
    {
      address.geohashing = {hash: geohash.postal_to_geo(address.postal, radius), radius};
      address.geohashingtiny = geohash.postal_to_geotiny(address.postal)
    }
    return address
    // try async promise chaining here
  }

  interface_dao.loc_genesis = async (userID, request) => {
    try{
      entity_init("USR",userID,"pte")
      const {user_id, event, ...locmap } = request;
      territory = map_creator(locmap)
      territorialization(userID,territory)
      return await wish()
    } catch(err){
      console.log(err)
      new Error("Cartography Gen Failed")
    }
  };

  interface_dao.loc_update = async (userID, request) => {
    try{
      entity_init("USR",userID,"pte")
      const {user_id,event  , ...locmap } = request;
      territory = map_editor(locmap)
      reterritorialization(userID, territory)
      return await wish()
    } catch(err){
      console.log(err)
      new Error("Cartography Update Failed")
    }
  };
  // access public methods
  return interface_dao;

});

module.exports ={
  Graph:Graph
}
