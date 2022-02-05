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
    if (!req.body.user_id){ // guest user firebase
      payload.device_id = req.body.device_id
      payload.username = "AttilaHun"
      payload.role = "barb"
    } else if (req.body.user_id === res.user_id && req.body.device_id) {
      var user = land.Entity();
      user.spawn("USR", req.body.user_id,"pte");
      existing_attr= await user.exist().catch(err => {
        err.status = 400;
        next(err);
      });
      if(existing_attr.Item && existing_attr.Item.identifier === req.body.device_id){
        payload.user_id = req.body.user_id;
        payload.role = "boni";
        /*
         * territory is not the most granular as this might compromise user security
         * .. without encryption for claims
         */
        if (existing_attr.Item.geohash) {
          territory = {}
          Object.entries(existing_attr.Item.geohash).forEach(([name, address]) =>{
            territory[name] = address.geohashing
          })
          payload.territory = territory
        }

        if(existing_attr.Item.alphanumeric){
          payload.username = existing_attr.Item.alphanumeric
        }
      }
      else{
        await fyr.auth()
                 .revokeRefreshTokens(res.user_id).then(() => {
                   throw new Error("Unauthorised Access");
                 })
                 .catch(err => {
                   console.log(err + " :: " + res.user_id);
                   throw new Error("Unauthorised Access");
                 });
      }}
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
    if (err.message == "Unauthorised Access") err.status = 401;
    next(err);
  }
});


router.get('/flameon', async (req, res, next) => {
  // device id addition to login path and check on uuid existence
  fyrUser = land.Entity()
  payload= await fyrUser.fyrgen(res.user_id,req.query.device_id).catch(err => {
    res.status = 400;
    next(err);
  });
  if(payload.Attributes){
    res.status(201).json({
      "Returning User": res.user_id,
      "Geolocation": payload.Attributes.geohash,
      "Last Login": payload.Attributes.time
    })
  }
  else{
    res.status(201).json({
      "Creating User": res.user_id
    })
  }
});

module.exports = router;
