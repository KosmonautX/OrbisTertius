const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
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
                                commercial: true,
                                available: true,
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
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async putSecondLocation(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "LOC#" + body.geohashing.second,
                SK: "USRc#" + body.user_id,
            },
        };
        const data = await docClient.put(params).promise();
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
                ":val": body.value
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
    async setGeohashPostal (body, pubpte, code) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + `#${pubpte}`
            },
            UpdateExpression: `set geohash = :loc`,
            ExpressionAttributeValues: {
                ":loc": code
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setNumericPostal (body, pubpte, code) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + `#${pubpte}`
            },
            UpdateExpression: `set #n = :loc`,
            ExpressionAttributeNames:{
                "#n": "numeric"
            },
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
    async banUser(body) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set payload.available = :stat",
            ExpressionAttributeValues: {
                ":stat": "ban",
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async unbanUser(body) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set payload.available = :stat",
            ExpressionAttributeValues: {
                ":stat": true,
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
};

const dynaOrb = {
    async postOrb (body) {
        const params = {
            RequestItems: {
                ORB_NET: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "ORB#" + body.orb_uuid, 
                                numeric: body.nature, //  100 OFFER, 200 REQUEST, 300 BROADCAST, 600 TELE OFFER, 700 TELE REQUEST
                                time: body.expiry_dt,
                                geohash : body.geohashing52,
                                inverse: "LOC#" + body.geohashing,
                                payload: {
                                    title: body.title,
                                    info: body.info,
                                    where: body.where,
                                    when: body.when,
                                    tip: body.tip,
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: body.expires_in,
                                    postal_code: body.postal_code,
                                    commercial: body.commercial,
                                    available: true,
                                }
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "LOC#" + body.geohashing,
                                SK: body.expiry_dt.toString() + "#ORB#" + body.orb_uuid,
                                inverse: body.nature.toString(),
                                geohash : body.geohashing52,
                                payload: {
                                    title: body.title,
                                    info: body.info,
                                    where: body.where,
                                    when: body.when,
                                    tip: body.tip,
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: 7,
                                    postal_code: body.postal_code,
                                }
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "USR#" + body.user_id,
                                inverse: "600#INIT",
                                time: body.created_dt,
                                geohash: body.geohashing52,
                                numeric: body.nature, 
                                payload: body.success_dict
                            }
                        }
                    }
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async retrieve (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,      
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ORB#" + body.orb_uuid
            }
        };
        const data = await docClient.get(params).promise();
        let dao = {};
        if (data.Item){
            dao.title = data.Item.payload.title;
            dao.info = data.Item.payload.info;
            dao.where = data.Item.payload.where;
            dao.when = data.Item.payload.when;
            dao.tip = data.Item.payload.tip;
            dao.user_id = parseInt(data.Item.payload.user_id);
            dao.username = data.Item.payload.username;
            dao.expiry_dt = data.Item.time;
            dao.created_dt = data.Item.payload.created_dt;
            dao.nature = data.Item.numeric;
            dao.orb_uuid = data.Item.PK.slice(4);
            dao.geohash = parseInt(data.Item.inverse.slice(4));
            dao.geohash52 = data.Item.geohash;
            dao.postal_code = data.Item.payload.postal_code;
            dao.available = data.Item.payload.available;
            dao.commercial = data.Item.payload.commercial;
            dao.payload = data.Item.payload;
        } 
        return dao;
    },
    async update(body) { // return true if success
        const params = {
            "TransactItems": [
                {
                    Delete: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "LOC#" + body.geohash,
                            SK: body.expiry_dt + "#ORB#" + body.orb_uuid
                        }
                    }
                },
                {
                    Update: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "ORB#" + body.orb_uuid, 
                        },
                        UpdateExpression: "set #t = :time",
                        ExpressionAttributeNames:{
                            "#t": "time"
                        },
                        ExpressionAttributeValues: {
                            ":time": moment().unix()
                        }
                    }
                },
                {
                    Update: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "USR#" + body.user_id,
                        },
                        UpdateExpression: "set inverse = :status",
                        ExpressionAttributeValues: {
                            ":status": "801#COMPLETED" 
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
    async delete(body) { // return true if success
        const params = {
            "TransactItems": [
                {
                    Delete: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "LOC#" + body.geohash,
                            SK: body.expiry_dt + "#ORB#" + body.orb_uuid
                        }
                    }
                },
                {
                    Update: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "ORB#" + body.orb_uuid, 
                        },
                        UpdateExpression: "set #t = :time, payload = :payload",
                        ExpressionAttributeNames:{
                            "#t": "time"
                        },
                        ExpressionAttributeValues: {
                            ":time": moment().unix(),
                            ":payload": body.payload
                        }
                    }
                },
                {
                    Update: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "USR#" + body.user_id,
                        },
                        UpdateExpression: "set inverse = :status",
                        ExpressionAttributeValues: {
                            ":status": "300#DELETE" 
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
    async retrieveSucc (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,      
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id
            }
        };
        const data = await docClient.get(params).promise();
        if (data.Item){
            return data.Item.payload;
        } else {
            return false;
        }
    },
};

async function checkAvailable(body) {
    const params = {
        TableName: ddb_config.tableNames.orb_table,      
        Key: {
            PK: "USR#" + body.user_id,
            SK: "USR#" + body.user_id + "#pub"
        }
    };
    const data = await docClient.get(params).promise();
    if (data.Item){
        if (data.Item.payload.available != true) {
            let err = new Error(`User banned`);
            err.status = 401;
            throw err;
        } 
    } else {
        let err = new Error(`User not found`);
        err.status = 404;
        throw err;
    }
    
}


module.exports = {
    dynaUser: dynaUser,
    dynaOrb: dynaOrb,
    checkAvailable: checkAvailable,
}

