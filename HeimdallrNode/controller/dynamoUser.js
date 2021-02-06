const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
})
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');

const dynaUser = {
    async Tcreate(body) {
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
                            numeric: body.geohashing.first,
                            geohash: body.geohashing.second,
                            numeric2: body.geohashing52.first,
                            geohash2: body.geohashing52.second,
                            payload: {
                                commercial: true
                            }
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
    async Bcreate(body) {
        const params = {
            RequestItems: {
                ORB_NET: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "USR#" + body.user_id,
                                SK: "USR#" + body.user_id + "#pte",
                                numeric: body.first,
                                geohash: body.second, 
                                payload: {
                                    gender: body.gender,
                                    age: body.age, 
                                    join_dt: body.join_dt
                                },
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "LOC#" + body.geohashing.first,
                                SK: "USRc#" + body.user_id,
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "LOC#" + body.geohashing.second,
                                SK: "USRc#" + body.user_id,
                            }
                        }
                    },
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async getPTEinfo(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pte"
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    async getPUBinfo(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,      
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    async getAllUsers(geohash) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and begins_with(SK, :user)",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohash,
                ":user": "USR",
            },
        }
        const data = await docClient.query(params).promise();
        return data;
    },
    async getCommercialUsers(geohash) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and begins_with(SK, :user)",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohash,
                ":user": "USRc#",
            },
        };
        const data = await docClient.query(params).promise();
        return data;
    },
    async getBlockedList (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :usr and begins_with(SK, :ban)",
            ExpressionAttributeValues: {
                ":usr": "USR#" + body.user_id + "#REL",
                ":ban": "BAN#",
            },
        }
        const data = await docClient.query(params).promise();
        return data;
    },
    async blockUser(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "USR#" + body.user_id + "#REL",
                SK: "BAN#" + body.block_id,
                time: moment().unix(),
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async setAge (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set payload.age = :age",
            ExpressionAttributeValues: {
                ":age": body.age
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setGender (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set payload.gender = :gender",
            ExpressionAttributeValues: {
                ":gender": body.gender
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setCommercial (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set payload.commercial = :val",
            ExpressionAttributeValues: {
                ":val": !body.value
            },
            ReturnValues:"UPDATED_NEW"
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setCommercial2 (body) {
        let param1 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + body.first,
                    SK: `USR${body.old}#` + body.user_id, 
                }
            }
        };
        let param2 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + body.second,
                    SK: `USR${body.old}#` + body.user_id, 
                }
            }
        };
        let param3 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + body.first,
                    SK: `USR${body.new}#` + body.user_id, 
                }
            }
        };
        let param4 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + body.second,
                    SK: `USR${body.new}#` + body.user_id, 
                }
            }
        };
        let params = {
            RequestItems: {
                ORB_NET: [param1, param2, param3, param4]
            }
        }
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async setPostal (body, pubpte, code) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + `#${pubpte}`
            },
            UpdateExpression: `set ${body.place} = :loc`,
            ExpressionAttributeValues: {
                ":loc": code
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setPostal2 (body) {
        let param1 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + geohash.postal_to_geo(body.old_postal),
                    SK: `USR${body.value}#` + body.user_id, 
                }
            }
        };
        let param2 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + geohash.postal_to_geo(body.postal_code),
                    SK: `USR${body.value}#` + body.user_id, 
                }
            }
        };
        let params = {
            RequestItems: {
                ORB_NET: [param1, param2]
            }
        }
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async delete (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ORB#"
            },
        };
        const data = await docClient.delete(params).promise();
        return data;
    },
};

module.exports = dynaUser;

