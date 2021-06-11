const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const land = require('../controller/graphLand').Land
const crypto = require('crypto')
const jwt = require(`jsonwebtoken`);
const buffer = require('buffer');
const moment = require('moment');
let mail = require('../controller/mailAngareion').Angareion.Mail
const algorithm = 'aes-256-ctr';
const ENCRYPTION_KEY = process.env.SECRET_TUNNEL;
const IV_LENGTH = 16;

router.get('/tele', async (req, res, next) =>
    {
      try{
        // moment.unix check with auth_date parameter +5mins
        if(req.query.auth_date> moment().subtract(600, 'seconds').unix()){
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
        else if (req.query.auth_date <= moment().subtract(600, 'seconds').unix()) {
          let err = new Error("Expired Authentication")
          err.status = 401
          throw err;
        }
      }
      catch (err) {
        next(err);
    }}
)

router.get('/mailin', async (req, res ,next ) =>
  {
    try {
		const iss = "ppmail";
		const sub = "sb";
		const exp = "10min";
		const verifyOptions = {
			issuer : iss,
			subject : sub,
			maxAge : exp,
			algorithms : ["HS256"]
		};
      if (req.query.hash) {
			  req.verification = jwt.verify(req.query.hash, secret, verifyOptions);
        req.query.id = decrypt(req.verification).split('#')[0]
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

		} else {
			let err = new Error(`No token, please login again!`);
			err.status = 401;
			next(err);
		}
    } catch (err) {
		if (err.message == "maxAge exceeded") err.status = 403;
        if (err.message == "jwt expired") err.status = 403;
      	next(err);
    }

  }
          );

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
    if (!req.body.user_id){
            payload.device_id = req.body.device_id
            payload.username = "AttilaHun"
            payload.role = "barb"
    } else if (req.body.user_id && req.body.device_id) {
          var user = land.Entity;
          user.claim("USR", req.body.user_id,"pte");
          payload= await user.exist().catch(err => {
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



router.post('/mail', async (req, res, next) => {
  var encrypted;
  var signup = true
  let message = {}
  let user_id = uuidv4();
  let nonce = '#' + crypto.randomBytes(16).toString('base64')
  // device id addition to login path and check on uuid existence
  let payload = land.Entity.affirm("MSG", req.body.mail,user_id )
  payload.then(response => {
  if(payload.Attributes){
    user_id = payload.Attributes.alphanumeric
    signup = false
  }})
  .catch(error => {
    console.log(error);
  })
  message.hash = encrypt(user_id + nonce)
  const iss = 'ppmail';
        const sub = 'sb';
        const exp = '10min'
        const signOptions = {
            issuer: iss,
            subject: sub,
            expiresIn: exp,
            algorithm: 'HS256',
        };
  const token = jwt.sign(message, ENCRYPTION_KEY, signOptions);
  let redirect = "https://i.scratchbac.org/?hash="+ token +"&id=" + signup
  let sent  = mail.signup(req.body, redirect)
    sent.then(response => {
      res.status(201).json({
        "Await": redirect
      })})
  .catch(error => {
    console.log(error);
    error = new Error("Email Failed");
      error.status = 500;
      next(error);
  });
           
} );


function encrypt(text) {
    let iv = crypto.randomBytes(IV_LENGTH);
    let cipher = crypto.createCipheriv(algorithm, Buffer.concat([Buffer.from(ENCRYPTION_KEY), Buffer.alloc(32)], 32), iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

function decrypt(text) {
    let textParts = text.split(':');
    let iv = Buffer.from(textParts.shift(), 'hex');
    let encryptedText = Buffer.from(textParts.join(':'), 'hex');
    let decipher = crypto.createDecipheriv(algorithm, Buffer.concat([Buffer.from(ENCRYPTION_KEY), Buffer.alloc(32)], 32), iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

module.exports = router;
