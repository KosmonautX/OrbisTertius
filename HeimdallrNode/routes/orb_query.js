const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment');
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
                dao.title = data.Item.payload.title;
                dao.info = data.Item.payload.info;
                dao.where = data.Item.payload.where;
                dao.when = data.Item.payload.when;
                dao.tip = data.Item.payload.tip;
                dao.user_id = parseInt(data.Item.payload.user_id);
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
// router.get(`/get_user`, async function (req, res, next) {
//     let params = {
//         TableName: ddb_config.tableNames.orb_table,        
//         Key: {
//             PK: "USR#" + req.query.user_id,
//             SK: "USR#" + req.query.user_id
//         }
//     };
//     docClient.get(params, function(err, data) {
//         if (err) {
//             res.status(400).send({ Error: err.message });
//         } else {
//             if (data.Item){
//                 let dao = {};
//                 dao.user_id = req.query.user_id;
//                 dao.username = data.Item.alphanumeric;
//                 dao.bio = data.Item.payload.bio;
//                 dao.profile_pic = data.Item.payload.profile_pic;
//                 dao.verified = data.Item.payload.verified;
//                 dao.country_code = data.Item.payload.country_code;
//                 dao.hp_number = data.Item.payload.hp_number;
//                 dao.gender = data.Item.payload.gender;
//                 dao.birthday = data.Item.payload.birthday;
//                 dao.home = data.Item.numeric;
//                 dao.office = data.Item.geohash;
//                 res.json(dao);
//             } else {
//                 res.status(404).json("User not found")
//             }
//         }
//     });
// });

router.get(`/get_user`, async function (req, res, next) {
    let pteData = await userQuery.queryPTE(req).catch(err => {
        err.status = 400;
        next(err);
    });
    let pubData = await userQuery.queryPUB(req).catch(err => {
        err.status = 400;
        next(err);
    });

    if (pteData && pubData) {
        let dao = {};
        dao.user_id = parseInt(req.query.user_id);
        dao.username = pubData.Item.alphanumeric;
        dao.bio = pubData.Item.payload.bio;
        dao.profile_pic = pubData.Item.payload.profile_pic;
        dao.verified = pubData.Item.payload.verified;
        dao.country_code = pteData.Item.payload.country_code;
        dao.hp_number = pteData.Item.payload.hp_number;
        dao.gender = pteData.Item.payload.gender;
        dao.birthday = pteData.Item.payload.birthday;
        dao.home = pteData.Item.numeric;
        dao.office = pteData.Item.geohash;
        res.json(dao);
    } else {
        res.status(404).json("User not found")
    }
});

const userQuery = {
    async queryPTE(req) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + req.query.user_id,
                SK: "USR#" + req.query.user_id + "#pte"
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
    async queryPUB(req) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + req.query.user_id,
                SK: "USR#" + req.query.user_id + "#pub"
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
}

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
                    dao.user_id = parseInt(item.SK.slice(4));
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
    let userActions = ['save','hide','rprt'] 
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
                    dao.user_id = parseInt(item.SK.slice(4).slice(0,-5));
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
                    dao.user_id = parseInt(item.SK.slice(4));
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
                    dao.geohash = parseInt(item.PK.slice(4))
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
                    if (item.payload) dao.payload = item.payload;
                    page.push(dao);
                }
            }
        }
        if (page.length > 0) {
            res.json(page)
        } else {
            res.status(204).json("nothing")
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
            ":buddy": "BUD#",
        },
        Limit: 8,
        ScanIndexForward: req.query.ascending,
    };
    if (req.query.start) {
        params.ExclusiveStartKey = {
            "PK": "USR#" + req.query.user_id,
            "SK": "BUD#" + req.query.start
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
                    dao.buddy_id = parseInt(item.SK.slice(4));
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
