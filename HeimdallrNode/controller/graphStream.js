const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
const { now } = require('moment');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});

var Stream = {}
Stream.Channel = (function () {
    `use strict`
    //init state
    var state = {TableName: ddb_config.tableNames.orb_table};
    var patternStr;
    //add public facing interface
	var interface_dao = {};

    var arrowoftime = {
        downstream: function(oldest){
            if(state.KeyConditionExpression) state.KeyConditionExpression += ` and SK <= :oldest`;
            state["ScanIndexForward"] = false
            state.ExpressionAttributeValues[":oldest"] = oldest.toString()
            // last evaluated key , scan direction
        },
        nowstream: function(){
            //if(state.KeyConditionExpression) state.KeyConditionExpression += ` and SK <= :now`;
            //state.ExpressionAttributeValues[":now"] = moment().unix().toString()

            state["ScanIndexForward"] = false
        }
        ,
        upstream: function(youngest){
            if(state.KeyConditionExpression) state.KeyConditionExpression += ` and SK >= :youngest`;
            state.ExpressionAttributeValues[":youngest"] = youngest.toString()
            state["ScanIndexForward"] = true
            // between last fetched orb time to current time

        }
    }

    var swim  = async() =>{
        return await docClient.query(state).promise();
    }

    var pagesofdestiny = {
        downstream: function(oldest){
            state["ScanIndexForward"] = true
            // last evaluated key , scan direction

        }
        ,
        upstream: function(youngest){
            state["ScanIndexForward"] = false
            // between last fetched orb time to current time

        }
    }

    var pagination = function(limit){
        state.Limit = limit
    }

    var filter = function(){
        state.FilterExpression = "#chrono > :nowish"
        state.ExpressionAttributeValues[":nowish"] = moment().unix()
        state.ExpressionAttributeNames = {"#chrono": "extinguish"} // filter for clean extinguish
        // filter extinguish
    }

    var entity_init = function(archetype, id, distributary){
        state = {TableName: ddb_config.tableNames.orb_table,
                 ExpressionAttributeValues: {}};
        stream = archetype + '#' + id + '#' + distributary
        state.KeyConditionExpression = "PK = :stream"
        state.ExpressionAttributeValues[":stream"] = stream
    }

    interface_dao.start  = async function (archetype, id, distributary){
        entity_init(archetype, id, distributary)
        pagination(8)
        arrowoftime.nowstream()
        filter()
        return await swim()
    }

    interface_dao.downstream  = async function (archetype, id, distributary,time){
        entity_init(archetype, id, distributary)
        pagination(8)
        arrowoftime.downstream(time)
        filter()
        return await swim()
    }

    interface_dao.upstream  = async function (archetype, id, distributary,time){
        entity_init(archetype, id, distributary)
        pagination(8)
        arrowoftime.upstream(time)
        //filter() NO Filter to disambiguate between to deactivation events that change "TIME" attribute that signal deactivation time
        return await swim()
    }

    return interface_dao;
})

module.exports = {

    Stream:Stream

}
