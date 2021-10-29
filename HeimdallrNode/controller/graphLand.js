const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const {v4 : uuidv4} = require('uuid');

var Land = {} // plane that cuts through network

Land.Entity = (function () {
    `use strict`

    //init state
    var state = {TableName: ddb_config.tableNames.orb_table};
    var patternStr;
    //add public facing interface
	var interface_dao = {};

    var time = function() {
        state.UpdateExpression = 'SET #t = :time';
        state.ExpressionAttributeNames = {"#t":"time"}
        state.ExpressionAttributeValues = {":time": moment().unix()}
        state.ReturnValues= 'ALL_OLD'
    }

    var fieldweaver = function(edge,field) {
        if(state.UpdateExpression) state.UpdateExpression += ', #edge = :field';
        else state.UpdateExpression = 'SET #edge = :field';
        state.ExpressionAttributeNames["#edge"] = edge
        state.ExpressionAttributeValues[":field"] = field
        state.ReturnValues= 'ALL_OLD'
    }

    var identity ={
        set : function(deviceID){
            if(state.UpdateExpression) state.UpdateExpression += ', #did = :did';
            else {state.UpdateExpression = 'SET #did = :did';}
        state.ExpressionAttributeNames["#did"]= "identifier"
        state.ExpressionAttributeValues[":did"] =deviceID
        },

    }

    // implement further encapsulation
    var condition = (function(){
        // Composite Keys are vertices not edges (init handles)
        var internal_dao= {};
        internal_dao.absence = function(edge,operator=''){
            state.ConditionExpression += operator +`attribute_not_exists(${edge})`;
        }

        internal_dao.timesensitivity = function(buffer,operator=''){
            buffer = moment().unix() - buffer
            state.ExpressionAttributeNames["#t"]= "time"
            state.ExpressionAttributeValues[":buffer"] =buffer
            state.ConditionExpression+= operator+"#t > :buffer"
        }
        internal_dao.match = function(edge,field,operator=''){
            state.ExpressionAttributeNames["#indb"]= edge
            state.ExpressionAttributeValues[":outdb"] = field
            state.ConditionExpression+=operator+"#indb = :outdb"
       }
        return internal_dao
    })();

 

    var projection = function(array) {
        state.ProjectionExpression = array.join(', ')
    }

	// private method declares wished future state in database (upsert)
    var wish = async() => {
        return await docClient.update(state).promise();
     }
    
    //closure  private method recalls past state
    var recall = async() =>{
        return await docClient.get(state).promise();
    }
    // pattern refers to the data access required by DynamoDb
    var entity_init  = function(_dBaction,_archetype, _id, _access=false, _bridge=false){
        state = {TableName: ddb_config.tableNames.orb_table};
        switch (_dBaction){
            case "PUT":
                patternStr = "Item"
                break;
            case "UPDATE":
                patternStr = "Key"
                break;
        }
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

    var gen = async(archetype,access,identifier=false) => {
        try{
            let genUUID = uuidv4();
            entity_init("PUT",archetype,genUUID,access)
            state.ConditionExpression = new String();
            condition.absence("PK");
            state.Item.time = moment().unix();
            if(identifier) state.Item.identifier = identifier
            const data = await docClient.put(state).promise();
            return genUUID;
        } catch (err){
            if (err.code == 'ConditionalCheckFailedException'){
                return gen();
            }
            else{
                return err;
            }
        }
    }

	// A public method to claim about world state
	interface_dao.usergen = async (source,identifier,deviceID) =>{
        //user genesis update mail, check unique id create deviceidbridge
        try{
        if(source==="email")
        {
            user_id = await gen("USR","pte",deviceID)
            entity_init("UPDATE","MSG",identifier)
            state.ConditionExpression = new String();
            state.ExpressionAttributeNames = {};
            state.ExpressionAttributeValues= {};
            condition.absence("alphanumeric")
            condition.timesensitivity(600," AND ")
            condition.match("identifier", deviceID," AND ")
            fieldweaver("alphanumeric",user_id)
            state.ReturnValues="UPDATED_NEW"
            return await wish()
        }} catch(err){
            console.log(err)
            new Error("User Genesis Failed")
            }
         };
    interface_dao.fyrgen = async(userID,deviceID) => {
        try{
            interface_dao.spawn("USR",userID,"pte")
            return interface_dao.upsert(deviceID)
        } catch(err){
            console.log(err)
            new Error("User Genesis Failed")
            }
    };

    interface_dao.telegen = async(userID,username) => {
        try{
            interface_dao.spawn("USR",userID,"pub")
            time();
            identity.set("telegram");
            //fieldweaver("payload", {bio:"Hello from Telegram"})
            fieldweaver("alphanumeric", username)
            return await wish();
        } catch(err){
            console.log(err)
            new Error("User Genesis Failed")
            }
    };

    interface_dao.fcmtoken = async(userID,token) => {
        try{
            interface_dao.spawn("USR",userID,"pub")
            return interface_dao.untimedupsert(token)
        } catch(err){
            console.log(err)
            new Error("Firebase Cloud Token Update Failed")
            }

    };

    interface_dao.affirm = async (archetype, id, fields) => {
        entity_init("PUT",archetype, id);
        condition("alphanumeric",fields);
        return await docClient.put(state).promise();
    };

    interface_dao.init = function (archetype, id,access,deviceID=false){
        entity_init("UPDATE",archetype, id, access);
        return interface_dao.upsert(deviceID)

    }

    interface_dao.spawn = function (archetype, id,access,deviceID=false){
        entity_init("UPDATE",archetype, id, access);
    }

    // update event and identifiers(login) edge/field later
    interface_dao.upsert = async (deviceID=false) => {
        time();
        if(deviceID) identity.set(deviceID)
        return await wish();
    };

    interface_dao.untimedupsert = async (deviceID=false) => {
        state.ReturnValues= 'ALL_NEW';
        state.ExpressionAttributeNames={}
        state.ExpressionAttributeValues={}
        if(deviceID) identity.set(deviceID)
        return await wish();
    };

    // conditional update check device id identical (signup)

    interface_dao.exist = async() =>{
        projection(['PK','identifier','geohash', 'alphanumeric']);
        return await recall();

    };

	// access public methods
	return interface_dao;

});

module.exports ={
    Land: Land
}
