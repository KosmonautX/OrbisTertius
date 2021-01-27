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
const geohash = require('ngeohash');
const fs = require('fs');
const rawdata = fs.readFileSync('./resources/onemap3.json', 'utf-8');
const onemap = JSON.parse(rawdata);

// body: first, second, username, gender, age
router.post(`/setup`, async function (req, res, next) {
    let body = { ...req.body };
    // body.orb_uuid = uuidv4();
    body.created_dt = moment().unix();
    try {
        body.geohashing = {
            first: postal_to_geo(body.first),
            second: postal_to_geo(body.second)
        };
        let success = await dynaUser.Tcreate(body).catch(err => {
            res.status(400).json(err.message);
        })
        if (success == true) {
            await dynaUser.Bcreate(body).catch(err => {
                err.status = 400
                throw err;
            })
            res.status(201).json({
                "User created": body.user_id,
            });
        }
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err)
    }
});

// returns commercial, first, second, no. of users (count)
router.get(`/start`, async function (req, res, next) {
    try {
        let pteData = await dynaUser.getPTEinfo(req.query).catch(err => {
            err.status = 500;
            throw err;
        });
        let pubData = await dynaUser.getPUBinfo(req.query).catch(err => {
            err.status = 500;
            throw err;
        });
        if (pteData && pubData) {
            let homeUser = await dynaUser.getAllUsers(pubData.Item.numeric).catch(err => {
                err.status = 500;
                throw err;
            })
            let officeUser = await dynaUser.getAllUsers(pubData.Item.geohash).catch(err => {
                err.status = 500;
                throw err;
            })
            let checkGender = true;
            let checkAge = true;
            if (pteData.Item.payload.gender == null) checkGender = false;
            if (pteData.Item.payload.age == null) checkAge = false;
            res.status(200).send({
                "commercial": pubData.Item.payload.commercial,
                "first": pteData.Item.numeric,
                "second": pteData.Item.geohash,
                "firstGeo": pubData.Item.numeric,
                "secondGeo": pubData.Item.geohash,
                "homeCount": homeUser.Count,
                "officeCount": officeUser.Count,
                "gender": checkGender,
                "age": checkAge,
            })
        } else {
            res.status(404).json("User not found")
        }
    } catch (err) {
        next(err)
    }
});

// receive user id, commercial?, first | second location
// returns list of users
router.get(`/recipients`, async function (req, res, next) {
    try {
        const geohashing = postal_to_geo(req.query.postal_code);
        let blockedList = await dynaUser.getBlockedList(req.query).catch(err => {
            err.status = 500;
            throw err;
        });
        let blockedUsers = [];
        if (blockedList.Count != 0) {
            blockedList.Items.forEach( item => {
                blockedUsers.push(parseInt(item.SK.slice(4)));
            });
        }
        if (req.query.commercial == true || req.query.commercial.toLowerCase() == 'true') {
            let users = await dynaUser.getCommercialUsers(geohashing).catch(err => {
                err.status = 500;
                throw err;
            });
            if (users.Count == 0 ) {
                res.status(204).send();
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.slice(5)));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item))
                }
                res.status(200).send({
                    "users": users_arr,
                })
            }
        } else {
            let users = await dynaUser.getAllUsers(geohashing).catch(err => {
                err.status = 500;
                throw err;
            });
            if (users.Count == 0 ) {
                res.status(204).send();
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.split('#')[1]));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item))
                }
                res.status(200).send({
                    "users": users_arr,
                })
            }
        }
    } catch (err) {
        next(err)
    }
});

// user block a user
router.post(`/block`, async function (req, res, next) {
    let body = { ...req.body};
    let orbInfo = await dynaOrb.retrieve(body).catch(err => {
        err.status = 500;
        next(err);
    });
    let block;
    if (orbInfo) {
        body.block_id = orbInfo.user_id;
        block = await dynaUser.blockUser(body).catch(err => {
            err.status = 500;
            next(err);
        });
    }
    if (block) res.status(200).send("user block");
});

// user set age  
router.put(`/setAge`, async function (req, res, next) {
    let body = { ...req.body};
    let setting = await dynaUser.setAge(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (setting) res.status(200).send("Age set");
});

// user set   gender
router.put(`/setGender`, async function (req, res, next) {
    let body = { ...req.body};
    let setting = await dynaUser.setGender(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (setting) res.status(200).send("Gender set");
});

// Set commercial setting
router.put(`/setCommercial`, async function (req, res, next) {
    let body = { ...req.body};
    let userInfo = await dynaUser.getPUBinfo(body).catch(err => {
        err.status = 500;
        next(err);
    });
    body.first = userInfo.Item.numeric;
    body.second = userInfo.Item.geohash;
    if (body.value) {
        body.old = "c";
        body.new = "";
    } else {
        body.old = "";
        body.new = "c";
    }
    let setting = await dynaUser.setCommercial(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (setting) { 
        let finish = await dynaUser.setCommercial2(body).catch(err => {
            err.status = 500;
            next(err);
        });
        if (finish) res.status(200).send();
    }
});

// Set new postal code setting
// receive user_id, postal_code, old_postal, setting: first | second
router.put(`/setPostal`, async function (req, res, next) {
    try {
        let body = { ...req.body};
        let userInfo = await dynaUser.getPUBinfo(body).catch(err => {
            err.status = 500;
            throw err;
        });
        if (userInfo.Item.payload.commercial == true){
            body.value = "c";
        } else {
            body.value = "";
        }
        if (body.setting == "first") {
            body.place = 'numeric'
        } else {
            body.place = 'geohash'
        }
        let setting = await dynaUser.setPostal(body, 'pte', body.postal_code).catch(err => {
            err.status = 500;
            throw err;
        });
        let setting2 = await dynaUser.setPostal(body, 'pub', postal_to_geo(body.postal_code)).catch(err => {
            err.status = 500;
            throw err;
        });
        if (setting) { 
            let finish = await dynaUser.setPostal2(body,).catch(err => {
                err.status = 500;
                throw err;
            });
            if (finish) res.status(200).send();
        }
    } catch (err) {
        next(err);
    }
});

router.get('/getuuid', async function (req, res, next) {
    const uuid = uuidv4();
    res.status(200).send(uuid);
})

// receive offer/request (orb), info, where, when, tip, username, postal_code, commercial, success_dict
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        body.expiry_dt = moment().add(7, 'days').unix();
        body.created_dt = moment().unix();
        body.geohashing = postal_to_geo(body.postal_code);
        body.geohashing52 = postal_to_geo52(body.postal_code);
        body.title = body.info.split(' ').slice(0,2).join(' ');
        body.title = "From Telegram: " + body.title + "..."
        // offer/request logic
        if (body.orb == "offer") {
            body.nature = 600;
        } else {
            body.nature = 700;
        }
     
        await dynaOrb.postOrb(body).catch(err => {
            err.status = 400;
            throw err;
        })
        res.status(201).json({
            "orb_uuid": body.orb_uuid
        });
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err)
    }
});

// receive orb uuid, user id
router.put(`/complete_orb`, async function (req, res, next) {
    let body = { ...req.body };
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found";
    });
    if (orbData) {
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        const completion = await dynaOrb.update(body).catch(err => {
            err.status = 500;
            next(err);
        });
        if (completion == true) {
            const sDict = await dynaOrb.retrieveSucc(body).catch(err => {
                err.status = 500;
                next(err);
            });
            if (sDict) {
                res.status(200).send(sDict);
            } else {
                res.status(204).send();
            }
        }
    }
});

// receive orb uuid, user id
router.put(`/delete_orb`, async function (req, res, next) {
    let body = { ...req.body};
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found"
    });
    if (orbData) {
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        body.payload = orbData.payload;
        body.payload.available = false;
        const deletion = await dynaOrb.delete(body).catch(err => {
            err.status = 500;
            next(err);
        });
        if (deletion == true) {
            const sDict = await dynaOrb.retrieveSucc(body).catch(err => {
                err.status = 500;
                next(err);
            });
            if (sDict) {
                res.status(200).send(sDict);
            } else {
                res.status(204).send();
            }
        }
    }
});

const dynaUser = {
    async Tcreate(body) {
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
                            numeric: body.geohashing.first,
                            geohash: body.geohashing.second,
                            payload: {
                                commercial: true
                            }
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
    async Bcreate(body) {
        const params = {
            RequestItems: {
                ORB_NET: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "USR#" + body.user_id,
                                SK: "USR#" + body.user_id + "#pte",
                                numeric: body.first,
                                geohash: body.second, 
                                payload: {
                                    gender: body.gender,
                                    age: body.age, 
                                },
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "LOC#" + body.geohashing.first,
                                SK: "USRc#" + body.user_id,
                            }
                        }
                    },
                    {
                        PutRequest: {
                            Item: {
                                PK: "LOC#" + body.geohashing.second,
                                SK: "USRc#" + body.user_id,
                            }
                        }
                    },
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async getPTEinfo(body) {
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
    async getPUBinfo(body) {
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
    async getAllUsers(geohash) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and begins_with(SK, :user)",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohash,
                ":user": "USR",
            },
        }
        const data = await docClient.query(params).promise();
        return data;
    },
    async getCommercialUsers(geohash) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :loc and begins_with(SK, :user)",
            ExpressionAttributeValues: {
                ":loc": "LOC#" + geohash,
                ":user": "USRc#",
            },
        };
        const data = await docClient.query(params).promise();
        return data;
    },
    async getBlockedList (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            KeyConditionExpression: "PK = :usr and begins_with(SK, :ban)",
            ExpressionAttributeValues: {
                ":usr": "USR#" + body.user_id + "#REL",
                ":ban": "BAN#",
            },
        }
        const data = await docClient.query(params).promise();
        return data;
    },
    async blockUser(body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Item: {
                PK: "USR#" + body.user_id + "#REL",
                SK: "BAN#" + body.block_id,
                time: moment().unix(),
            },
        };
        const data = await docClient.put(params).promise();
        return data;
    },
    async setAge (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set payload.age = :age",
            ExpressionAttributeValues: {
                ":age": body.age
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setGender (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pte"
            },
            UpdateExpression: "set payload.gender = :gender",
            ExpressionAttributeValues: {
                ":gender": body.gender
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setCommercial (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + "#pub"
            },
            UpdateExpression: "set payload.commercial = :val",
            ExpressionAttributeValues: {
                ":val": !body.value
            },
            ReturnValues:"UPDATED_NEW"
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setCommercial2 (body) {
        let param1 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + body.first,
                    SK: `USR${body.old}#` + body.user_id, 
                }
            }
        };
        let param2 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + body.second,
                    SK: `USR${body.old}#` + body.user_id, 
                }
            }
        };
        let param3 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + body.first,
                    SK: `USR${body.new}#` + body.user_id, 
                }
            }
        };
        let param4 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + body.second,
                    SK: `USR${body.new}#` + body.user_id, 
                }
            }
        };
        let params = {
            RequestItems: {
                ORB_NET: [param1, param2, param3, param4]
            }
        }
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async setPostal (body, pubpte, code) { 
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + body.user_id, 
                SK: "USR#" + body.user_id + `#${pubpte}`
            },
            UpdateExpression: `set ${body.place} = :loc`,
            ExpressionAttributeValues: {
                ":loc": code
            }
        };
        const data = await docClient.update(params).promise();
        return data;
    },
    async setPostal2 (body) {
        let param1 = {
            DeleteRequest: {
                Key : {
                    PK: "LOC#" + postal_to_geo(body.old_postal),
                    SK: `USR${body.value}#` + body.user_id, 
                }
            }
        };
        let param2 = {
            PutRequest: {
                Item : {
                    PK: "LOC#" + postal_to_geo(body.postal_code),
                    SK: `USR${body.value}#` + body.user_id, 
                }
            }
        };
        let params = {
            RequestItems: {
                ORB_NET: [param1, param2]
            }
        }
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async delete (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "ORB#"
            },
        };
        const data = await docClient.delete(params).promise();
        return data;
    },
};

const dynaOrb = {
    async postOrb (body) {
        const params = {
            RequestItems: {
                ORB_NET: [
                    {
                        PutRequest: {
                            Item: {
                                PK: "ORB#" + body.orb_uuid,
                                SK: "ORB#" + body.orb_uuid, 
                                numeric: body.nature, //  100 OFFER, 200 REQUEST, 300 BROADCAST, 600 TELE OFFER, 700 TELE REQUEST
                                time: body.expiry_dt,
                                geohash : body.geohashing52,
                                inverse: "LOC#" + body.geohashing,
                                payload: {
                                    title: body.title,
                                    info: body.info,
                                    where: body.where,
                                    when: body.when,
                                    tip: body.tip,
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: body.expires_in,
                                    postal_code: body.postal_code,
                                    commercial: body.commercial,
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
                                    user_id: body.user_id,
                                    username: body.username,
                                    created_dt: body.created_dt,
                                    expires_in: 7,
                                    postal_code: body.postal_code,
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
                                payload: body.success_dict
                            }
                        }
                    }
                ]
            }
        };
        const data = await docClient.batchWrite(params).promise();
        return data;
    },
    async retrieve (body) {
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
            dao.user_id = parseInt(data.Item.payload.user_id);
            dao.username = data.Item.payload.username;
            dao.expiry_dt = data.Item.time;
            dao.created_dt = data.Item.payload.created_dt;
            dao.nature = data.Item.numeric;
            dao.orb_uuid = data.Item.PK.slice(4);
            dao.geohash = parseInt(data.Item.inverse.slice(4));
            dao.geohash52 = data.Item.geohash;
            dao.postal_code = data.Item.payload.postal_code;
            dao.available = data.Item.payload.available;
            dao.commercial = data.Item.payload.commercial;
            dao.payload = data.Item.payload;
        } 
        return dao;
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
                            ":time": moment().unix()
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
                            ":time": moment().unix(),
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
    async retrieveSucc (body) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,      
            Key: {
                PK: "ORB#" + body.orb_uuid,
                SK: "USR#" + body.user_id
            }
        };
        const data = await docClient.get(params).promise();
        if (data.Item){
            return data.Item.payload;
        } else {
            return false;
        }
    },
};

function postal_to_geo(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo(latlon);
};

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

function latlon_to_geo(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 30);
    return geohashing;
};

function latlon_to_geo52(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 52);
    return geohashing;
}

module.exports = router;

