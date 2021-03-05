const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');

const comment = {
    async postComment(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "COM#" + body.comment_id,
                SK: "COM#" + body.comment_id,
                time: moment().unix(),
                inverse: "USR#" + body.user_id,
                available: 1,
                payload: {
                    comment: body.comment,
                    orb_uuid: body.orb_uuid
                },
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async postCommentRel(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "COM#" + body.comment_id,
                time: moment().unix(),
                inverse: "USR#" + body.user_id,
                available: 1,
                payload: {
                    comment: body.comment
                },
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async postChildComment(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "COM#" + body.parent_id,
                SK: "COM#" + body.comment_id,
                time: moment().unix(),
                inverse: "USR#" + body.user_id,
                available: 1,
                payload: {
                    comment: body.comment
                },
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async checkComment(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :orb and begins_with(SK, :comment)",
            ExpressionAttributeValues: {
                ":orb": "ORB#" + body.orb_uuid,
                ":comment": "COM#",
            },
            ScanIndexForward: false,
        };
        const data = await docClient.query(params).promise();
        return data;
    },
    async queryComment(body) { // if retrieved comment id has same comment id requested, it is the parent comment
        const params = { // includes child comments
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :comment_id and begins_with(SK, :comment)",
            ExpressionAttributeValues: {
                ":comment_id": "COM#" + body.comment_id,
                ":comment": "COM#",
            },
            ScanIndexForward: false,
        };
        const data = await docClient.query(params).promise();
        return data;
    },
    async getComment(body) { // if retrieved comment id has same comment id requested, it is the parent comment
        const params = { // includes child comments
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "COM#" + body.parent_id,
                SK: "COM#" + body.comment_id,
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    async deleteComment (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "COM#" + body.parent_id, 
                SK: "COM#" + body.comment_id,
            },
            UpdateExpression: "set available = :delete",
            ExpressionAttributeValues: {
                ":delete": 0
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async deleteCommentRel (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "ORB#" + body.orb_uuid, 
                SK: "COM#" + body.comment_id,
            },
            UpdateExpression: "set available = :delete",
            ExpressionAttributeValues: {
                ":delete": 0
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
};

const orbSpace = {
    async deleteAcceptance(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id.toString(),
            },
        };
        const data = await docClient.delete(params).promise();
        return data;
    },
    // initiator
    async notInterested_i(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.acceptor_id.toString(),
                time: moment().unix(),
                inverse: "505#DISINTERESTED_INITIATOR",
                payload: {
                    who: body.user_id.toString()
                }
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    // acceptor
    async notInterested_a(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id.toString(),
                time: moment().unix(),
                inverse: "550#DISINTERESTED_ACCEPTOR",
                payload: {
                    who: body.user_id.toString()
                }
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
}

module.exports = {
    comment: comment,
    orbSpace: orbSpace,
};
