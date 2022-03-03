const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint: ddb_config.dyna});
const geohash = require('../controller/geohash');
const userQuery = require('../controller/dynamoUser').userQuery;
const serve3 = require ('../controller/orbjectStore').serve3

/**
 * API 1
 * Get specific orbs (all info) by ORB:uuid
 */
router.get(`/get_orbs/:orb_uuids`, async function (req, res, next) {
    try{
        const n = 8 // limit to 8
        const orbs = req.params.orb_uuids.split(',').slice(0,n)
        const getter = async orb_uuid => {
            let params = {
                TableName: ddb_config.tableNames.orb_table,
                Key: {
                    PK: "ORB#" + orb_uuid,
                    SK: "ORB#" + orb_uuid
                }}
            return docClient.get(params).promise()
        };
        let now = moment().unix()
        Promise.all(orbs.map(orb_uuid => getter(orb_uuid))).then(response => {
            daos = response.map(async(data) => {
                var dao = {}
                if(data.Item){
                    dao.expiry_dt = data.Item.time;
                    dao.active = data.Item.time > now
                    dao.available = data.Item.available
                    dao.orb_uuid = data.Item.PK.slice(4);
                    dao.payload = data.Item.payload
                    if(data.Item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','ORB',dao.orb_uuid,'1920x1080');
                    dao.geolocation = data.Item.geohash;
                }
                return dao
            })
            Promise.all(daos).then(sandwich => {
                res.status(201).json(sandwich);
            })
        }).catch(error => {
            throw new Error("Recall ORB failed")
        });
    }catch(err){
        if (err.message == "Recall ORB failed") err.status = 401;
        next(err);
    }
});
/**
 * API 1
 * Get specific users (all info)
 */
router.get(`/get_users/:user_ids`, async function (req, res, next) {
    try{
        const n = 8
        const users = req.params.user_ids.split(',').slice(0,n)
        Promise.all(users.map(user_id => userQuery.queryPUB(user_id))).then(response => {
            daos = response.map(async(data) => {
                var dao = {payload:{}}
                if(data.Item){
                    dao.user_id = data.Item.PK.slice(4);
                    if (data.Item.payload) {
                        dao.payload = data.Item.payload
                        if(data.Item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','USR',dao.user_id,'150x150')}
                    if(data.Item.alphanumeric) dao.payload.username = data.Item.alphanumeric;
                    if(data.Item.geohash)dao.geolocation = data.Item.geohash;
                    dao.creationtime= data.Item.time
                    if(dao.user_id == req.verification.user_id)dao.beacon = data.Item.beacon
                }
                return dao
            })
            Promise.all(daos).then(sandwich => {
                res.status(201).json(sandwich);
            })
        }).catch(error => {
            throw new Error("Recall User failed")
        });
    }catch(err){
        if (err.message == "Recall User failed") err.status = 401;
        next(err);
    }
});


router.get(`/check_username`, async function (req, res, next) {
    try {
        let username = await userQuery.checkUsername(req.query.username);
        if (username.Item) {
            res.status(409).send({
                "username": "taken",
                "user_id": username.Item.alphanumeric
            });
        } else {
            res.status(200).send({
                "username": "empty"
            });
        }
    } catch (err) {
        next(err)
    }
});

/**
 * API GET 3
 * Get orbs for a user:
 * INIT: orbs not fulfilled (can be ongoing/expired)
 * ACCEPT: orbs accepted that are not completed yet
 * FULFILLED: as an acceptor
 * COMPLETED: as an initiator
 */
router.get(`/user_profile`, async function (req, res, next) {
    if (keyword_to_code(req.query.keyword) == "error") {
        res.status(400).send({ Error: "keyword not recogised." });
    }
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        IndexName: "Chronicle",
        KeyConditionExpression: "SK = :user and begins_with(inverse, :sort)",
        ExpressionAttributeValues: {
            ":user": "USR#" + req.query.user_id,
            ":sort": keyword_to_code(req.query.keyword)
        },
        Limit: 8,
        ScanIndexForward: false,
    };
    if (req.query.startkey) {
        params.ExclusiveStartKey = {
            "SK": "USR#" + req.query.user_id,
            "inverse": keyword_to_code(req.query.keyword)+ "#" + req.query.starttime,
            "PK": "ORB#" + req.query.startkey
        }
    };
    now = moment().unix()
    docClient.query(params, async function(err, data) {
        if (err) {
            err.status = 400;
            next(err);
        } else {
            if (data.Items.length == 0) {
                res.status(204).send();
            } else {
                let result = {
                    "Requested": req.query.keyword,
                    "Data" : await Promise.all(data.Items.map(async function(item){
                        let dao = {};
                        dao.user_id = item.SK.slice(4);
                        dao.orb_uuid = item.PK.slice(4);
                        dao.actiontime = item.time
                        if(item.payload){
                            dao.payload = item.payload;
                            dao.creationtime = item.payload.creationtime;
                            if(item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','ORB',dao.orb_uuid,'150x150')
                        }
                        dao.geohash = item.geohash;
                        dao.action = item.inverse.slice(4);
                        return dao
                    })),
                }
                if (data.LastEvaluatedKey) {
                    result.LastEvaluatedTime = data.LastEvaluatedKey.inverse.slice(-10)
                    result.LastEvaluatedKey = data.LastEvaluatedKey.PK.slice(4)}
                res.json(result);
            }
        }
    });
});

function keyword_to_code(keyword) {
    let code = "error"
    if (keyword.toUpperCase() == "INIT") code = "600#INIT";
   //  else if (keyword.toUpperCase() == "FULFILLED") code = "801#FULF";
    else if (keyword.toUpperCase() == "ACCEPT") code = "500#ACPT";

    else if (keyword.toUpperCase() == "COMPLETED") code = "800#CMPL";
    else if (keyword.toUpperCase() == "PENDING") code = "540#";
    return code;
}

/**
 * API 2
 * Get orbs saved / hidden for a user:
 */
router.get(`/user_pref`, async function (req, res, next) {
    let userActions = ['save','hide','rprt'] ;
    if (!userActions.includes(req.query.action.toLowerCase())) {
        res.status(400).send({ Error: 'Missing or Invalid user action. Only supports save|hide|rprt.' });
    }
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        IndexName: "Chronicle",
        KeyConditionExpression: "SK = :action and inverse > :sort",
        ExpressionAttributeValues: {
            ":action": "ACT#" + req.query.user_id + "#" + req.query.action,
            ":sort": "1"
        },
        Limit: 8,
        ScanIndexForward: req.query.ascending,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "SK": "ACT#" + req.query.user_id + "#" + req.query.action,
            "inverse": req.query.start_time,
            "PK": "ORB#" + req.query.start
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            err.status = 400;
            next(err);
        } else {
            if (data.Items.length == 0) {
                res.status(204).send()
            } else {
                let data_arr = [];
                data.Items.forEach(function(item) {
                    let dao = {};
                    dao.user_id = item.SK.slice(4).slice(0,-5);
                    dao.orb_uuid = item.PK.slice(4);
                    dao.creationtime = item.inverse;
                    data_arr.push(dao);
                })
                let result = {
                    "Requested": req.query.action,
                    "Data" : data_arr,
                }
                if (data.LastEvaluatedKey) {
                    result.LastEvaluatedKey = {
                        start: data.LastEvaluatedKey.PK.slice(4),
                        start_time: data.LastEvaluatedKey.inverse
                    }
                }
                res.json(result);
            }
        }
    });
});

// transferred from dev added function call to geohash library

router.get(`/decode_geohash`, async function (req, res, next) {
    if (req.query.geohash.length == 16) {
        let latlon = geohash.decode_hash(req.query.geohash, 52);
        res.send(latlon);
    } else if (req.query.geohash.length == 9) {
        let latlon = geohash.decode_hash(req.query.geohash, 30);
        res.send(latlon);
    } else {
        res.status(400).send("geohash looks sus");
    }
});

/**
 * API 4.0
 * Query for all ORB to user interactions
 * Query for all your buddies or baddies(?)
 */
router.get(`/buddy`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        KeyConditionExpression: "PK = :pk and begins_with(SK, :buddy)",
        ExpressionAttributeValues: {
            ":pk": "USR#" + req.query.user_id + "#REL",
            ":buddy": req.query.relation + "#",
        },
        Limit: 8,
        ScanIndexForward: req.query.ascending,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "PK": "USR#" + req.query.user_id,
            "SK": req.query.relation +"#" + req.query.start
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            err.status = 400;
            next(err);
        } else {
            if (data.Items.length == 0) {
                res.status(204).send()
            } else {
                let data_arr = [];
                data.Items.forEach(function(item) {
                    let dao = {};
                    dao.buddy_id = item.SK.slice(4);
                    data_arr.push(dao);
                })
                let result = {
                    "data" : data_arr
                }
                if (data.LastEvaluatedKey) result.LastEvaluatedKey = data.LastEvaluatedKey.SK.slice(4);
                res.json(result);
            }
        }
    });
});

router.get(`/postal_check`, async function (req, res, next) {
    if (req.query.code) {
        let check = geohash.check_postal(req.query.code);
        if (check) {
            res.status(200).json({
                "postal": true
            });
        } else {
            res.status(404).json({
                "postal": false
            });
        }
    } else {
        res.status(400).json({
            "Error": "please input code"
        });
    }
});


module.exports = router;
