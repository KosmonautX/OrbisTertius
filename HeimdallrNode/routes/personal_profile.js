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


/**
 * API 1 
 * Get specific user (all info) 
 */
 router.get(`/get_postal`, async function (req, res, next) {
     let pteData = await userQuery.queryPTE(req, ['numeric','geohash']).catch(err => {
        err.status = 400;
        next(err);
    });
    let dao = {};
    if (req.verification.user_id == parseInt(req.query.user_id)){
        if (pteData.Item) {
            dao.user_id = parseInt(req.query.user_id);
            dao.home = pteData.Item.numeric;
            dao.office = pteData.Item.geohash;
            res.json(dao);
        }
        else {
            res.status(404).json("User not found");
        }
    }
     else {
         res.status(403).json("Begone robber of geographies");
     }

});


const userQuery = {
    async queryPTE(req, arr) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,        
            Key: {
                PK: "USR#" + req.query.user_id,
                SK: "USR#" + req.query.user_id + "#pte"
            },
            AttributesToGet: arr
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
    async checkUsername (username) {
        const params = {
            TableName: ddb_config.tableNames.orb_table,
            Key: {
                PK: "username#" + username,
                SK: "username#" + username
            }
        };
        const data = await docClient.get(params).promise();
        return data;
    },
}


module.exports = router;
