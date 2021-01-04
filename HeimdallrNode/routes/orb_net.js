const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment')
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region,
    endpoint: ddb_config.endpoint
})
const docClient = new AWS.DynamoDB.DocumentClient();
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
    if (body.latlon) {
        geohashing = latlon_to_geo(body.latlon); 
    } else if (body.postal_code) {
        geohashing = postal_to_geo(body.postal_code);
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
                            geohash : geohashing,
                            inverse: "LOC#" + geohashing,
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
                            PK: "LOC#" + geohashing,
                            SK: expiry_dt.toString() + "#ORB#" + orb_uuid,
                            inverse: body.nature.toString(),
                            geohash : geohashing
                        }
                    }
                },
                {
                    PutRequest: {
                        Item: {
                            PK: "ORB#" + orb_uuid,
                            SK: "USER#" + body.user_id,
                            inverse: "600#INIT",
                            time : created_dt
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
            res.json({
                "PutItem succeeded:": {
                    "ORB UUID": orb_uuid,
                    "expiry": expiry_dt
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
    else if (keyword.toUpperCase() == "BOOKMARK") code = "400#BOOKMARK"
    return code;
}

/**
 * API 0.1
 * Register user
 * user_id = telegram_id
 */
router.post(`/post_user`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let geohashing;
        if (body.lat && body.lon) {
            let latlon = {};
            latlon.LATITUDE = body.lat;
            latlon.LONGTITUDE = body.lon;
            geohashing = latlon_to_geo(latlon);
        } else if (body.postal_code) {
            geohashing = postal_to_geo(body.postal_code);
        }
        let params = {
            TableName: ddb_config.tableNames.orb_table,        
            Item: {
                PK: "USER#" + body.user_id, 
                SK: "USER#" + body.user_id,
                payload: JSON.stringify({
                    bio: body.bio,
                    profile_pic: body.profile_pic,
                    username: body.username,
                    verified: body.verified,

                }),
                numeric: body.postal_code,
                geohash: geohashing
            }
        };
        docClient.put(params, function(err, data) {
            if (err) {
                res.status(400).send({ Error: err.message });
            } else {
                res.json({
                    "User Registered:": {
                        "USER ID": body.user_id
                    }
                });
            }
            });
    } catch (err) {
        res.json(err.message);
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
                res.json({
                    "Interaction:": {
                        "Type": body.keyword,
                        "ORB UUID": body.orb_uuid,
                        "USER ID": body.user_id
                    }
                });
            }
          });
    } catch (err) {
        res.json(err.message);
    }
});

/**
 * API 0.3
 * Update ORB status
 */
router.put(`/complete_orb`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,        
        Key: {
            PK: "ORB#" + req.query.orb_uuid,
            SK: "USER#" + req.query.user_id
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
            res.json({
                "ORB updated as FULFILLED:": {
                    "ORB UUID": req.query.orb_uuid,
                    "USER ID": req.query.user_id
                }
            });
        }
    });
});

/**
 * API 1.1
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
                dao.title = JSON.parse(data.Item.payload).title;
                dao.info = JSON.parse(data.Item.payload).info;
                dao.where = JSON.parse(data.Item.payload).where;
                dao.when = JSON.parse(data.Item.payload).when;
                dao.tip = JSON.parse(data.Item.payload).tip;
                dao.user_id = JSON.parse(data.Item.payload).user_id;
                dao.username = JSON.parse(data.Item.payload).username;
                dao.photo = JSON.parse(data.Item.payload).photo;
                dao.tags = JSON.parse(data.Item.payload).tags;
                dao.expiry_dt = data.Item.time;
                dao.created_dt = JSON.parse(data.Item.payload).created_dt;
                dao.nature = data.Item.numeric;
                dao.uuid = data.Item.PK.slice(4);
                dao.geohash = data.Item.geohash;
                res.json(dao);
            } else {
                res.json("ORB not found")
            }
        }
    });
});

/**
 * API 1.4
 * Get specific user (all info) 
 */
router.get(`/get_user`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,        
        Key: {
            PK: "USER#" + req.query.user_id,
            SK: "USER#" + req.query.user_id
        }
    };
    docClient.get(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            if (data.Item){
                let dao = {};
                dao.user_id = data.Item.PK.slice(5);
                dao.username = JSON.parse(data.Item.payload).username;
                dao.bio = JSON.parse(data.Item.payload).bio;
                dao.profile_pic = JSON.parse(data.Item.payload).profile_pic;
                dao.verified = JSON.parse(data.Item.payload).verified;
                dao.postal_code = data.Item.numeric;
                dao.geohash = data.Item.geohash;
                res.json(dao);
            } else {
                res.json("User not found")
            }
        }
    });
});

/**
 * API DEV
 * Query via PK to retrieve everything related to primary key
 */
// // Get orbs posted by user with U:uuid
router.get(`/query`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        KeyConditionExpression: "PK = :pk",
        ExpressionAttributeValues: {
            ":pk": req.query.pk,
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            // res.json(data);
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * API UNRELEASED
 * Query to get comments for particular ORB
 */
// // Get orbs posted by user with U:uuid
router.get(`/comment`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        KeyConditionExpression: "PK = :pk and begins_with(SK, :comment)",
        ExpressionAttributeValues: {
            ":pk": "ORB#" + req.query.orb_uuid,
            ":comment": "COMMENT"
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * API DEV
 * Scan for all pk = ORB
 */
router.get(`/scan_all`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        FilterExpression: "begins_with(PK, :orb)",
        ExpressionAttributeValues: {
            ":orb": req.query.key
        }
    };
    docClient.scan(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            // res.json(data);
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * API DEV
 * Scan for all ORBs after certain time
 */
router.get(`/all_orbs`, async function (req, res, next) {
    let dt = req.query.date + " " + req.query.time
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        FilterExpression: "begins_with(PK, :orb) and SK > :current_time and begins_with(SK,:orb)",
        ExpressionAttributeValues: {
            ":orb":"ORB#",
            ":current_time": "ORB#" + moment(dt).unix()
        }
    };
    docClient.scan(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            // res.json(data);
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * API DEV
 * Scan for all ORBs not expired yet
 */
router.get(`/current_orbs`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        FilterExpression: "begins_with(PK, :orb) and SK > :current_time and begins_with(SK,:orb)",
        ExpressionAttributeValues: {
            ":orb":"ORB#",
            ":current_time": "ORB#" + moment().unix()
        }
    };
    docClient.scan(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});


/**
 * API 1.3
 * Multiple functions: 
 *      1. Get orbs posted by a user
 *      2. Get orbs accepted by a user
 *      3. Get orbs bookmarked by a user 
 */
router.get(`/get_orb_profile`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        IndexName: "Chronicle",
        KeyConditionExpression: "SK = :user and inverse = :sort",
        ExpressionAttributeValues: {
            ":user": "USER#" + req.query.user_id,
            ":sort": keyword_to_code(req.query.keyword)
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * API 1.2
 * QUERY for all fresh ORBs in a geohash
 */
router.get(`/orbs_in_loc_fresh`, async function (req, res, next) {
    let postal = req.query.postal_code.toString();
    let latlon = onemap[postal];
    let geohashing = geohash.encode(latlon.LATITUDE, latlon.LONGTITUDE, 9);
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        KeyConditionExpression: "PK = :loc and SK > :current_time",
        ExpressionAttributeValues: {
            ":loc": "LOC#" + geohashing,
            ":current_time": moment().unix() + "#ORB#"
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            // res.json(data);
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
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
            latlon.LONGTITUDE = req.query.lon;
            geohashing = latlon_to_geo(latlon);
        } else if (req.query.postal_code) {
            let postal = req.query.postal_code;
            geohashing = postal_to_geo(postal);
        } else {
            throw new Error('Please give either postal_code or latlon')
        }
        let geohash_arr = get_geo_array(geohashing);
        let page = [];
        for (let g of geohash_arr) {
            let result = await batch_query_location(g);
            if (result){
                for (let i of result) {
                    page.push(i);
                }
            }
        }
        if (page.length > 0) {
            res.json(page)
        } else {
            res.json("No fresh ORBS")
        }
    } catch (err) {
        res.json(err.message);
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
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGTITUDE), 30);
    return geohashing;
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

async function batch_query_location(geohashing) {
    return new Promise((resolve, reject) => {
        let params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and SK > :current_time",
            // FilterExpression: "",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohashing.toString(),
                ":current_time": moment().unix().toString()
            }
        };
        docClient.query(params, function(err, data) {
            if (err) {
                // console.log(err.message);
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