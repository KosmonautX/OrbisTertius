const express = require('express');
const router = express.Router();
const land = require('../controller/graphLand').Land
const crypto = require('crypto')
const jwt = require(`jsonwebtoken`);
const buffer = require('buffer');
const moment = require('moment');
const fyr = require("firebase-admin");
const secret = process.env.SECRET_TUNNEL;

router.post('/serveronfyr' , async (req,res, next) => {
  // integrate handshake (AES128 ECDH-ES)
  // device id check and integration for exists
  try{
    let payload = {};
    if (!req.body.user_id){
            payload.device_id = req.body.device_id
            payload.username = "AttilaHun"
            payload.role = "barb"
    } else if (req.body.user_id === req.user_id && req.body.device_id) {
          var user = land.Entity;
          user.spawn("USR", req.body.user_id,"pte");
          payloadz= await user.exist().catch(err => {
            err.status = 400;
            next(err);
          });
          if(payloadz.Item){
            payload.user_id = req.body.user_id;
            payload.username = "ChongaldXrump";
            payload.role = "pleb";
          }
          else{
            res.status(401).json({
              "User": "Not Exist Yet"
            })

          }
        }
    else{
      res.status(403).json({
              "User": "Is Fyred"
            })
    }
        const iss = 'Princeton';
        const sub = 'ScratchBac';
        const exp = '20min'
        const signOptions = {
            issuer: iss,
            subject: sub,
            expiresIn: exp,
            algorithm: 'HS256',
        };
        const token = jwt.sign(payload, secret, signOptions);
        res.send({payload: token});
  }catch(err)
  {
    next(err);}
    });


router.get('/flameon', async (req, res, next) => {
  // device id addition to login path and check on uuid existence
  fyrUser = land.Entity
  payload= await fyrUser.fyrgen(req.user_id,req.query.device_id).catch(err => {
            res.status = 400;
            next(err);
        });
  if(payload.Attributes){
    res.status(201).json({
      "Returning User": req.user_id,
      "Home Postal": payload.Attributes.numeric,
      "Office Postal": payload.Attributes.geohash,
      "Last Login": payload.Attributes.time
    })
  }
  else{
    res.status(201).json({
      "Creating User": req.user_id
    })
  }
});

module.exports = router;
