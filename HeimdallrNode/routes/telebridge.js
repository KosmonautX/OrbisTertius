const express = require('express');
const router = express.Router();
const moment = require('moment');
const security = require('../controller/security');
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;
const geohash = require('../controller/geohash')
const territory_markers = [30,31,32]
const geofencer = require('ngeohash').decode

router.use(function (req, res, next){
    security.checkAdmin(req, next);
    next()
})

router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let promises = new Map();
        body.expiry_dt = slider_time(body.expires_in);
        body.created_dt = moment().unix();
        Object.entries(body.geolocation).slice(0,1).forEach(([geoName, address]) =>{
            if(address.geolock){
                body.geolocation.geolock = true
            }
            if (address.postal){ // only postal support for tele no territory check
                body.geolocation.hash = geohash.postal_to_geo(address.postal,address.target)
                body.geolocation.radius = address.target
            }
        })
        //body.geolocation.radii = territory_markers.filter(function(x){ return x>=req.geolocation.radius})
        // when listener frequencies become adaptable not now
        if(body.geolocation.radius === territory_markers[0]) body.geolocation.hashes = geoneighbour(body.geolocation.hash,body.geolocation.radius)
        else body.geolocation.hashes = [body.geolocation.hash]

        if(body.geolocation.geolock === true) body.geolocation.geofence = geofencer(body.geolocation.hash,body.geolocation.radius)
        //initators data from telegram

        body.init = {}
        body.init.username = body.username
        body.init.media = false;
        orb_uuid = await dynaOrb.create(body,dynaOrb.gen(body)).catch(err => {
            err.status = 400;
            next(err);
        });
        promises.set('orb_uuid', body.orb_uuid);
        promises.set('expiry', body.expiry_dt);
        promises.set(`creationtime`, body.created_dt)
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
    }catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});

router.put(`/destroy_orb`, async function (req, res, next) {
    try{
        let body = { ...req.body};
        const orbData = await dynaOrb.retrieve(body).catch(err => {
            err.status = 404;
            err.message = "ORB not found";
        });
        // shift to orbland security will fail (state machine capture)
        if(orbData.payload && orbData.available){
            var deactivation = await dynaOrb.destroy(orbData).catch(err => {
                err.status = 500;
                next(err);
            });
            if (deactivation) {
                res.status(201).json({
                    "Orb destroyed": body.orb_uuid
                });
            }
            else{

                res.status(400).json({
                    "Orb": "Destruction Failed"
                })
            }
        }
        else{
            res.status(404).json({
                "Orb": "already go bye bye"
            })

        }
    }catch(err) {
        next(err);
    }});

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt) {
        expiry_dt = moment().add(parseInt(dt), 'days').unix();
    }
    return expiry_dt;
}

router.get(`/decode_geohash`, async function (req, res, next) {
    try{
        let latlon = geohash.decode_hash(req.query.hash, req.query.radius);
        res.send(latlon);
    }catch{
        res.status(400).send("geohash looks sus");
    }
});
module.exports = router;
