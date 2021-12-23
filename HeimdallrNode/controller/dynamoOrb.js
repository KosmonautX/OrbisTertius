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
                payload: {
                    comment: body.comment,
                    orb_uuid: body.orb_uuid,
                },
                identifier: body.beacon
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
                available: false,
                payload: {
                    comment: body.comment
                },
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async childPresent(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "COM#" + body.parent_id,
            },
            UpdateExpression: "set available = :present",
            ConditionExpression: "attribute_exists(SK)",
            ExpressionAttributeValues: {
                ":present": true
            }
        };
        const data = await docClient.update(params).promise();
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
                payload: {
                    comment: body.comment
                },
                identifier: body.beacon
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
                ":delete": false
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
                ":delete": false
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
    async create(body, gen){
        orb_uuid= await gen
        const params = {
            RequestItems: {
                [ddb_config.tableNames.orb_table]: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + orb_uuid,
                                SK: "USR#" + body.user_id,
                                inverse: "600#INIT#"+ body.created_dt, //in action space action is king lexiological sort (dictionary)
                                time: body.expiry_dt, // some init will be deactivated need fulfillment cycle
                                geohash: body.geolocation,
                                identifier: body.beacon,
                                payload: {
                                    orb_nature: body.orb_nature,
                                    title: body.title,
                                    media: body.media,
                                    creationtime: body.created_dt
                                }
                            }
                        }
                    }
                ]
            }
        };
        for(hashes of body.geolocation.hashes){
            params.RequestItems[ddb_config.tableNames.orb_table].push({
                PutRequest: {
                    Item: {
                        PK: "LOC#" + hashes +"#" + body.geolocation.radius,
                        SK: body.created_dt + "#ORB#" + orb_uuid, // in stream time is king
                        geohash : body.geolocation,
                        time: body.expiry_dt,
                        extinguish: body.expiry_dt,
                        payload: {
                            orb_nature: body.orb_nature,
                            title: body.title,
                            media: body.media,
                            init: {
                                media :body.init.media,
                                profile_pic :body.init.profile_pic,
                                username: body.init.username
                            },
                            photo: body.photo,
                            user_id: body.user_id,
                            creationtime: body.created_dt,
                        }
                    }
                }
            })
        }
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
            //dao.expiry_dt = data.Item.time;
            dao.alphanumeric = data.Item.alphanumeric;
            dao.orb_uuid = data.Item.PK.slice(4);
            dao.geolocation = data.Item.geohash;
            dao.active = data.Item.time > moment().unix()
            if(data.Item.payload){
                dao.payload = data.Item.payload;
                dao.user_id = data.Item.payload.user_id
                dao.created_dt  = data.Item.payload.creationtime}
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
                ":status": "800#FULF"
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
                ":status": "800#FULF"
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async gen(body){
        try{
            body.orb_uuid = uuidv4();
            const  params = {
                TableName: ddb_config.tableNames.orb_table,
                Item: {
                    PK: "ORB#" + body.orb_uuid,
                    SK: "ORB#" + body.orb_uuid,
                    time: body.expiry_dt,
                    geohash : body.geolocation,
                    alphanumeric: "LOC#" + body.geolocation.hash+ "#" +body.geolocation.radius,
                    payload: {
                        title: body.title, // title might have to go to the alphanumeric
                        orb_nature: body.orb_nature,
                        info: body.info,
                        where: body.where,
                        when: body.when,
                        tip: body.tip,
                        media: body.media,
                        photo: body.photo,
                        user_id: body.user_id,
                        init: {username: body.init.username},
                        creationtime: body.created_dt,
                        extinguishtime: body.expiry_dt,
                        tags: body.tags,
                        postal_code: body.postal_code,
                    }
                },
                ConditionExpression: "attribute_not_exists(PK)"
            };
            const data = await docClient.put(params).promise();
            return body.orb_uuid;
        } catch (err){
            if (err.code == 'ConditionalCheckFailedException'){
                return dynaOrb.gen(body);
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
                            ":status": "801#CMPL"
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
    async deactivate(body) { // return true if success
        now = moment().unix()
        const params = {
            RequestItems: {
                [ddb_config.tableNames.orb_table]: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "USR#" + body.user_id,
                                inverse: "600#INIT#"+ body.created_dt , //in action space action is king lexiological sort (dictionary)
                                time: now, // some init will be deactivated need fulfillment cycle
                                geohash: body.geolocation,
                                identifier: body.beacon,
                                payload: {
                                    orb_nature: body.orb_nature,
                                    title: body.payload.title,
                                    media: body.payload.media,
                                    creationtime: body.created_dt
                                }
                            }
                        }
                    },

                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "ORB#" + body.orb_uuid,
                                time: now,
                                geohash : body.geolocation,
                                alphanumeric: body.alphanumeric,
                                payload: body.payload
                            }
                        }
                    }
                ]
            }
        };
        for(hashes of body.geolocation.hashes){
            params.RequestItems[ddb_config.tableNames.orb_table].push({
                PutRequest: {
                    Item: {
                        PK: "LOC#" + hashes +"#" + body.geolocation.radius,
                        SK: now + "#ORB#" + body.orb_uuid,
                        extinguish: body.payload.extinguishtime,
                        time: now,
                        payload: body.payload,
                        geohash: body.geolocation
                    }}})
        }
        return batchWriteProcessor(params);
    },

    async destroy(body) { // return true if success
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
                    Delete: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "ORB#" + body.orb_uuid,
                        },
                    }
                },
                {
                    Delete: {
                        TableName: ddb_config.tableNames.orb_table,
                        Key: {
                            PK: "ORB#" + body.orb_uuid,
                            SK: "USR#" + body.user_id,
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


async function batchWriteProcessor(params){
    var  count = 0
        var processed = false
        do{
            processBatch = await docClient.batchWrite(params).promise();
            if (processBatch && Object.keys(processBatch.UnprocessedItems).length>0) {
                params = {RequestItems: batchWriteResp.UnprocessedItems}
                // delay a random time and fixed increase exponentially
                const delay = Math.floor(Math.random() * count * 500 + 10**count)
                await new Promise(resolve => setTimeout(resolve, delay));
            } else {
                processed = true
                break
            }
        } while(count< 5)

    return processed
}


module.exports = {
    comment: comment,
    orbSpace: orbSpace,
    dynaOrb: dynaOrb,
};
