const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
})
const docClient = new AWS.DynamoDB.DocumentClient({endpoint:ddb_config.dyna});
var s3;
switch(process.env.NODE_ENV)
{
    case "dev": s3 = new AWS.S3({endpoint:ddb_config.sthree, s3ForcePathStyle: true, signatureVersion: 'v4'});
    case "test": s3 = new AWS.S3({region:ddb_config.region, signatureVersion: 'v4'});
    case "prod": s3 = new AWS.S3({region:ddb_config.region, signatureVersion: 'v4'});
}

const geohash = require('../controller/geohash');
const teleMessaging = require('../controller/teleMessaging');
const security = require('../controller/security');
const orbSpace = require('../controller/dynamoOrb').orbSpace;


router.post(`/gen_uuid`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let promises = new Map();
        security.checkUser(req.verification.user_id, body.user_id);
        orb_uuid = await dynaOrb.gen(body);
        promises.set('orb_uuid',orb_uuid);
        if (body.media){
            promises.set('lossy', await serve3.preSign('putObject','ORB',orb_uuid,'150x150'));
            promises.set('lossless', await serve3.preSign('putObject','ORB',orb_uuid,'1920x1080'));
        };
        Promise.all(promises).then(response => {
            res.status(201).json({
                response
               
            });
        });
        
    } catch (err) {
        next(err);
    }
});

/**
 * API 0.0
 * Create orb
 * No checking for empty fields yet
 * user_id = telegram_id
 */
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        if (!body.orb_uuid) {
            body.orb_uuid = uuidv4();
        }
        body.expiry_dt = slider_time(body.expires_in);
        body.created_dt = moment().unix();
        if(!body.geohashing || !body.geohashing52){
        if (body.latlon) {
            body.geohashing = geohash.latlon_to_geo(body.latlon); 
            body.geohashing52 = geohash.latlon_to_geo52(body.latlon); 
        } else if (body.postal_code) {
            body.geohashing = geohash.postal_to_geo(body.postal_code);
            body.geohashing52 = geohash.postal_to_geo52(body.postal_code);
        }};
        if (body.media !== true){
            var img = body.photo;
            body.media = false;
        } else {
            var img = "on bucket";
            body.media = true;
        };
        await dynaOrb.create(body);
        // when user post orb on app, send the orb to telebro
        let recipients = await teleMessaging.getRecipient(body);
        await teleMessaging.postOrbOnTele(body, recipients);
        res.status(201).json({
            "orb_uuid": body.orb_uuid,
            "expiry": body.expiry_dt,
            "img": img
        });
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt) {
        expiry_dt = moment().add(parseInt(dt), 'days').unix();
    }
    return expiry_dt;
}

router.post(`/upload_profile_pic`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        if (body.media){
            var img_lossy = await serve3.preSign('putObject','USR',body.user_id,'150x150');
            var img_lossless = await serve3.preSign('putObject','USR',body.user_id,'1920x1080');
            res.status(200).json({
                "lossy": img_lossy,
                "lossless": img_lossless,
            });
        } else {
            res.status(400).json({
                "Error": "No media"
            });
        }
    } catch (err) {
        next(err);
    }
});

router.post(`/create_user`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        if (body.latlon) {
            body.geohashing = {
                home: geohash.latlon_to_geo(body.latlon.home),
                office: geohash.latlon_to_geo(body.latlon.office)
            };
            body.loc = {
                home: body.latlon.home,
                office: body.latlon.office
            };
        } else if (body.home || body.office) {
            // if only 1 is given (either home or office postal codes)
            body.geohashing = {
                home: geohash.postal_to_geo(body.home),
                office: geohash.postal_to_geo(body.office)
            };
            body.geohashing52 = {
                home: geohash.postal_to_geo52(body.home),
                office: geohash.postal_to_geo52(body.office)
            };
            body.loc = {
                home: body.home,
                office: body.office
            };
        }
        if (body.profile_pic == null) body.profile_pic = "null";
        body.join_dt = moment().unix();
        let transacSuccess = await dynaUser.transacCreate(body).catch(err => {
            err.status = 409;
            throw err;
        });
        if (transacSuccess == true) {
            await dynaUser.bulkCreate(body).catch(err => {
                err.status = 400
                throw err;
            })
            res.status(201).json({
                "User Created": body.user_id
            });
        }
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err)
    }
});

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
                            SK: "username#" + body.username
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
                                numeric: parseInt(body.loc.home),
                                geohash: parseInt(body.loc.office), 
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
                    profile_pic: body.profile_pic,
                    verified: body.verified,
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
                ":home": geohash.postal_to_geo(body.home)
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
                ":home": geohash.postal_to_geo52(body.home)
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
    async updateUserOfficeGeohash(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id,
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set geohash = :office",
            ExpressionAttributeValues: {
                ":office": geohash.postal_to_geo(body.office),
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
                ":office": geohash.postal_to_geo52(body.office),
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
                            SK: "username#" + body.username
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
};

const userQuery = {
    async queryPTE(body) {
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
    async queryPUB(body) {
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
                                inverse: "LOC#" + body.geohashing,
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
                                inverse: body.nature.toString(),
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
            dao.geohash = parseInt(data.Item.inverse.slice(4));
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
    async gen(body){
        try{
            let orb_uuid = uuidv4();
            const  params = {
                TableName: ddb_config.tableNames.orb_table,        
                Item: {
                    PK: "ORB#" + orb_uuid,
                    SK: "ORB#" + orb_uuid,
                    alphanumeric2: body.user_id,
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

const serve3 = {
    
    async preSign(action,entity, uuid, form) {
        var sign = s3.getSignedUrl(action, { 
            Bucket: ddb_config.sthreebucket, 
            Key: entity+ '/' +uuid + '/' + form, Expires: 300
        });
        if(sign.length < 50 )
        {sign = serve3.preSign(action,entity,uuid,form);}

        return sign;
    },

};

/**
 * API POST 3
 * User personal interactions with orb: SAVE | HIDE
 */
router.post(`/user_action`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        let userActions = ['save','hide'] 
        if (!userActions.includes(body.action.toLowerCase())) {
            throw new Error('Missing or Invalid user action. Only supports save|hide')
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ACT#" + body.user_id.toString() + "#" + body.action.toLowerCase(),
                inverse: moment().unix().toString(), // inverse attribute requires it to be a string!
            },
        };
        docClient.put(params, function(err, data) {
            if (err) {
                err.status = 400;
                next(err);
            } else {
                res.status(200).json({
                    "User Action": body.action.toLowerCase(),
                    "ORB UUID": body.orb_uuid,
                    "USER ID": body.user_id
                });
            }
        });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API POST 3
 * UNDO User personal interactions with orb: SAVE | HIDE
 */
router.post(`/undo_user_action`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        let userActions = ['save','hide'] 
        if (!userActions.includes(body.action.toLowerCase())) {
            throw new Error('Missing or Invalid user action. Only supports save|hide.')
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ACT#" + body.user_id.toString() + "#" + body.action.toLowerCase(),
            },
        };
        docClient.delete(params, function(err, data) {
            if (err) {
                err.status = 400;
                next(err);
            } else {
                res.status(200).json({
                    "UNDO User Action": body.action.toLowerCase(),
                    "ORB UUID": body.orb_uuid,
                    "USER ID": body.user_id
                });
            }
          });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

// user reports a post 
router.post(`/report`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "REPORT#" + body.user_id,
                inverse: moment().unix().toString(),
                payload: body.reason,
            },
        };
        docClient.put(params, function(err, data) {
            if (err) {
                err.status = 400;
                next(err);
            } else {
                res.status(200).json({
                    "ORB Reported": body.orb_uuid,
                    "user_id": body.user_id
                });
            }
          });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 1.1
 * Update user payload
 */
router.put(`/update_user`, async function (req, res, next) {
    let body = { ...req.body };
    security.checkUser(req.verification.user_id, body.user_id);
    let data = await dynaUser.updatePayload(body).catch(err => {
        err.status = 400;
        next(err);
    });
    if (data) {
        res.json({
            "User updated:": body
        });
    } 
});

/**
 * API 1.1
 * Update username
 */
router.put(`/update_username`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        // transac create username, if true, then change and delete old username, else no go
        security.checkUser(req.verification.user_id, body.user_id);
        let pubData = await userQuery.queryPUB(body);
        if (pubData.Item) { // get old username
            body.old_username = pubData.Item.alphanumeric;
            let transac = await dynaUser.usernameTransaction(body);
            if (transac == true) {
                let params = {
                    TableName: ddb_config.tableNames.orb_table,      
                    Key: {
                        PK: "USR#" + body.user_id, 
                        SK: "USR#" + body.user_id + "#pub",
                    },
                    UpdateExpression: "set alphanumeric = :username",
                    ExpressionAttributeValues: {
                        ":username": body.username,
                    }
                };
                docClient.update(params, function(err, data) {
                    if (err) {
                        err.status = 400;
                        next(err);
                    } else {
                        res.status(201).json({
                            "User updated:": body
                        });
                    }
                });
            } else {
                let err = new Error("Username taken");
                err.status = 409;
                throw err;
            }
        } else {
            // user id invalid
            let err = new Error("User_id not found");
            err.status = 404;
            throw err;
        }
   
    } catch (err) {
        next(err);
    }
});

/**
 * API 1.1
 * Update user location
 * ONLY supports postal code for now
 */
router.put(`/update_user_location`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        if (body.home){
            await dynaUser.updateUserHome(body);
            await dynaUser.updateUserHomeGeohash(body);
            await dynaUser.updateUserHomeGeohash52(body);
        } 
        if (body.office){
            await dynaUser.updateUserOffice(body);
            await dynaUser.updateUserOfficeGeohash(body);
            await dynaUser.updateUserOfficeGeohash52(body);
        }
        res.json({ "User updated:": body });
    } catch (err) {
        err.status = 400;
        next(err)
    }
});

/**
 * API 0.2
 * Accept orb
 */
router.post(`/accept`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id.toString(),
                inverse : "500#ACCEPT",
                time: moment().unix(),
            },
        };
        docClient.put(params, function(err, data) {
            if (err) {
                err.status = 400;
                next(err);
            } else {
                teleMessaging.exchangeContact(body).then(
                    function(value){
                        res.status(200).json({
                            "ORB accepted by": body.user_id,
                            "USER ID": body.orb_uuid
                    });
                });
            }
          });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 0.2
 * Unaccept orb
 */
router.put(`/delete_acceptance`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        await orbSpace.deleteAcceptance(body);
        res.status(200).json({
            "ORB interaction removed": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        next(err);
    }
});

/**
 * API 
 * 
 */
router.put(`/not_interested`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        await orbSpace.notInterested_i(body);
        res.status(200).json({
            "ORB not interested": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 
 * 
 */
router.put(`/not_interested_acceptor`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        await orbSpace.notInterested_a(body);
        res.status(200).json({
            "ORB not interested": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 1.2
 * Complete orb handshake (for an acceptor)
 */
router.put(`/complete_orb_acceptor`, async function (req, res, next) {
    let body = { ...req.body };
    let clock = moment().unix();
    security.checkUser(req.verification.user_id, body.init_id);
    const accepted = await dynaOrb.acceptance(body).catch(err => {
            err.status = 400;
            next(err);
    })
    const buddied = await dynaUser.buddy(body.init_id,body.user_id,clock).catch(err=> {
        err.status = 400;
        next(err);
    })
    const buddys = await dynaUser.buddy(body.user_id,body.init_id,clock).catch(err=> {
        err.status = 400;
        next(err);
    })
    if (accepted && buddied && buddys) {
            res.status(200).json({
                "ORB completed for Acceptor": body.orb_uuid,
                "user_id": body.user_id
            });
        };
});

/**
 * API 1.2
 * Complete orb (as an initiator)
 * deletes the location-time entry, update orb completion time and orb-usr status as completed
 */
router.put(`/complete_orb`, async function (req, res, next) {
    let body = { ...req.body };
    security.checkUser(req.verification.user_id, body.user_id);
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found"
    });
    let completion = false;
    if (orbData) {
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        completion = await dynaOrb.update(body).catch(err => {
            err.status = 500;
            next(err);
        });
    }
    if (completion == true) {
        res.status(201).json({
            "Orb completed": body.orb_uuid
        })
    }
});

/**
 * API 1.2
 * Init acceptance handshake for eventual two way to completed
 */
router.put(`/pending_orb_acceptor`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        security.checkUser(req.verification.user_id, body.user_id);
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id
            },
            UpdateExpression: "set inverse = :status",
            ExpressionAttributeValues: {
                ":status": "550#PENDING"
            }
        };
        docClient.update(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.status(200).json({
                    "ORB handshake initialised": body.orb_uuid,
                    "user_id": body.user_id
                });
            }
        });
    } catch (err) {
        res.status(400).json(err.message);
    }
});

router.put(`/delete_orb`, async function (req, res, next) {
    let body = { ...req.body};
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found";
    });
    security.checkUser(req.verification.user_id, orbData.payload.user_id);
    body.expiry_dt = orbData.expiry_dt;
    body.geohash = orbData.geohash;
    body.payload = orbData.payload;
    body.payload.available = false;
    const deletion = await dynaOrb.delete(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (deletion == true) {
        res.status(201).json({
            "Orb deleted": body.orb_uuid
        });
    }
});

module.exports = router;
