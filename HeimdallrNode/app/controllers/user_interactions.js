const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB();
const docClient = new AWS.DynamoDB.DocumentClient();
const ddb = require('../config/ddb.config')

// create user in DynamoDB
exports.create = (req, res) => {
    let params = {
        TableName: ddb.tableNames.user_table,
        Item: {
            uuid: req.body.uuid,
            postal_code: req.body.postal_code,
            nature : req.body.nature,
            friends: req.body.friends,
            orb_uuid: req.body.orb_uuid
        },
    };
    docClient.put(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            res.json({"PutItem succeeded:": params.Item.uuid});
        }
      });
};

// get user from DynamoDB
exports.retrieveUser = (req, res) => {
    let params = {
        TableName: ddb.tableNames.user_table,
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
};

// get user from DynamoDB through secondary index (postal codes)
exports.retrieveUserByPS = (req, res) => {
    let params = {
        TableName: ddb.tableNames.user_table,
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
};