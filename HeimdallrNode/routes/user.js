const express = require('express');
const router = express.Router();
const ddb_config = require('../../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region,
    endpoint: ddb_config.endpoint
})
const docClient = new AWS.DynamoDB.DocumentClient();


// const docClient = dynamodb.DocumentClient();
/**
 * API 0
 * Create user
 */
router.post(`/create`, async function (req, res, next) {
    let body = { ...req.body };
    let params = {
        TableName: ddb_config.tableNames.user_table,
        Item: {
            uuid: body.uuid,
            postal_code: body.postal_code,
            nature : body.nature,
            friends: body.friends,
            orb_uuid: body.orb_uuid
        },
    };
    docClient.put(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json({"PutItem succeeded:": params.Item.uuid});
        }
      });
});

/**
 * API 1
 * Get specific user
 */
router.get(`/get`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.user_table,
        Key: {
            uuid: req.query.uuid,
        }
    };
    docClient.get(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json(data);
        }
    });
});

/**
 * API 2
 * Get users by specific postal code
 */
router.get(`/getps`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.user_table,
        IndexName: "users_in_location",
        KeyConditionExpression: "postal_code = :ps",
        ExpressionAttributeValues: {
            ":ps": parseInt(req.query.postal_code)
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json(data);
        }
    });
});

/**
 * UNRELEASED API 
 * Get users by a range of postal code
 */
router.get(`/getRange`, async function (req, res, next) {
    let params = {
        TableName: ddb_config.tableNames.user_table,
        IndexName: "users_in_location",
        KeyConditionExpression: "is_deleted = 0 and postal_code BETWEEN :psDown AND :psUp",
        ExpressionAttributeValues: {
            ":psUp": parseInt(req.query.upper_code),
            ":psDown": parseInt(req.query.lower_code)
        }
    };
    docClient.query(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json(data);
        }
    });
});

module.exports = router;