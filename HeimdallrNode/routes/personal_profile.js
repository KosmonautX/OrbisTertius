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
 router.get(`/get_user`, async function (req, res, next) {
    let pteData = await userQuery.queryPTE(req).catch(err => {
        err.status = 400;
        next(err);
    });
    let pubData = await userQuery.queryPUB(req).catch(err => {
        err.status = 400;
        next(err);
    });
    let dao = {};
    if ( (process.env.NODE_ENV == 'dev') || (req.verification.user_id == parseInt(req.query.user_id))){
        if (pteData.Item && pubData.Item) {
            if (pubData.Item.payload) {
                dao.bio = pubData.Item.payload.bio;
                dao.profile_pic = pubData.Item.payload.profile_pic;
                dao.verified = pubData.Item.payload.verified;
                dao.country_code = pteData.Item.payload.country_code;
            }
            if (pteData.Item.payload){
                dao.gender = pteData.Item.payload.gender;
                dao.birthday = pteData.Item.payload.birthday;
            }
            dao.user_id = parseInt(req.query.user_id);
            dao.username = pubData.Item.alphanumeric;
            dao.hp_number = 98754321;
            dao.home = pteData.Item.numeric;
            dao.office = pteData.Item.geohash;
            dao.home_geohash = pubData.Item.numeric;
            dao.office_geohash = pubData.Item.geohash;
            // dao.home_geohash52 = pubData.Item.numeric2;
            // dao.office_geohash52 = pubData.Item.geohash2;
            dao.join_dt = pteData.Item.join_dt;
            res.json(dao);
        }
        else {
            res.status(404).json("User not found");
        }
    }
    else if(req.verification.user_id != req.query.user_id){
        if(pubData.Item){
            if (pubData.Item.payload) {
                dao.bio = pubData.Item.payload.bio;
                dao.profile_pic = pubData.Item.payload.profile_pic;
                dao.verified = pubData.Item.payload.verified;
                dao.country_code = pteData.Item.payload.country_code;
            }
            dao.user_id = parseInt(req.query.user_id);
            dao.username = pubData.Item.alphanumeric;
            dao.home_geohash = pubData.Item.numeric;
            dao.office_geohash = pubData.Item.geohash;
        }
        else {
            res.status(404).json("User not found");
        }
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