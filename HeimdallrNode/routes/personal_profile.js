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
const serve3 = require('../controller/orbjectStore').serve3
const geohash = require('../controller/geohash');
const userQuery = require('../controller/dynamoUser').userQuery;


router.get(`/get_media`, async function (req, res, next) {
    try{
        var getUrl;
        switch (req.query.entity){
        case "ORB":
            getUrl = await serve3.preSign('getObject','ORB',req.query.uuid, req.query.form);
            res.status(201).json({
                "media": getUrl,
            });
            break;
        case "USR":
            getUrl = await serve3.preSign('getObject','USR',req.query.uuid, req.query.form);
            if(req.query.uuid == req.verification.user_id)
            {res.status(201).json({"User's own": getUrl});}
            else{
            var params = {
                TableName : ddb_config.tableNames.orb_table,
                Key: {
                    'PK': "USR#" + req.query.uuid + "#REL",
                    'SK': "BUD#" + req.verification.user_id
                }
            };
            docClient.get(params, function(err, data) {
                if (err) throw err;
                else {
                    if (data.Item){
                        res.status(201).json({"Buddy's":getUrl});
                       }
                }
            });
            }
            break;
        }

        res.status(401).json({"Begone": "Imposter"});
    } catch (err){
        next(err);
    }

});

module.exports = router;
