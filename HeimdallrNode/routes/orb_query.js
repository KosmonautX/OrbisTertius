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
 * Get specific orb (all info) by ORB:uuid
 */
router.get(`/get`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,        
        Key: {
            PK: "ORB#" + req.query.orb_uuid,
            SK: "ORB#" + req.query.orb_uuid
        }
    };
    docClient.get(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            if (data.Item){
                let dao = {};
                dao.expiry_dt = data.Item.time;
                dao.nature = data.Item.numeric;
                dao.orb_uuid = data.Item.PK.slice(4);
                dao.geohash = parseInt(data.Item.alphanumeric.slice(4));
                dao.geohash52 = data.Item.geohash;
                dao.payload = data.Item.payload
                res.json(dao);
            } else {
                res.status(404).json("ORB not found");
            }
        }
    });
});
/**
 * API 1
 * Get specific orb (all info) by ORB:uuid
 */
router.get(`/get_orbs/:orb_uuids`, async function (req, res, next) {
    try{
        const n = 5 // limit to 5
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
        Promise.all(orbs.map(orb_uuid => getter(orb_uuid))).then(response => {
            daos = response.map(async(data) => {
                var dao = {}
                if(data.Item){
                    dao.expiry_dt = data.Item.time;
                    dao.orb_uuid = data.Item.PK.slice(4);
                    dao.payload = data.Item.payload
                    if(data.Item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','ORB',dao.orb_uuid,'1920x1080');
                    dao.geohash = parseInt(data.Item.alphanumeric.slice(4));
                    dao.geohash52 = data.Item.geohash;
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
        const n = 5
        const users = req.params.user_ids.split(',').slice(0,n)
        Promise.all(users.map(user_id => userQuery.queryPUB(user_id))).then(response => {
            daos = response.map(async(data) => {
                var dao = {}
                if(data.Item){
                    if (data.Item.payload) {
                        dao.payload = data.Item.payload
                        if(data.Item.payload.media) dao.media_asset = await serve3.preSign('getObject','USR',req.params.user_id,'150x150')}
                    dao.user_id = data.Item.PK.slice(4);
                    dao.username = data.Item.alphanumeric;
                    dao.home_geohash = data.Item.numeric;
                    dao.office_geohash = data.Item.geohash;
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
/**
 * API 1 
 * Get specific user (all info) 
 */
router.get(`/get_user`, async function (req, res, next) {
    // let pteData = await userQuery.queryPTE(req).catch(err => {
    //     err.status = 400;
    //     next(err);
    // });
    let pubData = await userQuery.queryPUB(req.query.user_id).catch(err => {
        err.status = 400;
        next(err);
    });

    if (pubData.Item) {
        let dao = {};
        if (pubData.Item.payload) {
            dao.bio = pubData.Item.payload.bio;
            dao.profile_pic = pubData.Item.payload.profile_pic;
            dao.media = pubData.Item.payload.media
            if(pubData.Item.payload.media) dao.media_asset = await serve3.preSign('getObject','USR',req.query.user_id,'1920x1080')
            //dao.verified = pubData.Item.payload.verified;
            // dao.country_code = pteData.Item.payload.country_code;
        }
        // if (pteData.Item.payload){
        //     dao.gender = pteData.Item.payload.gender;
        //     dao.birthday = pteData.Item.payload.birthday;
        // }
        dao.user_id = req.query.user_id;
        dao.username = pubData.Item.alphanumeric;
        // dao.home = pteData.Item.numeric;
        // dao.office = pteData.Item.geohash;
        dao.home_geohash = pubData.Item.numeric;
        dao.office_geohash = pubData.Item.geohash;
        dao.home_geohash52 = pubData.Item.numeric2;
        dao.office_geohash52 = pubData.Item.geohash2;
        // dao.join_dt = pteData.Item.join_dt;
        res.json(dao);
    } else {
        res.status(404).json("User not found");
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
        KeyConditionExpression: "SK = :user and inverse = :sort",
        ExpressionAttributeValues: {
            ":user": "USR#" + req.query.user_id,
            ":sort": keyword_to_code(req.query.keyword)
        },
        Limit: 8,
        ScanIndexForward: req.query.ascending,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "SK": "USR#" + req.query.user_id,
            "inverse": keyword_to_code(req.query.keyword),
            "PK": "ORB#" + req.query.start
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            err.status = 400;
            next(err);
        } else {
            if (data.Items.length == 0) {
                res.status(204).send();
            } else {
                let data_arr = [];
                data.Items.forEach(function(item) {
                    let dao = {};
                    dao.user_id = item.SK.slice(4);
                    dao.orb_uuid = item.PK.slice(4);
                    dao.created_dt = item.time;
                    dao.geohash = item.geohash;
                    dao.info = item.inverse.slice(4);
                    data_arr.push(dao);
                })
                let result = {
                    "Requested": req.query.keyword,
                    "Data" : data_arr,
                }
                if (data.LastEvaluatedKey) result.LastEvaluatedKey = data.LastEvaluatedKey.PK.slice(4)
                res.json(result);
            }
        }
    });
});

function keyword_to_code(keyword) {
    let code = "error"
    if (keyword.toUpperCase() == "INIT") code = "600#INIT";
    else if (keyword.toUpperCase() == "FULFILLED") code = "800#FULFILLED";
    else if (keyword.toUpperCase() == "ACCEPT") code = "500#ACCEPT";
    else if (keyword.toUpperCase() == "COMPLETED") code = "801#COMPLETED";
    else if (keyword.toUpperCase() == "PENDING") code = "550#PENDING";
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
                    dao.created_dt = item.inverse;
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

/**
 * API 1.2
 * Query for all ORB to user interactions
 */
router.get(`/orb_acceptance`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        KeyConditionExpression: "PK = :pk and begins_with(SK, :user)",
        FilterExpression: "inverse > :space",
        ExpressionAttributeValues: {
            ":pk": "ORB#" + req.query.orb_uuid,
            ":user": "USR#",
            ":space": "499#"
        },
        Limit: 8,
        ScanIndexForward: req.query.ascending,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "PK": "ORB#" + req.query.orb_uuid,
            "SK": "USR#" + req.query.start
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
                    dao.user_id = item.SK.slice(4);
                    dao.orb_uuid = item.PK.slice(4);
                    dao.created_dt = item.time;
                    dao.geohash = item.geohash;
                    dao.info = item.inverse.slice(4);
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

/**
 * API 1.5
 * QUERY for all fresh ORBs in a geohash
 */
router.get(`/orbs_in_loc_fresh_page`, async function (req, res, next) {
    let geohashing;
    if (req.query.lat && req.query.lon) {
        let latlon = {};
        latlon.LATITUDE = req.query.lat;
        latlon.LONGITUDE = req.query.lon;
        geohashing = geohash.latlon_to_geo(latlon);
    } else if (req.query.postal_code) {
        let postal = req.query.postal_code;
        geohashing = geohash.postal_to_geo(postal);
    } else {
        throw new Error('Please give either postal_code or latlon')
    }
    if (req.query.page) {
        let geohash_arr = geohash.get_geo_array(geohashing);
        geohashing = geohash_arr[req.query.page]
    }
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        KeyConditionExpression: "PK = :loc and SK BETWEEN :current_time AND :future_time",
        ExpressionAttributeValues: {
            ":loc": "LOC#" + geohashing,
            ":current_time": moment().unix().toString(),
            ":future_time": "4136173415"
        },
        ScanIndexForward: false,
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
                    dao.orb_uuid = item.SK.slice(15);
                    dao.geohash = parseInt(item.PK.slice(4));
                    dao.geohash52 = item.geohash;
                    dao.nature = parseInt(item.inverse);
                    dao.expiry_dt = parseInt(item.SK.substr(0, 10));
                    if (item.payload) dao.payload = item.payload;
                    data_arr.push(dao);
                })
                res.json(data_arr);
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
 * API 1.5
 * QUERY for all fresh ORBs in a geohash
 */
router.get(`/orbs_in_loc_fresh_batch`, async function (req, res, next) {
    try {
        let geohashing;
        if (req.query.lat && req.query.lon) {
            let latlon = {};
            latlon.LATITUDE = req.query.lat;
            latlon.LONGITUDE = req.query.lon;
            geohashing = geohash.latlon_to_geo(latlon);
        } else if (req.query.postal_code) {
            let postal = req.query.postal_code;
            geohashing = geohash.postal_to_geo(postal);
        } else {
            throw new Error('Please give either postal_code or latlon');
        }
        let geohash_arr = geohash.get_geo_array(geohashing);
        let page = [];
        for (let g of geohash_arr) {
            let result = await batch_query_location(g);
            if (result){
                for (let item of result) {
                    let dao = {};
                    dao.orb_uuid = item.SK.slice(15);
                    // dao.geohash = parseInt(item.PK.slice(4));
                    // dao.geohash52 = item.geohash;
                    //dao.nature = parseInt(item.inverse.slice(4));
                    dao.expiry_dt = parseInt(item.SK.substr(0, 10));
                    if (item.payload){
                        dao.payload = item.payload
                        if(item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','ORB',dao.orb_uuid,'150x150')
                        if(item.payload.init){
                            dao.payload.init = item.payload.init;
                            if(item.payload.init.media) dao.payload.init.media_asset = await serve3.preSign('getObject','USR',item.payload.user_id,'150x150')}
                    }
                    page.push(dao);
                }
            }
        }
        if (page.length > 0) {
            res.json(page)
        } else {
            res.status(204).json("nothing burger")
        }
    } catch (err) {
        if (err.message == 'Please give either postal_code or latlon') err.status = 400;
        next(err);
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

async function batch_query_location(geohashing) {
    return new Promise((resolve, reject) => {
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and SK BETWEEN :current_time AND :future_time",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohashing,
                ":current_time": moment().unix().toString(),
                ":future_time": "4136173415"
            },
            ScanIndexForward: false,
        };
        docClient.query(params, function(err, data) {
            if (err) {
                reject(err.message);
            } else {
                let dao = [];
                data.Items.forEach(function(item) {
                    dao.push(item)
                })
                resolve(dao);
            }
        });
    })
}


module.exports = router;
