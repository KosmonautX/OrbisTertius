const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');

const dynaUser = {
    async transacCreate(body) {
        const params = {
            "TransactItems": [
                {
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        ConditionExpression: "attribute_not_exists(PK)",
                        Item: {
                            PK: "USR#" + body.user_id, 
                            SK: "USR#" + body.user_id + "#pub",
                            alphanumeric: body.username,
                            numeric: body.geohashing.home,
                            geohash: body.geohashing.office, 
                            numeric2: body.geohashing52.home,
                            geohash2: body.geohashing52.office,
                            time: body.join_dt,
                            payload: {
                                bio: body.bio,
                                profile_pic: body.profile_pic,
                                verified: body.verified,
                                available: true
                            },
                        }
                    }
                },
                {
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        ConditionExpression: "attribute_not_exists(PK)",
                        Item: {
                            PK: "username#" + body.username,
                            SK: "username#" + body.username,
                            alphanumeric: body.user_id
                        }
                    }
                }
            ] 
        };
        const data = await docClient.transactWrite(params).promise();
        if (!data || !data.Item) {
            return true;
        }
        return data;
    },
    async bulkCreate(body) {
        const params = {
            RequestItems: {
                [ddb_config.tableNames.orb_table]: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "USR#" + body.user_id,
                                SK: "USR#" + body.user_id + "#pte",
                                numeric: body.loc.home,
                                geohash: body.loc.office, 
                                payload: {
                                    country_code: body.country_code,
                                    hp_number: body.hp_number,
                                    gender: body.gender,
                                    birthday: body.birthday, //DD-MM-YYYY
                                },
                            }
                        }
                    },
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
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
    async updateUserHome(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set #n = :home",
            ExpressionAttributeNames:{
                "#n": "numeric"
            },
            ExpressionAttributeValues: {
                ":home": body.home
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async updateUserHomeGeohash(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set #n = :home",
            ExpressionAttributeNames:{
                "#n": "numeric"
            },
            ExpressionAttributeValues: {
                ":home": body.home.geohashing ||geohash.postal_to_geo(body.home)
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async updateUserHomeGeohash52(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set #n = :home",
            ExpressionAttributeNames:{
                "#n": "numeric2"
            },
            ExpressionAttributeValues: {
                ":home": body.home.geohashing52 ||geohash.postal_to_geo52(body.home)
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async updateUserOffice(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set geohash = :office",
            ExpressionAttributeValues: {
                ":office": body.office,
            }
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
    async updateUserOfficeGeohash(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set geohash = :office",
            ExpressionAttributeValues: {
                ":office": body.office.geohashing || geohash.postal_to_geo(body.office),
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async updateUserOfficeGeohash52(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set geohash2 = :office",
            ExpressionAttributeValues: {
                ":office": body.office.geohashing52 || geohash.postal_to_geo52(body.office),
            }
        };
        const data = await docClient.update(params).promise();
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
    },
    // async uploadProfilePic(body) {
    //     const params = {
    //         TableName: ddb_config.tableNames.orb_table,        
    //         Key: {
    //             PK: "USR#" + body.user_id, 
    //             SK: "USR#" + body.user_id + "pub",
    //         },
    //         UpdateExpression: "set payload.profile_pic = :pic",
    //         ExpressionAttributeValues: {
    //             ":pic": body.upload
    //         }
    //     };
    //     const data = await docClient.update(params).promise();
    //     return data;
    // }
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
