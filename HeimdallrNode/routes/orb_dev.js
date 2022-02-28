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
const jwt = require(`jsonwebtoken`);
const crypto = require('crypto');
const hash = crypto.createHash('sha256');
const admin = require('firebase-admin')
const axios = require('axios')
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
 * FYR TOKEN CUSTOM GEN
 */

router.get(`/fyr`, async function (req, res, next) {
    token = admin.auth().createCustomToken(req.query.id)
                 .then((customToken) => {
                     const url = `https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyCustomToken?key=${process.env.LOCAL_FYR}`;
                     const data = {
                         token: customToken,
                         returnSecureToken: true
                     };
                     const configs={"Content-Type": "application/json"}
                     axios.post(url, data, configs).then(response => {
                         res.status(201).json({
                             "payload": response.data.idToken
                         })})
                          .catch(error => {
                              console.log(error);
                              error = new Error("SMS Gateway Failed");
                              error.status = 500;
                              next(error);
                          });;
                 })
                 .catch((error) => {
                     console.log('Error creating custom token:', error);
                 });
});


/**
 * API 1.2 UNRELEASED
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
 * API 1.3 DEV
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
            let dao = [];
            data.Items.forEach(function(item) {
                dao.push(item)
            })
            res.json(dao)
        }
    });
});

/**
 * DELETE
 * Delete user
 */
router.delete(`/delete_user`, async function (req, res, next) {
    let param1 = {
        DeleteRequest: {
            Key : {
                PK: "USR#" + req.query.user_id,
                SK: "USR#" + req.query.user_id + "#pte", 
            }
        }
    };
    let param2 = {
        DeleteRequest: {
            Key : {
                PK: "USR#" + req.query.user_id,
                SK: "USR#" + req.query.user_id + "#pub", 
            }
        }
    };
    let param3 = {
        DeleteRequest: {
            Key : {
                PK: "username#" + req.username,
                SK: "username" + req.username
            }
        }
    }
    let itemsArray = [];
    itemsArray.push(param1);
    itemsArray.push(param2);
    itemsArray.push(param3);
    let params = {
        RequestItems: {
            [ddb_config.tableNames.orb_table]: itemsArray
        }
    }
    docClient.batchWrite(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json(data)
        }
    });
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
            let transac = await dynaUser.usernameTransaction(body);
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
            let err = new Error("User_id not found");
            err.status = 404;
            throw err;
        }

    } catch (err) {
        next(err);
    }
});


router.get(`/decode_geohash`, async function (req, res, next) {
    if (req.query.geohash.length == 16) {
        let latlon = geohash.decode_int(req.query.geohash, 52);
        res.send(latlon);
    } else if (req.query.geohash.length == 9) {
        let latlon = geohash.decode_int(req.query.geohash, 30);
        res.send(latlon);
    } else {
        res.status(400).send("geohash looks sus");
    }
});

router.get('/hash', async function (req, res, next) {
    let pw = encrypt("93999");
    let decry = decrypt(pw)
    console.log(pw)
    console.log(decry)
});

const algorithm = 'aes-256-ctr';
const ENCRYPTION_KEY = 'USR#1234'; // or generate sample key Buffer.from('FoCKvdLslUuB4y3EZlKate7XGottHski1LmyqJHvUhs=', 'base64');
const IV_LENGTH = 16;

function encrypt(text) {
    let iv = crypto.randomBytes(IV_LENGTH);
    let cipher = crypto.createCipheriv(algorithm, Buffer.concat([Buffer.from(ENCRYPTION_KEY), Buffer.alloc(32)], 32), iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

function decrypt(text) {
    let textParts = text.split(':');
    let iv = Buffer.from(textParts.shift(), 'hex');
    let encryptedText = Buffer.from(textParts.join(':'), 'hex');
    let decipher = crypto.createDecipheriv(algorithm, Buffer.concat([Buffer.from(ENCRYPTION_KEY), Buffer.alloc(32)], 32), iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

module.exports = router;
