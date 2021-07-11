const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
const geohash = require('./geohash');
const {v4 : uuidv4} = require('uuid');

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
                inverse: "505#DISINIT",
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
                inverse: "550#DISACCEPT",
                payload: {
                    who: body.user_id.toString()
                }
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
}

const dynaOrb = {
    
    async create(body) {
        const params = {
            RequestItems: {
                [ddb_config.tableNames.orb_table]: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "ORB#" + body.orb_uuid, 
                                numeric: body.nature,
                                time: body.expiry_dt,
                                geohash : body.geohashing52,
                                alphanumeric: "LOC#" + body.geohashing,
                                payload: {
                                    title: body.title, // title might have to go to the alphanumeric
                                    info: body.info,
                                    where: body.where,
                                    when: body.when,
                                    tip: body.tip,
                                    media: body.media,
                                    photo: body.photo,
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: body.expires_in,
                                    tags: body.tags,
                                    postal_code: body.postal_code,
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
                                inverse: "TAX#" + body.nature,
                                geohash : body.geohashing52,
                                payload: {
                                    title: body.title,
                                    info: body.info,
                                    where: body.where,
                                    when: body.when,
                                    media: body.media,
                                    tip: body.tip,
                                    photo: body.photo,
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: body.expires_in,
                                    tags: body.tags
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
                            }
                        }
                    }
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async retrieve(body) {
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
            dao.user_id = data.Item.payload.user_id;
            dao.username = data.Item.payload.username;
            dao.photo = data.Item.payload.photo;
            dao.tags = data.Item.payload.tags;
            dao.expiry_dt = data.Item.time;
            dao.created_dt = data.Item.payload.created_dt;
            dao.nature = data.Item.numeric;
            dao.orb_uuid = data.Item.PK.slice(4);
            dao.geohash = parseInt(data.Item.alphanumeric.slice(4));
            dao.geohash52 = data.Item.geohash;
            dao.postal_code = data.Item.payload.postal_code;
            dao.available = data.Item.payload.available;
            dao.payload = data.Item.payload;
        } 
        return dao;
    },
    async acceptance(body){
        const  params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id
            },
            UpdateExpression: "set inverse = :status",
            ExpressionAttributeValues: {
                ":status": "800#FULFILLED"
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async forceaccept(body){
        const  params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.acpt_id
            },
            UpdateExpression: "set inverse = :status",
            ExpressionAttributeValues: {
                ":status": "800#FULFILLED"
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async gen(body){
        try{
            let orb_uuid = uuidv4();
            const  params = {
                TableName: ddb_config.tableNames.orb_table,        
                Item: {
                    PK: "ORB#" + orb_uuid,
                    SK: "ORB#" + orb_uuid,
                    alphanumeric: body.user_id,
                },
                ConditionExpression: "attribute_not_exists(PK)"
            };
            const data = await docClient.put(params).promise();
            return orb_uuid;
        } catch (err){
            if (err.code == 'ConditionalCheckFailedException'){
                return dynaOrb.gen();
            }
            else{
                return err;
            }
        }
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
                            ":time": moment().subtract(1, "minutes").unix(),
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
                            ":time": moment().subtract(1, "minutes").unix(),
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
};


module.exports = {
    comment: comment,
    orbSpace: orbSpace,
    dynaOrb: dynaOrb,
};
