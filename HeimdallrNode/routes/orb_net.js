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
const geohash = require('../controller/geohash');
const teleMessaging = require('../controller/teleAngareion');
const security = require('../controller/security');
const serve3 = require ('../controller/orbjectStore').serve3
const orbSpace = require('../controller/dynamoOrb').orbSpace;
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;
const dynaUser = require('../controller/dynamoUser').dynaUser;
const userQuery = require('../controller/dynamoUser').userQuery;
const graph = require('../controller/graphLand');
const dynamoOrb = require('../controller/dynamoOrb');
const carto = require('../controller/graphCarto');
router.use(function (req, res, next){
    security.checkUser(req, next);
    next()
}
          )
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
// generate uuid and a presigned buffer for image in s3 bucket
router.post(`/gen_uuid`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let promises = new Map();
        orb_uuid = await dynaOrb.gen(body);
        promises.set('orb_uuid', orb_uuid);
        if (body.media){
            promises.set('lossy', await serve3.preSign('putObject','ORB',orb_uuid,'150x150'));
            promises.set('lossless', await serve3.preSign('putObject','ORB',orb_uuid,'1920x1080'));
        };
        Promise.all(promises).then(response => {
            //m = new Map(response.map(obj => [obj[0], obj[1]])) jsonObject[key] = value
            let jsonObject = {};
            response.map(obj => [jsonObject[obj[0]] = obj[1]])
            res.status(201).json(jsonObject);
        });
        
    } catch (err) {
        next(err);
    }
});

/**
 * API 0.0
 * Create orb
 * No checking for empty fields yet
 * user_id = telegram_id
 */
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let promises = new Map();
        body.expiry_dt = slider_time(body.expires_in);
        body.created_dt = moment().unix();
        if(!body.geohashing || !body.geohashing52){
        if (body.latlon) {
            body.geohashing = geohash.latlon_to_geo(body.latlon); 
            body.geohashing52 = geohash.latlon_to_geo52(body.latlon); 
        } else if (body.postal_code) {
            body.geohashing = geohash.postal_to_geo(body.postal_code);
            body.geohashing52 = geohash.postal_to_geo52(body.postal_code);
        } else{
            throw new Error('Postal code does not exist!')
        }
        };
        //initators public data
        let pubData = await userQuery.queryPUB(req.body.user_id).catch(err => {
            err.status = 400;
            next(err);
        });
        if (pubData.Item){
            body.init = {}
            body.init.username = pubData.Item.alphanumeric
            if(pubData.Item.payload){
            if(pubData.Item.payload.media) body.init.media = true;
                if(pubData.Item.payload.profile_pic)body.init.profile_pic= pubData.Item.payload.profile_pic;
            }
            orb_uuid = await dynaOrb.create(body,dynaOrb.gen(body)).catch(err => {
            err.status = 400;
            next(err);
        });
        promises.set('orb_uuid', body.orb_uuid);
        promises.set('expiry', body.expiry_dt);
        if (body.media){
            promises.set('lossy', await serve3.preSign('putObject','ORB',body.orb_uuid,'150x150'));
            promises.set('lossless', await serve3.preSign('putObject','ORB',body.orb_uuid,'1920x1080'));
        };
        }

        Promise.all(promises).then(response => {
            //m = new Map(response.map(obj => [obj[0], obj[1]])) jsonObject[key] = value
            let jsonObject = {};
            response.map(obj => [jsonObject[obj[0]] = obj[1]])
            res.status(201).json(jsonObject);
        });
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt) {
        expiry_dt = moment().add(parseInt(dt), 'days').unix();
    }
    return expiry_dt;
}

// upload profile pic, not sure if it works, bala made it
router.post(`/upload_profile_pic`, async function (req, res, next) {
    try {
        let body = { ...req.body };

        if (body.media===true){
            var img_lossy = await serve3.preSign('putObject','USR',body.user_id,'150x150');
            var img_lossless = await serve3.preSign('putObject','USR',body.user_id,'1920x1080');
            res.status(200).json({
                "lossy": img_lossy,
                "lossless": img_lossless,
            });
        } else {
            res.status(400).json({
                "Error": "No media"
            });
        }
    } catch (err) {
        next(err);
    }
});

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

// user reports a post 
router.post(`/report`, async function (req, res, next) {
    try {
        let clock = moment().unix()
        let body = { ...req.body };
        const bullied = await dynaUser.bully(body.acpt_id,body.user_id,clock).catch(err=> {
            err.status = 400;
            next(err);
        })
        const bullyd = await dynaUser.bully(body.user_id,body.acpt_id,clock).catch(err=> {
            err.status = 400;
            next(err);
        })
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

        let pubData = await userQuery.queryPUB(body.user_id);
        if (pubData.Item) { // get old username
            body.old_username = pubData.Item.alphanumeric;
            let transac = await dynaUser.usernameTransaction(body);
            if (transac == true) {
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
            } else {
                let err = new Error("Username taken");
                err.status = 409;
                throw err;
            }
        } else {
            // user id invalid
            let err = new Error("User_id not found");
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
                teleMessaging.exchangeContact(body.init_id,body.user_id,body.username,body.title).then(
                    function(value){
                        res.status(200).json({
                            "ORB accepted by": body.user_id,
                            "orb_uuid": body.orb_uuid
                    });
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
 * Chat with user on telegram
 */
 router.post(`/chatWithTelegram`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        teleMessaging.exchangeContact(body.init_id,body.user_id,body.username,body.title).then(
            function(value){
                res.status(200).json({
                    "User_id": body.user_id,
                    "Chatting with this init_id": body.init_id
            });
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

        await orbSpace.deleteAcceptance(body);
        res.status(200).json({
            "ORB interaction removed": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        next(err);
    }
});

/**
 * API 
 * 
 */
router.put(`/not_interested`, async function (req, res, next) {
    try {
        let body = { ...req.body };

        await orbSpace.notInterested_i(body);
        res.status(200).json({
            "ORB not interested": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 
 * 
 */
router.put(`/not_interested_acceptor`, async function (req, res, next) {
    try {
        let body = { ...req.body };

        await orbSpace.notInterested_a(body);
        res.status(200).json({
            "ORB not interested": body.orb_uuid,
            "user_id": body.user_id
        });
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

/**
 * API 1.2
 * Complete orb handshake (for an acceptor)
 */
router.put(`/complete_orb_acceptor`, async function (req, res, next) {
    let body = { ...req.body };
    // from user_id to accept_id security middleware shift
    let clock = moment().unix();
    const accepted = await dynaOrb.acceptance(body).catch(err => {
            err.status = 400;
            next(err);
    })
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

/*
 * Completing accept cycle through dictatorial means
 */
router.put(`/complete_orb_dictator`, async function (req, res, next) {
    let body = { ...req.body };
    // from user_id to accept_id security middleware shift
    let clock = moment().unix();
    const accepted = await dynaOrb.forceaccept(body).catch(err => {
            err.status = 400;
            next(err);
    })
    const buddied = await dynaUser.buddy(body.acpt_id,body.user_id,clock).catch(err=> {
        err.status = 400;
        next(err);
    })
    const buddys = await dynaUser.buddy(body.user_id,body.acpt_id,clock).catch(err=> {
        err.status = 400;
        next(err);
    })
    if (accepted && buddied && buddys) {
            res.status(200).json({
                "ORB completed for Acceptor": body.orb_uuid,
                "user_id": body.acpt_id
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
    try{
        let body = { ...req.body};
        const orbData = await dynaOrb.retrieve(body).catch(err => {
            err.status = 404;
            err.message = "ORB not found";
        });
        // shift to orbland security will fail (state machine capture)
        if(orbData.payload){
            if(req.verification.user_id === orbData.payload.user_id){
                body.expiry_dt = orbData.expiry_dt;
                body.geohash = orbData.geohash;
                body.payload = orbData.payload;
                body.payload.available = false;
                var deletion = await dynaOrb.delete(body).catch(err => {
                    err.status = 500;
                    next(err);
                });
            }
            if (deletion == true) {
                res.status(201).json({
                    "Orb deleted": body.orb_uuid
                });
            }
        }
        else{
            res.status(404).json({
                "Orb": "Not Found"
            })

        }
    }catch(err) {
        next(err);
    }});

module.exports = router;
