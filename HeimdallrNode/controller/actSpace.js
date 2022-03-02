const moment = require('moment'); // time of event
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const {v4 : uuidv4} = require('uuid');

action_space = {
    "INIT": {
        start: false,
        end: "600#INIT",
        initator: true
    },
    "ACPT":{
        start: false,
        end: "500#ACPT",
        acceptor: true
    },
    "INIT_PND":{
        start: "500#ACPT",
        end: "541#IPND",
        initator: true
    },
    "SUSP_INIT_PND":{
        start: "541#IPND",
        end: "500#ACPT",
        initator: true
    },
    "ACPT_PND":{
        start: "500#ACPT",
        end: "540#APND",
        acceptor: true
    },
    "SUSP_ACPT_PND":{
        start: "540#APND",
        end: "500#ACPT",
        acceptor: true
    },
    "INIT_COMPLETE":{
        start: "540#APND",
        end: "800#CMPL",
        initator: true
    },
    "ACPT_COMPLETE":{
        start: "541#IPND",
        end: "800#CMPL",
        acceptor: true
    }
}

var Space = {} // state space navigation

Space.Action = (function () {
    `use strict`
    var state = {TableName: ddb_config.tableNames.orb_table};


    //will the future action state
    var will = function(future_state){
        if(state.UpdateExpression) state.UpdateExpression += `, #action = :state`;
        else {state.UpdateExpression = 'SET #action = :state';}
        state.ExpressionAttributeNames["#action"]= "inverse"
        state.ExpressionAttributeValues[":state"] = future_state + "#" + moment().unix()
    }

    var time = function() {
        if(state.UpdateExpression) state.UpdateExpression += `, #t = :time`;
        else state.UpdateExpression = 'SET #t = :time';
        state.ExpressionAttributeNames["#t"] ="time"
        state.ExpressionAttributeValues[":time"] =moment().unix()
    }
    // Composite Keys where PK != SK are not nodes but edges (init handles)
    //
    // check for current absence of state or existence of state as initial transition
    // create transition action space for state machine
    // eg. acpt -> i_pend -> completion by acceptor(action) UPDATE inverse
    // // eg. acpt -> a_pend -> completion by initiator(action) UPDATE inverse
    // agent check for init different through orb init
    // deactivation implementation//
    var interface_dao= {};

    // implement further encapsulation
    var condition = (function(){
        // Composite Keys are vertices not edges (init handles)
        var internal_dao= {};

        absence = function(edge,operator=''){
            state.ConditionExpression += operator +`attribute_not_exists(${edge})`;
            state.ExpressionAttributeValues[":buffer"] =buffer
        }

        past_action = function(edge, start_state, operator=''){
            state.ConditionExpression += operator +`begins_with(${edge}, :past)`;
            state.ExpressionAttributeValues[":past"] = start_state
        }

        timesensitivity = function(buffer,operator=''){
            buffer = moment().unix() - buffer
            state.ExpressionAttributeNames["#t"]= "time"
            state.ExpressionAttributeValues[":buffer"] =buffer
            state.ConditionExpression+= operator+"#t > :buffer"
        }
        match = function(edge,field,operator=''){
            state.ExpressionAttributeNames["#indb"]= edge
            state.ExpressionAttributeValues[":outdb"] = field
            state.ConditionExpression+=operator+"#indb = :outdb"
        }

        internal_dao.guard = function(action_move, orb_uuid, user_id){
            state.ConditionExpression = new String();
            state.ExpressionAttributeValues={}
            if(action_move.start) past_action("inverse", action_move.start)
            else absence("SK")
            state.ExpressionAttributeNames={}
            if(action_move.acceptor) match("SK", "USR#" + user_id, " AND ")
            else if(action_move.initator) match("alphanumeric", "USR#" + user_id, " AND ")
        }

        return internal_dao

    })();

    var action_construct = function(node_archetype, node_id, arc_archetype, arc_id){
        patternStr = "Key"
        state[patternStr]= {}
        state[patternStr].PK = node_archetype + "#" + node_id
        state[patternStr].SK = arc_archetype + "#" + arc_id
    }


    // wish to transition in action space
    var wish = async() => {
        return await docClient.update(state).promise();
    }

    interface_dao.orb = async(user_id, orb_uuid, action, actor_id) => {
        action_move= action_space[action]
        if(user_id === actor_id) action_construct("ORB", orb_uuid, "USR", user_id )
        else action_construct("ORB", orb_uuid, "USR", actor_id )
        condition.guard(action_move, orb_uuid, user_id)
        state.UpdateExpression=""
        will(action_move.end)
        time()
        return await wish()
    }

    return interface_dao

})();

module.exports = {

    Space:Space

}
