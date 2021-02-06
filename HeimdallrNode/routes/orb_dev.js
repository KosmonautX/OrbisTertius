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
const jwt = require(`jsonwebtoken`);
const secret = require('../resources/global').SECRET;
const crypto = require('crypto');
const hash = crypto.createHash('sha256');
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
                SK: "USR#" + req.query.user_id, 
            }
        }
    };
    let param2 = {
        DeleteRequest: {
            Key : {
                PK: "phone#" + req.query.country_code + req.query.hp_number,
                SK: "phone#" + req.query.country_code + req.query.hp_number,
            }
        }
    }
    let itemsArray = [];
    itemsArray.push(param1);
    itemsArray.push(param2);
    let params = {
        RequestItems: {
            "ORB_NET": itemsArray
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
 * DELETE
 * Delete orb
 */
router.delete(`/delete_orb`, async function (req, res, next) {
    let param1 = {
        DeleteRequest: {
            Key : {
                PK: "ORB#" + req.query.orb_uuid,
                SK: "ORB#" + req.query.orb_uuid, 
            }
        }
    };
    let param2 = {
        DeleteRequest: {
            Key : {
                PK: "ORB#" + req.query.orb_uuid,
                SK: "USR#" + req.query.user_id, 
            }
        }
    };
    let param3 = {
        DeleteRequest: {
            Key: {
                PK: "LOC#" + body.geohash,
                SK: body.expiry_dt + "#ORB#" + body.orb_uuid
            }
        }
    }
    let itemsArray = [];
    itemsArray.push(param1);
    itemsArray.push(param2);
    itemsArray.push(param3);
    let params = {
        RequestItems: {
            "ORB_NET": itemsArray
        }
    }
    docClient.batchWrite(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.status(200).json("Orb deleted")
        }
    });
});

router.post('/login', async function (req, res, next) {
    let body = { ...req.body };
    try {
        if (body.login == "login") {
            // if (body.password !== result.password) {
            //     if (!passwordHash.verify(body.password, result.password)) {
            //         let error = new Error(`Invalid password.`);
            //         error.status = 401;
            //         throw error;
            //     }
            // };
            // delete result.password;
        
            // NEW AUTHENTICATION
            let payload = { };
            payload.user_id = "007";
            payload.name = "login boi";
            payload.role = "normie";

            const iss = "Princeton";
            const sub = "ScratchBac";
            // const aud = "";
            const exp = moment().add(20, "minute").unix();
            const signOptions = {
                issuer:  iss,
                subject:  sub,
                // audience:  aud,
                expiresIn: exp,
                algorithm: "HS256"
            };
            // Create the JWT Token
            const token = jwt.sign(payload, secret, signOptions);

            res.json({
                "token" : token
            });
        
        } else {
            let error = new Error(`User does not exist.`);
            error.status = 401;
            throw error;
        }

    } catch (err) {
        next(err);
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

module.exports = router;
