const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');

const dynaUser = {
    async buddy(alpha,beta,friendshiptime) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "USR#" + alpha + "#REL",
                SK: "BUD#" + beta,
                time: friendshiptime,
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async bully(alpha,beta,endshiptime) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "USR#" + alpha + "#REL",
                SK: "BUL#" + beta,
                time: endshiptime,
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async updatePayload(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set payload = :payload",
            // ConditionExpression: "",
            ExpressionAttributeValues: {
                ":payload": {
                    bio: body.bio,
                    birthday: body.birthday,
                    profile_pic: body.profile_pic,
                    media: body.media
                }
            },
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async blockUser(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "USR#" + body.user_id + "#REL",
                SK: "BUL#" + body.block_id,
                time: moment().unix(),
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async usernameTransaction(body) {
        const params = {
            "TransactItems": [
                {
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        ConditionExpression: "attribute_not_exists(PK)",
                        Item: {
                            PK: "username#" + body.username,
                            SK: "username#" + body.username,
                            alphanumeric: body.user_id,
                            time: moment().unix()
                        }
                    }
                },
                {
                    Delete: {
                        TableName: ddb_config.tableNames.orb_table,
                        // ConditionExpression: "attribute_exists(PK)",
                        Key: {
                            PK: "username#" + body.old_username,
                            SK: "username#" + body.old_username
                        }
                    }
                },
            ] 
        };
        const data = await docClient.transactWrite(params).promise();
        if (!data || !data.Item) {
            return true;
        }
        return data;
    }
}

const userQuery = {
    async queryPTE(body, arr) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pte"
            },
            AttributesToGet: arr
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    async queryPUB(user_id) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + user_id,
                SK: "USR#" + user_id + "#pub"
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    // takes in a (str) USERNAME
    async checkUsername (username) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "username#" + username,
                SK: "username#" + username
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
}

module.exports = {
    dynaUser: dynaUser,
    userQuery: userQuery,
};
