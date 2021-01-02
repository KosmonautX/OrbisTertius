const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment')
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region,
    endpoint: ddb_config.endpoint
})
const ddb = new AWS.DynamoDB({ endpoint: new AWS.Endpoint(ddb_config.endpoint) }); 
const ddbGeo = require('dynamodb-geo');
const config = new ddbGeo.GeoDataManagerConfiguration(ddb, 'MyGeoTable');
const docClient = new AWS.DynamoDB.DocumentClient();

config.longitudeFirst = true;
const myGeoTableManager = new ddbGeo.GeoDataManager(config);
config.hashKeyLength = 7;




module.exports = router;