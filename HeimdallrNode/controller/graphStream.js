const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});

Stream.Entity = (function (archetype, id ,access) {
    `use strict`

    //init state
    var state = {TableName: ddb_config.tableNames.orb_table, Key:{}};
    //add public facing interface
	var interface = {};

    time = function() {
        state.UpdateExpression = 'SET #t = :time';
        state.ExpressionAttributeNames = {"#t": "time",};
        state.ExpressionAttributeValues = {":time": moment().unix()};
        state.ReturnValues= 'ALL_OLD'
    }


	// private method declares wished future state in database (upsert)
    wish = async() => {
        return await docClient.update(state).promise();
     }


    interface.exists = async() =>{
        projection(['PK']);
        return await recall();

    };

	// access public methods
	return interface;

})();
