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
const s3 = new AWS.S3({endpoint:ddb_config.sthree,
                       s3ForcePathStyle: true, signatureVersion: 'v4'});
const geohash = require('ngeohash');
const fs = require('fs');
const rawdata = fs.readFileSync('./resources/onemap3.json', 'utf-8');
const onemap = JSON.parse(rawdata);

/**
 * API 0.0
 * Create orb
 * No checking for empty fields yet
 * user_id = telegram_id
 */
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        body.orb_uuid = uuidv4();
        body.expiry_dt = slider_time(body.expires_in);
        body.created_dt = moment().unix();
        let img;
        if (body.latlon) {
            body.geohashing = latlon_to_geo(body.latlon); 
            body.geohashing52 = latlon_to_geo52(body.latlon); 
        } else if (body.postal_code) {
            body.geohashing = postal_to_geo(body.postal_code);
            body.geohashing52 = postal_to_geo52(body.postal_code);
        }
        if (body.photo){
            img = body.photo;
        } else {
            img =  s3.getSignedUrl('putObject', { Bucket: ddb_config.sthreebucket
                                                        , Key: body.orb_uuid, Expires: 300});
        }
        let response = await dynaOrb.create(body).catch(err => {
            err.status = 400
            throw err;
        })
        res.status(201).json({
            "ORB UUID": body.orb_uuid,
            "expiry": body.expiry_dt,
            "Image URL": img
        });
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err)
    }
});

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt) {
        expiry_dt = moment().add(parseInt(dt), 'days').unix();
    }
    return expiry_dt;
}

router.post(`/create_user`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        if (body.latlon) {
            body.geohashing = {
                home: latlon_to_geo(body.latlon.home),
                office: latlon_to_geo(body.latlon.office)
            };
            body.geohashing52 = {
                home: postal_to_geo52(body.home),
                office: postal_to_geo52(body.office)
            };
            body.loc = {
                home: body.latlon.home,
                office: body.latlon.office
            };
        } else if (body.home) {
            body.geohashing = {
                home: postal_to_geo(body.home),
                office: postal_to_geo(body.office)
            };
            body.loc = {
                home: body.home,
                office: body.office
            };
        }
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
                            payload: {
                                bio: body.bio,
                                profile_pic: body.profile_pic,
                                verified: body.verified,
                            },
                        }
                    }
                },
                {
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        ConditionExpression: "attribute_not_exists(PK)",
                        Item: {
                            PK: "phone#" + body.country_code + body.hp_number,
                            SK: "phone#" + body.country_code + body.hp_number
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
                ORB_NET: [
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
                    }
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
                ":home": postal_to_geo(body.home)
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
                ":home": postal_to_geo52(body.home)
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
                ":office": postal_to_geo(body.office),
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
                ":office": postal_to_geo52(body.office),
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
};

const dynaOrb = {
    async create(body) {
        const params = {
            RequestItems: {
                ORB_NET: [
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
                                geohash: body.geohashing52
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
            dao.username = data.Item.alphanumeric;
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
}

/**
 * API POST 3
 * User personal interactions with orb: SAVE | HIDE
 */
router.post(`/user_action`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let userActions = ['save','hide'] 
        if (!userActions.includes(body.action.toLowerCase())) {
            throw new Error('Missing or Invalid user action. Only supports save|hide')
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ACT#" + body.user_id.toString() + "#" + body.action.toLowerCase(),
                inverse: moment().unix().toString(),
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
 * API 0.2
 * Accept orb
 */
router.post(`/accept`, async function (req, res, next) {
    try {
        let body = { ...req.body };
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
                res.status(200).json({
                    "ORB accepted": body.orb_uuid,
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
 * API 0.2
 * Unaccept orb
 */
router.put(`/delete_acceptance`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id.toString(),
            },
        };
        docClient.delete(params, function(err, data) {
            if (err) {
                err.status = 400;
                next(err);
            } else {
                res.status(200).json({
                    "ORB interaction removed": body.orb_uuid,
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
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pub",
            },
            UpdateExpression: "set alphanumeric = :username",
            ExpressionAttributeValues: {
                ":username": body.username
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
    } catch (err) {
        err.status = 400;
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
 * API 1.2
 * Complete orb handshake (for an acceptor)
 */
router.put(`/complete_orb_acceptor`, async function (req, res, next) {
    let body = { ...req.body };
    let clock = moment().unix()
    const accepted = await dynaOrb.acceptance(body).catch(err => {
            err.status = 400;
            next(err);})
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
        err.message = "ORB not found"
    });
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
        })
    }
});


function postal_to_geo(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo(latlon);
}

function latlon_to_geo(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 30);
    return geohashing;
}

function postal_to_geo52(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo52(latlon);
}

function latlon_to_geo52(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 52);
    return geohashing;
}


module.exports = router;
