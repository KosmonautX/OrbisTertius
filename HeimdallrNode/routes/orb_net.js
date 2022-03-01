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
const security = require('../controller/security');
const serve3 = require ('../controller/orbjectStore').serve3
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;
const graph = require('../controller/graphLand');
const carto = require('../controller/graphCarto');
const teleria = require('../controller/teleria').teleChannelPipeline
const dynaUser = require('../controller/dynamoUser').dynaUser
const userQuery = require('../controller/dynamoUser').userQuery

router.use(function (req, res, next){
    security.checkUser(req, next);
    next()
})

// fcm token
router.put('/tokenonfyr', async (req,res,next) => {
    try{
        fyrUser = graph.Land.Entity();
        payload= await fyrUser.fcmtoken(req.body.user_id,req.body.token).catch(err => {
            res.status = 400;
            next(err);});
        if(payload.Attributes){
            res.status(201).json({
                "FCM Token": "Updated"
            })
        }}catch(err){
            next(err);
        }})

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

// user reports a orb or a user through a orb
router.post(`/report`, async function (req, res, next) {
    try {
        let clock = moment().unix()
        let body = { ...req.body };
        body.reasons = Object.keys(body.reason).filter(k => body.reason[k])

        if(body.reasons.length < 5){
            payload= await teleria(req.verification,"report", body).catch(err => {
                res.status = 400;
                next(err)
                ;});
            let params = {
                TableName: ddb_config.tableNames.orb_table,
                Item: {
                    PK: "ORB#" + body.orb_uuid,
                    SK: "RPRT#" + body.user_id,
                    inverse: moment().unix().toString(),
                    payload: body.reason,
                }
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
        }
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
    if (body.media===true){
        var img_lossy = await serve3.preSign('putObject','USR',body.user_id,'150x150');
        var img_lossless = await serve3.preSign('putObject','USR',body.user_id,'1920x1080');
    }
    let data = await dynaUser.updatePayload(body).catch(err => {
        err.status = 400;
        next(err);
    });
    if (data) {
        res.status(200).json({
            "User" : "Updated",
            "lossy": img_lossy,
            "lossless": img_lossless,
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
        // need to have mirror of username in pte for authorisation

        let pubData = await userQuery.queryPUB(body.user_id);
        if (pubData.Item) { // get old username
            body.old_username = pubData.Item.alphanumeric;
            let transac = await dynaUser.usernameTransaction(body).catch((error) =>{
                let err = new Error("Transaction failed");
                err.status = 409;
                throw err;
            })
            if (transac == true) {
                let pte_update = {
                    TableName: ddb_config.tableNames.orb_table,
                    Key: {
                        PK: "USR#" + body.user_id,
                        SK: "USR#" + body.user_id + "#pte",
                    },
                    UpdateExpression: "set alphanumeric = :username",
                    ExpressionAttributeValues: {
                        ":username": body.username,
                    }
                };

                docClient.update(pte_update, function(err, data) {
                    if (err) {
                        err.status = 400;
                        next(err);
                    } else {
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
                    }
                });

            } else {
                let err = new Error("Username taken");
                err.status = 409;
                throw err;
            }
        } else {
            // user id invalid
            let err = new Error("User_pub_id  not found");
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
 * supports postal code for now
 */
router.put(`/user_location`, async function (req, res, next) {
    try {
        switch(req.body.event){
            case "genesis":
                payload = await carto.Graph.Edge().loc_genesis(req.body.user_id, req.body).catch(err => {
                    res.status = 400;
                    next(err);});
                break;
            case "update":
                payload = await carto.Graph.Edge().loc_update(req.body.user_id, req.body).catch(err => {
                    res.status = 400;
                    next(err);});
                break;
        }
        if(payload) res.json({ "User Location Updated:": payload.Attributes.geohash});
    }catch (err) {
        err.status = 400;
        next(err)
    }});
/**
 * API 0.2
 * Accept orb
 */
router.post(`/accept`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let clock = moment().unix()

        const orbData = await dynaOrb.retrieve(body).catch(err => {
            err.status = 404;
            err.message = "ORB not found";
        });


        // shift to orbland security will fail (state machine capture)
        if(orbData.payload && orbData.available){
            if(body.user_id !== orbData.payload.user_id) {

                let params = {
                    TableName: ddb_config.tableNames.orb_table,
                    Item: {
                        PK: "ORB#" + body.orb_uuid,
                        SK: "USR#" + body.user_id.toString(),
                        inverse : "500#ACPT#" + clock,
                        alphanumeric: "USR#" +orbData.payload.user_id,
                        payload:{
                            creationtime: orbData.payload.creationtime,
                            media: orbData.payload.media,
                            title: orbData.payload.title,
                            orb_nature: orbData.payload.orb_nature
                        },
                        time: clock,
                        identifier: body.beacon
                    },
                };
                docClient.put(params, function(err, data) {
                    if (err) {
                        err.status = 400;
                        next(err);
                    } else {
                        res.status(200).json({
                            "ORB accepted by": body.user_id,
                            "orb_uuid": body.orb_uuid});
                    }
                });
            } else{
                res.status(401).json({
                    "Ownself": "Accept Ownself"
                })}

        }else{
            res.status(404).json({
                "Orb": "Not Active"
            })

        }
    } catch (err) {
        err.status = 400;
        next(err);
    }
});


/**
 * Deactivate Orbs out of location feed
 */

router.put(`/deactivate_orb`, async function (req, res, next) {
    try{
        let body = { ...req.body};
        const orbData = await dynaOrb.retrieve(body).catch(err => {
            err.status = 404;
            err.message = "ORB not found";
        });
        // shift to orbland security will fail (state machine capture)
        if(orbData.payload && orbData.active && orbData.available){
            if(req.verification.user_id === orbData.payload.user_id){
                var deactivation = await dynaOrb.deactivate(orbData).catch(err => {
                    err.status = 500;
                    next(err);
                });
            }
            if (deactivation) {
                res.status(201).json({
                    "Orb deactivated": body.orb_uuid
                });
            }
            else{

                res.status(400).json({
                    "Orb": "Deactivation Failed"
                })
            }
        }
        else{
            res.status(404).json({
                "Orb": "Not Active"
            })

        }
    }catch(err) {
        next(err);
    }});
/**
 * Destroy Orbs to unavailable
 */
router.put(`/destroy_orb`, async function (req, res, next) {
    try{
        let body = { ...req.body};
        const orbData = await dynaOrb.retrieve(body).catch(err => {
            err.status = 404;
            err.message = "ORB not found";
        });
        // shift to orbland security will fail (state machine capture)
        if(orbData.payload && orbData.available){
            if(req.verification.user_id === orbData.payload.user_id){
                var deactivation = await dynaOrb.destroy(orbData).catch(err => {
                    err.status = 500;
                    next(err);
                });
            }
            if (deactivation) {
                res.status(201).json({
                    "Orb destroyed": body.orb_uuid
                });
            }
            else{

                res.status(400).json({
                    "Orb": "Destruction Failed"
                })
            }
        }
        else{
            res.status(404).json({
                "Orb": "already go bye bye"
            })

        }
    }catch(err) {
        next(err);
    }});

module.exports = router;
