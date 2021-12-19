const express = require('express');
const router = express.Router();
const checkTeleService = require('../controller/security').checkAdmin
const userQuery= require('../controller/dynamoUser').userQuery;
const moment = require('moment');
const dynaOrb= require('../controller/dynamoOrb').dynaOrb;
const land = require('../controller/graphLand').Land
const geohash = require('../controller/geohash')
const serve3 = require('../controller/orbjectStore').serve3


router.use(function (req, res, next){
  checkTeleService(req, next);
  next()
})

router.post(`/gen_orb`, async function (req, res, next) {
  try {
    let body = { ...req.body };
    let promises = new Map();
    body.expiry_dt = slider_time(body.expires_in);
    body.created_dt = moment().unix();
    if(!body.geohashing || !body.geohashing52){
      if (body.latlon) {
        body.geohashing = geohash.latlon_to_geo(body.latlon);
        body.geohashing52 = geohash.latlon_to_geo52(body.latlon);
      } else if (body.postal_code) {
        body.geohashing = geohash.postal_to_geo(body.postal_code);
        body.geohashing52 = geohash.postal_to_geo52(body.postal_code);
      }};
    //initators public data
    let pubData = await userQuery.queryPUB(req.body).catch(err => {
      err.status = 400;
      next(err);
    });
    if (pubData.Item){
      body.init = {}
      body.init.username = pubData.Item.alphanumeric
      if(pubData.Item.payload){
        if(pubData.Item.payload.media) body.init.media = true;
        if(pubData.Item.payload.profile_pic)body.init.profile_pic= pubData.Item.payload.profile_pic;
      }
    }
    orb_uuid = await dynaOrb.create(body,dynaOrb.gen(body)).catch(err => {
      err.status = 400;
      next(err);
    });
    promises.set('orb_uuid', body.orb_uuid);
    if (body.media){
      promises.set('lossy', await serve3.preSign('putObject','ORB',body.orb_uuid,'150x150'));
      promises.set('lossless', await serve3.preSign('putObject','ORB',body.orb_uuid,'1920x1080'));
    };
    Promise.all(promises).then(response => {
      //m = new Map(response.map(obj => [obj[0], obj[1]])) jsonObject[key] = value
      let jsonObject = {};
      response.map(obj => [jsonObject[obj[0]] = obj[1]])
      res.status(201).json(jsonObject);
    });
  } catch (err) {
    if (err.message == 'Postal code does not exist!') err.status = 404;
    next(err);
  }
});

router.post(`/gen_user`, async function (req, res, next) {
  try {
    user = land.Entity();
    payload = await user.telegen(req.body.user_id, req.body.username).catch(err => {
    res.status = 400;
    next(err);
  });
    if(payload.Attributes){
    res.status(201).json({
      "Updating User": req.body.user_id
        });
    }
    else{
      res.status(201).json({
      "Creating User": req.body.user_id
        });
    }

  } catch (err) {
    if (err.message == 'Postal code does not exist!') err.status = 404;
    next(err);
  }
});

router.post('/control_media', async function(req, res, next) {

  getUrl = await serve3.preSign('getObject','ORB',req.body.uuid, "1920x1080");
            res.status(201).json({
                "media_asset": getUrl,
            });

})

router.put(`/delete_orb`, async function (req, res, next) {
  try{
    let body = { ...req.body};
    const orbData = await dynaOrb.retrieve(body).catch(err => {
      err.status = 404;
      err.message = "ORB not found";
    });
    // shift to orbland security will fail (state machine capture)
    if(orbData.payload){
      if(req.body.user_id === orbData.payload.user_id){
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        // body.payload = orbData.payload;
        deletion = await dynaOrb.deactivate(body).catch(err => {
          err.status = 500;
          next(err);
        });
      }
      if (deletion == true) {
        res.status(201).json({
          "Orb deleted": body.orb_uuid
        });
      }
    }
    else{
      res.status(404).json({
        "Orb": "Not Found"
      })

    }
  }catch(err) {
    next(err);
  }});

function slider_time(dt){
  let expiry_dt = moment().add(7, 'days').unix(); // default expire in 1 day
  if (dt) {
    expiry_dt = moment().add(parseInt(dt), 'days').unix();
  }
  return expiry_dt;
}
module.exports = router;
