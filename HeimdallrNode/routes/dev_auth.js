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
const userQuery = require('../controller/dynamoUser').userQuery
const crypto = require('crypto')

router.get('/tele', (req, res, next) =>
    {
      try{
        const bot_token = process.env.NEIB
        const secretKey = crypto.createHash('sha256')
                                .update(bot_token)
                                .digest();
        
        //data to be authenticated i.e. telegram user id, first_name, last_name etc.
        const dataCheckString = Object.keys(req.query)
                                      .filter((key) => key!=="hash")
                                      .sort()
                                      .map(key => (`${key}=${req.query[key]}`))
                                      .join('\n');
        
        // run a cryptographic hash function over the data to be authenticated and the secret
        const hmac = crypto.createHmac('sha256', secretKey)
              .update(dataCheckString)
              .digest('hex');
        
        if (hmac === req.query.hash){
            //check if existing user pass back postal code else create
          res.status(201).json({
            "Creating User": req.query.id
          })
        }
        else{
          let err = new Error("Corrupted Authentication");
          err.status = 401
          throw err;
        }

      }
      catch (err) {
        next(err);
    }}
)

module.exports = router;
