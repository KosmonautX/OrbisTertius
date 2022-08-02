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
                    username: body.username
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
                    comment: body.comment,
                    username: body.username
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
                    comment: body.comment,
                    orb_uuid: body.orb_uuid,
                    username: body.username
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
        let dao = {};
        if (data.Item){
            dao.parent_id = data.Item.PK.slice(4);
            dao.comment_id = data.Item.SK.slice(4)
            if(data.Item.payload){
                dao.comment = data.Item.payload.comment;
                dao.orb_uuid = data.Item.payload.orb_uuid
            }
            dao.user_id = data.Item.inverse.substring(4)
            dao.creationtime = data.Item.time
        }
        return dao;
    },
    async deleteComment (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "COM#" + body.parent_id, 
                SK: "COM#" + body.comment_id,
            },
            UpdateExpression: "set extinguish = :delete",
            ConditionExpression:"attribute_exists(PK) and inverse = :user",
            ExpressionAttributeValues: {
                ":delete": moment().unix() + 86400*14,
                ":user": "USR#" + body.user_id
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async deleteAdminComment (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "COM#" + body.parent_id,
                SK: "COM#" + body.comment_id,
            },
            UpdateExpression: "set extinguish = :delete",
            ConditionExpression:"attribute_exists(PK)",
            ExpressionAttributeValues: {
                ":delete": moment().unix() + 86400*14
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
            UpdateExpression: "set extinguish = :delete",
            ExpressionAttributeValues: {
                ":delete": moment().unix() + 86400*14
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
};

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
                        available: true,
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
        return dynaOrb.fish(body.orb_uuid)
    },
    async fish(orb) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + orb,
                SK: "ORB#" + orb
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
            dao.available = data.Item.available
            if(data.Item.payload){
                dao.payload = data.Item.payload;
                dao.user_id = data.Item.payload.user_id
                dao.created_dt  = data.Item.payload.creationtime
            }
        }
        return dao;
    },
    async fisher(orb) {
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + orb,
                SK: "ORB#" + orb
            }}
        return docClient.get(params).promise()
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
                    available: true,
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
                        traits: body.traits,
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
    async force_gen(body){
        try{
            const  params = {
                TableName: ddb_config.tableNames.orb_table,
                Item: {
                    PK: "ORB#" + body.orb_uuid,
                    SK: "ORB#" + body.orb_uuid,
                    time: body.expiry_dt,
                    geohash : body.geolocation,
                    available: true,
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
                        traits: body.traits,
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
                                payload: body.payload,
                                available: true
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
                        SK: now + "#ORB#" + body.orb_uuid, // links with filter function in stream
                        extinguish: body.payload.extinguishtime,
                        time: now,
                        available: true,
                        payload: body.payload,
                        geohash: body.geolocation
                    }}})
        }
        return batchWriteProcessor(params);
    },

    async destroy(body) { // return true if success
        now = moment().unix()
        const params = {
            RequestItems: {
                [ddb_config.tableNames.orb_table]: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "USR#" + body.user_id,
                                inverse: "100#DSTY#"+ body.created_dt , //in action space action is king lexiological sort (dictionary)
                                time: now, // some init will be deactivated need fulfillment cycle
                                geohash: body.geolocation,
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
                                payload: body.payload,
                                available: false
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
                        geohash: body.geolocation,
                        available: false
                    }}})
        }
        return batchWriteProcessor(params);

    },

    async nirvana(orbs) { // return true if success
        return Promise.all(orbs.map(orb_uuid => dynaOrb.fisher(orb_uuid))).then(response => {
            const params = { RequestItems: {[ddb_config.tableNames.orb_table]: []}};
            response.map(async(data) => {
                if(data.Item){
                    orb_uuid = data.Item.PK.slice(4);
                    creationtime = data.Item.payload.creationtime
                    geolocation = data.Item.geohash;
                    user_id = data.Item.payload.user_id
                    params.RequestItems[ddb_config.tableNames.orb_table].push(
                        {
                            DeleteRequest: {
                                Key: {
                                    PK: "ORB#" + orb_uuid,
                                    SK: "USR#" + user_id,
                                }}},
                        {
                            DeleteRequest: {
                                Key: {
                                    PK: "ORB#" + orb_uuid,
                                    SK: "ORB#" + orb_uuid,
                                }}}
                    )
                    for(hash of geolocation.hashes){
                        params.RequestItems[ddb_config.tableNames.orb_table].push({
                            DeleteRequest: {
                                Key: {
                                    PK: "LOC#" + hash +"#" + geolocation.radius,
                                    SK: creationtime + "#ORB#" + orb_uuid
                                }}})
                    }
                }
            })
            return batchWriteProcessor(params);
        })

    },
    async anon(user_id, orbs) { // return true if success
        const params = { RequestItems: {[ddb_config.tableNames.orb_table]: []}};
        for(orb of orbs){
            params.RequestItems[ddb_config.tableNames.orb_table].push({
                DeleteRequest: {
                    Key: {
                        PK: "ORB#" + orb,
                        SK: "USR#" + user_id,
                    }}})
        }

        return batchWriteProcessor(params);

    }
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
    dynaOrb: dynaOrb,
};
