const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment')
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
    let body = { ...req.body };
    const orb_uuid = uuidv4();
    let expiry_dt = slider_time(body.expires_in);
    let created_dt = moment().unix();
    let geohashing;
    let img;
    if (body.latlon) {
        geohashing = latlon_to_geo(body.latlon); 
    } else if (body.postal_code) {
        geohashing = postal_to_geo(body.postal_code);
    }
    let geohashing52;
    if (body.latlon) {
        geohashing52 = latlon_to_geo52(body.latlon); 
    } else if (body.postal_code) {
        geohashing52 = postal_to_geo52(body.postal_code);
    }
    if (body.photo){
        img = body.photo;
    } else {
        img =  s3.getSignedUrl('putObject', { Bucket: ddb_config.sthreebucket
                                                    , Key: orb_uuid, Expires: 300});
    }
    let params = {
        RequestItems: {
            "ORB_NET": [
                {
                    PutRequest: {
                        Item: {
                            PK: "ORB#" + orb_uuid,
                            SK: "ORB#" + orb_uuid, 
                            numeric: body.nature,
                            time: expiry_dt,
                            geohash : geohashing52,
                            inverse: "LOC#" + geohashing,
                            payload: JSON.stringify({
                                title: body.title, // title might have to go to the alphanumeric
                                info: body.info,
                                where: body.where,
                                when: body.when,
                                tip: body.tip,
                                photo: body.photo,
                                user_id: body.user_id,
                                username: body.username,
                                created_dt: created_dt,
                                expires_in: body.expires_in,
                                tags: body.tags
                            })
                        }
                    }
                },
                {
                    PutRequest: {
                        Item: {
                            PK: "LOC#" + geohashing,
                            SK: expiry_dt.toString() + "#ORB#" + orb_uuid,
                            inverse: body.nature.toString(),
                            geohash : geohashing52,
                            payload: JSON.stringify({
                                title: body.title,
                                info: body.info,
                                where: body.where,
                                when: body.when,
                                tip: body.tip,
                                photo: body.photo,
                                user_id: body.user_id,
                                username: body.username,
                                created_dt: created_dt,
                                expires_in: body.expires_in,
                                tags: body.tags
                            })
                        }
                    }
                },
                {
                    PutRequest: {
                        Item: {
                            PK: "ORB#" + orb_uuid,
                            SK: "USER#" + body.user_id,
                            inverse: "600#INIT",
                            time: created_dt,
                            geohash: geohashing52,
                            payload: JSON.stringify({
                                title: body.title,
                                info: body.info,
                                where: body.where,
                                when: body.when,
                                tip: body.tip,
                                photo: body.photo,
                                user_id: body.user_id,
                                username: body.username,
                                created_dt: created_dt,
                                expires_in: body.expires_in,
                                tags: body.tags
                            })
                        }
                    }
                }
            ]
        }
    }
    docClient.batchWrite(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.status(201).json({
                "PutItem succeeded:": {
                    "ORB UUID": orb_uuid,
                    "expiry": expiry_dt,
                    "Image URL": img
                }
            });
        }
    });
});

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt == "1 day"){ 
        expiry_dt = moment().add(1, 'days').unix();
    } else if (dt == "3 day") {
        expiry_dt = moment().add(3, 'days').unix();
    } else if (dt == "1 week") {
        expiry_dt = moment().add(7, 'days').unix();
    } else if (dt == "1 month") {
        expiry_dt = moment().add(1, 'M').unix();
    }
    return expiry_dt;
}

function keyword_to_code(keyword) {
    let code = "9000#ERROR"
    if (keyword.toUpperCase() == "INIT") code = "600#INIT";
    else if (keyword.toUpperCase() == "ACCEPT") code = "500#ACCEPT";
    else if (keyword.toUpperCase() == "BOOKMARK") code = "400#BOOKMARK";
    else if (keyword.toUpperCase() == "DELETE") code = "300#DELETE";
    else if (keyword.toUpperCase() == "HIDE") code = "200#HIDE";
    else if (keyword.toUpperCase() == "REPORT") code = "100#REPORT";
    return code;
}

router.post(`/create_user`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let geohashing;
        if (body.latlon) {
            geohashing = latlon_to_geo(body.latlon); 
        } else if (body.postal_code) {
            geohashing = postal_to_geo(body.postal_code);
        }
        let params = {
            "TransactItems": [
                {
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        ConditionExpression: "attribute_not_exists(PK)",
                        Item: {
                            PK: "USER#" + body.user_id, 
                            SK: "USER#" + body.user_id,
                            payload: JSON.stringify({
                                bio: body.bio,
                                profile_pic: body.profile_pic,
                                verified: body.verified,
                                country_code: body.country_code,
                                hp_number: body.hp_number,
                                gender: body.gender,
                                birthday: body.birthday, //DD-MM-YYYY
                            }),
                            alphanumeric: body.username,
                            numeric: body.postal_code,
                            geohash: geohashing
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
        docClient.transactWrite(params, function(err, data) {
            if (err) {
                let err_msg = [];
                let result = err.message.slice(79);
                result = result.slice(0,-1);
                let result_arr = result.split(",");
                if (result_arr[0].trim() != "None" ) err_msg.push("user_id");
                if (result_arr[1].trim() != "None" ) err_msg.push("hp_number");
                res.status(409).json({
                    "Duplicate Entries:": err_msg
                });
            } else {
                res.status(201).json({
                    "User Registered:": body
                });
            }
            });
    } catch (err) {
        res.status(400).json(err.message);
    }
})

/**
 * API 0.2
 * Interact with ORB
 */
router.post(`/interact`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let geohashing;
        if (body.latlon) {
            geohashing = latlon_to_geo(body.latlon); 
        } else if (body.postal_code) {
            geohashing = postal_to_geo(body.postal_code);
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USER#" + body.user_id.toString(),
                inverse : keyword_to_code(body.keyword.trim()),
                time: moment().unix(),
                geohash: geohashing,
                alphanumeric: body.comment
            },
        };
        docClient.put(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.status(200).json({
                    "Interaction:": {
                        "Type": body.keyword,
                        "ORB UUID": body.orb_uuid,
                        "USER ID": body.user_id
                    }
                });
            }
          });
    } catch (err) {
        res.status(400).json(err.message);
    }
});

/**
 * API 1.1
 * Update ORB status
 */
router.put(`/update_user`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USER#" + body.user_id, 
                SK: "USER#" + body.user_id,
            },
            UpdateExpression: "set payload = :payload",
            // ConditionExpression:":username",
            ExpressionAttributeValues: {
                ":payload": JSON.stringify({
                    bio: body.bio,
                    profile_pic: body.profile_pic,
                    verified: body.verified,
                    country_code: body.country_code,
                    hp_number: body.hp_number,
                    gender: body.gender,
                    birthday: body.birthday,
                }),
            }
        };
        docClient.update(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.json({
                    "User updated:": body
                });
            }
        });
    } catch (err) {
        res.status(400).json(err.message);
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
                PK: "USER#" + body.user_id, 
                SK: "USER#" + body.user_id,
            },
            UpdateExpression: "set alphanumeric = :username",
            ExpressionAttributeValues: {
                ":username": body.username
            }
        };
        docClient.update(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.status(201).json({
                    "User updated:": body
                });
            }
        });
    } catch (err) {
        res.status(400).json(err.message);
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
        let geohashing;
        if (body.latlon) {
            geohashing = latlon_to_geo(body.latlon); 
        } else if (body.postal_code) {
            geohashing = postal_to_geo(body.postal_code);
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USER#" + body.user_id, 
                SK: "USER#" + body.user_id,
            },
            UpdateExpression: "set geohash = :geohash, numeric = :ps",
            ExpressionAttributeValues: {
                ":geohash": geohashing,
                ":ps": body.postal_code || 0
            }
        };
        docClient.update(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.status(201).json({
                    "User updated:": body
                });
            }
        });
    } catch (err) {
        res.status(400).json(err.message);
    }
});

/**
 * API 1.2
 * Update ORB status
 * unable catch an orb that has already been fulfilled
 */
router.put(`/complete_orb_acceptor`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USER#" + body.user_id
            },
            UpdateExpression: "set inverse = :status",
            ExpressionAttributeValues: {
                ":status": "800#FULFILLED"
            }
        };
        docClient.update(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.status(200).json({
                    "ORB updated as FULFILLED:": {
                        "orb_uuid": body.orb_uuid,
                        "user_id": body.user_id
                    }
                });
            }
        });
    } catch (err) {
        res.status(400).json(err.message);
    }
});

router.put(`/complete_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let params = {
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
                    Put: {
                        TableName: ddb_config.tableNames.orb_table,
                        Item: {
                            PK: "LOC#" + body.geohash,
                            SK: moment().unix().toString() + "#ORB#" + body.orb_uuid,
                            inverse: body.nature.toString(),
                            geohash: body.geohash52,
                            payload: JSON.stringify({
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
                            })
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
                            SK: "USER#" + body.user_id, 
                        },
                        UpdateExpression: "set inverse = :status",
                        ExpressionAttributeValues: {
                            ":status": "801#INIT_FULFILLED" 
                        }
                    }
                },
            ] 
        };
        docClient.transactWrite(params, function(err, data) {
            if (err) {
                res.status(409).json({
                    "Duplicate Entries:": err
                });
            } else {
                res.status(201).json(data);
            }
            });
    } catch (err) {
        res.status(400).json(err.message);
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
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGTITUDE), 30);
    return geohashing;
}

function get_geo_array(geohashing) {
    let arr = geohash.neighbors_int(geohashing, 30); // array
    arr.unshift(geohashing);
    return arr;
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
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGTITUDE), 52);
    return geohashing;
}


module.exports = router;
