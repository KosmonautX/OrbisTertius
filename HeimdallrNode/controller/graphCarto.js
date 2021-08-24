const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
  region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash')
const MAX_TERRITORIES = 3
var Graph = {} // maps
Graph.Edge = (function () {
  `use strict`

  //init state
  var state = {TableName: ddb_config.tableNames.orb_table};
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
    state = {TableName: ddb_config.tableNames.orb_table,
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
  var map_editor  = async (locmap, radius=30) => {
    territory = {}
    Object.entries(locmap).slice(0,MAX_TERRITORIES).forEach(([name, address]) =>{
      address = geohasher(address, radius)
      map.set(name, address)
      territory[name] = {hash: address.geohashing, granularity: radius}
    })
    return territory
  };

  var map_creator  = async (locmap, radius=30) => {
    territory = {}
    Object.entries(locmap).slice(0,MAX_TERRITORIES).forEach(([name, address]) =>{
      addressed = geohasher(address, radius)
      locmap[name] = addressed
      territory[name] = {hash: addressed.geohashing, granularity: radius}
    })
    map.rebirth(locmap)
    return territory
  };

  var territorialization= async (agent, territory) => {
    territory.then((data) => {
      const params = {
        TableName: ddb_config.tableNames.orb_table,
        Key: {
          PK: "USR#" + agent,
          SK: "USR#" + agent + "#pub"
        },
        UpdateExpression: "set #geo = :ter",
        ExpressionAttributeNames:{
          "#geo": "geohash"
        },
        ExpressionAttributeValues: {
          ":ter": data
        }
      };
      docClient.update(params, function(err, data) {
        if (err) console.log(err);
        else console.log(data);
      });
    })
  }

  var reterritorialisation = async(agent, territory) => {
    territory.then((data)=>{
      let params = {
        TableName: ddb_config.tableNames.orb_table,
        Key: {
          PK: "USR#" + agent,
          SK: "USR#" + agent + "#pub"
        },
        ExpressionAttributeNames: {},
        ExpressionAttributeValues: {}
      }
      Object.entries(data).slice(0,MAX_TERRITORIES).forEach(([geoName, address]) => {
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
      address.geohashing = geohash.latlon_to_geo(address.latlon, radius);
      address.geohashing52 = geohash.latlon_to_geo52(address.latlon); //curry 52 in the future
    }
    else if(address.postal)
    {
      address.geohashing = geohash.postal_to_geo(address.postal, radius)
      address.geohashing52 = geohash.postal_to_geo52(address.postal)
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
      reterritorialisation(userID, territory)
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
