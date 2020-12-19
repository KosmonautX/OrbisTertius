const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB();
const docClient = new AWS.DynamoDB.DocumentClient();
const ddb = require('../config/ddb.config')


// create orb in DynamoDB
exports.create = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,
        Item: {
            orb_uuid: req.body.orb_uuid,
            time_created: req.body.time_created,
            postal_code: req.body.postal_code,
            acceptor_uuid : req.body.acceptor_uuid,
            title: req.body.title,
            payload: req.body.payload,
            init_uuid: req.body.init_uuid,
            dormancy: req.body.dormancy,
            nature: req.body.nature
        },

    };
    docClient.put(params, function(err, data) {
        if (err) {
            res.status(400).send({ Error: err.message });
        } else {
            debugger;
            res.json({"Big 200 PutItem succeeded:": params.Item.orb_uuid});
        }
      });
};

// get orb from DynamoDB
exports.retrieveOrb = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,        
        Key: {
            orb_uuid: parseInt(req.query.orb_uuid),
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

// get orb from DynamoDB through secondary index (postal codes)
exports.retrieveOrbByLoc = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,
        IndexName: "orbs_in_loc",
        KeyConditionExpression: "nature = :n and postal_code = :ps",
        ExpressionAttributeValues: {
            ":ps": parseInt(req.query.postal_code),
            ":n": parseInt(req.query.nature)
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

// get orb from DynamoDB through secondary index (RANGE of postal codes)
exports.retrieveOrbByLocRange = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,
        IndexName: "orbs_in_loc",
        KeyConditionExpression: "nature = :n and postal_code BETWEEN :psDown AND :psUp",
        ExpressionAttributeValues: {
            ":psUp": parseInt(req.query.upper_code),
            ":psDown": parseInt(req.query.lower_code),
            ":n": parseInt(req.query.nature)
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

// get orb from DynamoDB through secondary index (postal codes & nature)
exports.retrieveOrbByRecency = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,
        IndexName: "orbs_recency",
        KeyConditionExpression: "nature = :n and time_created BETWEEN :time1 AND :time2",
        ExpressionAttributeValues: {
            ":n": parseInt(req.query.nature),
            ":time1": parseInt(req.query.time1),
            ":time2": parseInt(req.query.time2)
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

// get orb from DynamoDB through secondary index (postal codes & nature)
exports.retrieveOrbByName = (req, res) => {
    let params = {
        TableName: ddb.tableNames.orb_table,
        IndexName: "naming",
        KeyConditionExpression: "nature = :n and begins_with(title, :title)",
        ExpressionAttributeValues: {
            ":n": parseInt(req.query.nature),
            ":title": req.query.title
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

