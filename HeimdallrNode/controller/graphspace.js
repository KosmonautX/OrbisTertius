const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const Network = {TableName: ddb_config.tableNames.orb_table, Key:{}}

var Land = {} // plane that cuts through network

Land.Entity = (function (archetype, id ,access) {
    //init state
    var state = Network;
    //add public facing interface
	var interface = {};

    time = function() {
        state.UpdateExpression = 'SET #t = :time';
        state.ExpressionAttributeNames = {"#t": "time",};
        state.ExpressionAttributeValues = {":time": moment().unix()};
        state.ReturnValues= 'ALL_OLD'
    }

    projection = function(array) {
        state.ProjectionExpression = array.join(', ')
    }

	// private method declares wished future state in database (upsert)
    wish = async() => {
        return await docClient.update(state).promise();
     }
    // private method recalls past state
    recall = async() =>{
        return await docClient.get(state).promise();
    }

	// A public method
	interface.claim = (_archetype, _id, _access) => {
        if (_access) {
        state.Key.PK = _archetype + '#' + _id;
        state.Key.SK = state.Key.PK+ '#' + _access;

        } else {
            state.Key.PK = _archetype + '#' + _id;
            state.Key.SK = state.Key.PK
        }

    };

    interface.upsert = async () => {
        time();
        return await wish();
    };

    interface.exists = async() =>{
        projection(['PK']);
        return await recall();

    };

	// access public methods
	return interface;

})();

module.exports ={
    Land: Land
}
