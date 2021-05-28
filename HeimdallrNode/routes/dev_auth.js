const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const land = require('../controller/graphspace').Land
const crypto = require('crypto')
const jwt = require(`jsonwebtoken`);

router.get('/tele', async (req, res, next) =>
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
          var user = land.Entity;
          user.claim("USR", req.query.id,"pte");
          payload= await user.upsert().catch(err => {
            err.status = 400;
            next(err);
          });
          if(payload.Attributes){
          res.status(201).json({
            "Returning User": req.query.id,
            "Home Postal": payload.Attributes.numeric,
            "Office Postal": payload.Attributes.geohash,
            "Last Login": payload.Attributes.time
          })
          }
          else{
            res.status(201).json({
            "Creating User": req.query.id
          })
          }
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

router.get('/handshake',(req, res ,next ) =>
  {
    try{



    }catch(err){
      next(err);
    }


  }
          );

router.post('/server' , async (req,res, next) => {
  // integrate handshake (AES128 ECDH-ES)
  // device id check and integration for exists
  try{
    let payload = {};
    const secret = process.env.SECRET_TUNNEL;
    if (req.body.device_id){
            payload.device_id = req.body.device_id
            payload.username = "AttilaHun"
            payload.role = "barb"
        } else if (req.body.user_id) {
          var user = land.Entity;
          user.claim("USR", req.body.user_id,"pte");
          payload= await user.exists().catch(err => {
            err.status = 400;
            next(err);
          });
          if(payload.Item){
            payload.user_id = req.body.user_id;
            payload.username = "ChongaldXrump";
            payload.role = "pleb";
          }
          else{
            throw new Error("User does not Exist")
          }
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

module.exports = router;
