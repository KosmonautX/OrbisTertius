const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});

var Land = {} // plane that cuts through network

Land.Entity = (function () {
    `use strict`

    //init state
    var state = {TableName: ddb_config.tableNames.orb_table};
    //add public facing interface
	var interface_dao = {};

    time = function() {
        state.UpdateExpression = 'SET #t = :time';
        state.ExpressionAttributeNames = {"#t": "time",};
        state.ExpressionAttributeValues = {":time": moment().unix()};
        state.ReturnValues= 'ALL_OLD'
    }

    condition = function(fields){
        state.Item.alphanumeric = fields
        state.ConditionExpression = "attribute_not_exists(PK)";
        state.ReturnValues = 'ALL_OLD';
    }

    projection = function(array) {
        state.ProjectionExpression = array.join(', ')
    }

	// private method declares wished future state in database (upsert)
    wish = async() => {
        return await docClient.update(state).promise();
     }
    //closure  private method recalls past state
    recall = async() =>{
        return await docClient.get(state).promise();
    }



    // pattern refers to the data access required by DynamoDb
    entity_init  = function(_dBaction,_archetype, _id, _access, _bridge=false){
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
            state[patternStr].SK = state[patternStr].PK+ '#' + _access + '#' + _bridge;
        }
        else if (_access) {
            state[patternStr].PK = _archetype + '#' + _id;
            state[patternStr].SK = state[patternStr].PK+ '#' + _access;

        } else {
            state[patternStr].PK = _archetype + '#' + _id;
            state[patternStr].SK = state[patternStr].PK
        }
    }

	// A public method to claim about world state
	interface_dao.claim = (archetype, id, access, tie, dbaction) => {
        entity_init(archetype, id, access, tie, dbaction);
    };

    interface_dao.affirm = async (archetype, id, fields) => {
        entity_init("PUT",archetype, id);
        condition(fields);
        return await docClient.put(state).promise();
    }

    interface_dao.upsert = async () => {
        time();
        return await wish();
    };

    interface_dao.exist = async() =>{
        projection(['PK']);
        return await recall();

    };

	// access public methods
	return interface_dao;

})();

module.exports ={
    Land: Land
}
