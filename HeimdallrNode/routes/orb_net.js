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
// const onemap = require('./../resources/onemap3.json')
const fs = require('fs');
let rawdata = fs.readFileSync('./resources/onemap3.json', 'utf-8');
let onemap = JSON.parse(rawdata);

/**
 * API 0
 * Create orb
 */
router.post(`/post_orb`, async function (req, res, next) {
    let body = { ...req.body };
    const orb_uuid = uuidv4();
    let expiry_dt = slider_time(body.expires_in);
    let created_dt = moment().unix();
    let geohashing = postal_to_geo(body.postal_code);
    let params = {
        RequestItems: {
            "ORB_NET": [
                {
                    PutRequest: {
                        Item: {
                            PK: "ORB#" + orb_uuid,
                            SK: "ORB#" + expiry_dt.toString(),
                            numeric: body.nature,
                            time: created_dt,
                            geohash : geohashing,
                            payload: JSON.stringify({
                                Title: body.title,
                                Info: body.info,
                                Where: body.where,
                                When: body.when,
                                Tip: body.tip
                            })
                        }
                    }
                },
                {
                    PutRequest: {
                        Item: {
                            PK: "LOC#" + geohashing,
                            SK: expiry_dt.toString() + "#ORB#" + orb_uuid,
                            // SK: "ORB#" + moment(7,'day').unix(),
                            inverse: body.nature.toString(),
                            geohash : geohashing
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
                    "ORB ID": orb_uuid,
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

/**
 * API DEPRECATED
 * Create orb
 */
router.post(`/d_post_orb`, async function (req, res, next) {
    let body = { ...req.body };
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        Item: {
            PK: "ORB#" + uuidv4(),
            SK: "ORB#" + moment().add(604800, 's').unix(),
            numeric: body.nature,
            time: created_dt,
            geohash : body.geohash,
            payload: JSON.stringify({
                Title: body.title,
                Info: body.info,
                Where: body.where,
                When: body.when,
                Tip: body.tip
            })
        },
    };
    docClient.put(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json({
                "PutItem succeeded:": {
                    "ORB ID": params.Item.PK.slice(4)
                }
            });
        }
        });
});

/**
 * API 1 
 * Get specific orb (all info) by ORB:uuid and expiry
 */
router.get(`/get`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,        
        Key: {
            PK: "ORB#" + req.query.orb_uuid,
            SK: "ORB#" + req.query.expiry
        }
    };
    
    docClient.get(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            debugger;
            if (data.Item){
                let dao = {};
                dao.title = JSON.parse(data.Item.payload).Title;
                dao.info = JSON.parse(data.Item.payload).Info;
                dao.where = JSON.parse(data.Item.payload).Where;
                dao.when = JSON.parse(data.Item.payload).When;
                dao.tip = JSON.parse(data.Item.payload).Tip;
                dao.expiry_dt = data.Item.SK.slice(4);
                dao.created_dt = data.Item.time;
                dao.nature = data.Item.numeric;
                dao.uuid = data.Item.PK.slice(4);
                dao.geohash = data.Item.geohash;
                res.json(dao);
            } else {
                res.json("cant find shit")
            }
        }
    });
});

/**
 * API 1.1 DEV
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
 * API 1.2
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
 * API 1.3 DEV
 * Scan for all pk = ORB
 */
router.get(`/scan_all`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,    
        FilterExpression: "begins_with(PK, :orb)",
        ExpressionAttributeValues: {
            ":orb": "ORB#"
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
 * API 1.4 DEV
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
 * API 1.4 DEV
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
 * API 1.5 DEV
 * Scan for all ORBs in a geo location
 */
router.get(`/orbs_in_loc`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        FilterExpression: "PK between :start_loc and :end_loc and begins_with(SK,:orb)",
        ExpressionAttributeValues: {
            ":start_loc":   "LOC#" + "232332420",
            ":end_loc":     "LOC#" + "999999999",
            ":orb":"ORB#"
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
 * API 1.5
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
        debugger;
        let postal = req.query.postal_code;
        let geohashing = postal_to_geo(postal);
        let geohash_arr = get_geo_array(geohashing);
        let page = []
        for (let g of geohash_arr) {
            let result = batch_query_location(g);
            if (result){
                for (let i of result) {
                    page.push(i)
                }
            }
        }
        res.json(page)
    } catch (err) {
        res.json("err")
    }
    
});
//NW 3949703750517866 1125991258849301
//SE 3949719478713446 1125991258849301

// central 3949705054216902
// south 3949705007232706
// east 3949705412985454


function postal_to_geo(postal) {
    postal = postal.toString();
    let latlon = onemap[postal];
    let geohashing = geohash.encode_int(parseInt(latlon.LATITUDE), parseInt(latlon.LONGTITUDE), 52);
    return geohashing;
}

function get_geo_array(geohashing) {
    let arr = geohash.neighbors_int(geohashing, 52); // array
    arr.unshift(geohashing);
    return arr;
}

function batch_query_location(geohashing) {
    let dao = [];
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        KeyConditionExpression: "PK = :loc and SK > :current_time",
        ExpressionAttributeValues: {
            ":loc": "LOC#" + geohashing,
            ":current_time": moment().unix()
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            // res.status(400).send({ Error: err.message });
            console.log(err.message)
        } else {
            data.Items.forEach(function(item) {
                dao.push(item)
            })
        }
    });
    return dao;
}

/**
 * API 0
 * Bookmark Orb
 */
router.post(`/bookmark`, async function (req, res, next) {
    let body = { ...req.body };
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        Item: {
            PK: "ORB#" + body.orb_uuid,
            SK: "USER#" + body.user,
            inverse: "400#BOOKMARK"
        },
    };
    docClient.put(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json({"PutItem succeeded:": params.Item.orb_uuid});
        }
        });
});

// recency ends with (everything after current time seconds)
// 600INIT, 500ACCEPT, 400BOOKMARK, 


module.exports = router;