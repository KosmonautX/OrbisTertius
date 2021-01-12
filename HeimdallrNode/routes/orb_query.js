const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment')
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
})
const docClient = new AWS.DynamoDB.DocumentClient({endpoint: ddb_config.dyna});
const geohash = require('ngeohash');
const fs = require('fs');
const rawdata = fs.readFileSync('./resources/onemap3.json', 'utf-8');
const onemap = JSON.parse(rawdata);

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
                dao.orb_uuid = data.Item.PK.slice(4);
                dao.geohash = parseInt(data.Item.inverse.slice(4));
                dao.geohash52 = data.Item.geohash;
                res.json(dao);
            } else {
                res.status(404).json("ORB not found")
            }
        }
    });
});

/**
 * API 1 
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
                dao.user_id = parseInt(data.Item.PK.slice(5));
                dao.username = JSON.parse(data.Item.payload).username;
                dao.bio = JSON.parse(data.Item.payload).bio;
                dao.profile_pic = JSON.parse(data.Item.payload).profile_pic;
                dao.verified = JSON.parse(data.Item.payload).verified;
                dao.postal_code = data.Item.numeric;
                dao.verified = JSON.parse(data.Item.payload).verified;
                dao.country_code = JSON.parse(data.Item.payload).country_code;
                dao.hp_number = JSON.parse(data.Item.payload).hp_number;
                dao.gender = JSON.parse(data.Item.payload).gender;
                dao.birthday = JSON.parse(data.Item.payload).birthday;
                dao.geohash = data.Item.geohash;
                res.json(dao);
            } else {
                res.status(404).json("User not found")
            }
        }
    });
});

/**
 * API 2
 * Get orbs for a user:
 * INIT | ACCEPT | BOOKMARK | FULFILLED
 */
router.get(`/get_orb_profile`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        IndexName: "Chronicle",
        KeyConditionExpression: "SK = :user and inverse = :sort",
        ExpressionAttributeValues: {
            ":user": "USER#" + req.query.user_id,
            ":sort": keyword_to_code(req.query.keyword)
        },
        Limit: 8,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "SK": "USER#" + req.query.user_id,
            "inverse": keyword_to_code(req.query.keyword),
            "PK": req.query.start
        }
    }
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            let data_arr = [];
            data.Items.forEach(function(item) {
                let dao = {};
                dao.user_id = item.SK.slice(5);
                dao.orb_uuid = item.PK.slice(4);
                dao.created_dt = item.time;
                dao.geohash = item.geohash;
                dao.info = item.inverse.slice(4);
                if (item.payload) dao.payload = JSON.parse(item.payload);
                data_arr.push(dao);
            })
            let result = {
                "data" : data_arr
            }
            if (data.LastEvaluatedKey) result.LastEvaluatedKey = data.LastEvaluatedKey.PK.slice(4)
            res.json(result);
        }
    });
});

function keyword_to_code(keyword) {
    let code = "9000#ERROR"
    if (keyword.toUpperCase() == "INIT") code = "600#INIT";
    else if (keyword.toUpperCase() == "FULFILLED") code = "800#FULFILLED";
    else if (keyword.toUpperCase() == "ACCEPT") code = "500#ACCEPT";
    else if (keyword.toUpperCase() == "BOOKMARK") code = "400#BOOKMARK";
    else if (keyword.toUpperCase() == "DELETE") code = "300#DELETE";
    else if (keyword.toUpperCase() == "HIDE") code = "200#HIDE";
    else if (keyword.toUpperCase() == "REPORT") code = "100#REPORT";
    return code;
}

/**
 * API 1.5
 * QUERY for all fresh ORBs in a geohash
 */
router.get(`/orbs_in_loc_fresh_page`, async function (req, res, next) {
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
    if (req.query.page) {
        let geohash_arr = get_geo_array(geohashing);
        geohashing = geohash_arr[req.query.page]
    }
    let params = {
        TableName: ddb_config.tableNames.orb_table,
        KeyConditionExpression: "PK = :loc and SK > :current_time",
        ExpressionAttributeValues: {
            ":loc": "LOC#" + geohashing,
            ":current_time": moment().unix().toString()
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            let data_arr = [];
            data.Items.forEach(function(item) {
                let dao = {};
                dao.orb_uuid = item.SK.slice(15);
                dao.geohash = parseInt(item.PK.slice(4))
                dao.geohash52 = item.geohash;
                dao.nature = parseInt(item.inverse);
                dao.expiry_dt = parseInt(item.SK.substr(0, 10));
                if (item.payload) dao.payload = JSON.parse(item.payload);
                data_arr.push(dao);
            })
            res.json(data_arr);
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
                for (let item of result) {
                    let dao = {};
                    dao.orb_uuid = item.SK.slice(15);
                    dao.geohash = parseInt(item.PK.slice(4))
                    dao.geohash52 = item.geohash;
                    dao.nature = parseInt(item.inverse);
                    dao.expiry_dt = parseInt(item.SK.substr(0, 10));
                    if (item.payload) dao.payload = JSON.parse(item.payload);
                    page.push(dao);
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
                ":loc": "LOC#" + geohashing,
                ":current_time": moment().unix().toString()
            }
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
