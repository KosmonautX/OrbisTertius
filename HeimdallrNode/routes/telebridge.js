const express = require('express');
const router = express.Router();
const moment = require('moment');
const security = require('../controller/security');
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;
const geohash = require('../controller/geohash')
const { territory_markers } = require('../config/ddb.config');
const serve3 = require('../controller/orbjectStore').serve3

router.use(function (req, res, next){
    security.checkAdmin(req, next);
    next()
})

router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        promises = []
        let delivered
        for(var element in body ) promises.push(gen_orb(body[element]))
        await Promise.all(promises).then(response => {
            delivered = response
        });
        res.status(201).json(delivered)
    }catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});


async function gen_orb(body){
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
        if (address.latlon){ // only postal support for tele no territory check
            body.geolocation.hash = geohash.latlon_to_geo(address.latlon ,address.target)
            body.geolocation.radius = address.target
        }
    })
    //body.geolocation.radii = territory_markers.filter(function(x){ return x>=req.geolocation.radius})
    // when listener frequencies become adaptable not now
    if(body.geolocation.radius === territory_markers[0]) body.geolocation.hashes = geohash.neighbour(body.geolocation.hash,body.geolocation.radius)
    else body.geolocation.hashes = [body.geolocation.hash]
    //initators data from telegram

    body.init = {}
    body.init.username = body.username
    body.init.media = false;
    orb_uuid = await dynaOrb.create(body,dynaOrb.gen(body)).catch(err => {
        err.status = 400;
        next(err);
    });
    promises.title = body.title
    promises.orb_uuid =  body.orb_uuid;
    promises.expiry = body.expiry_dt;
    promises.creationtime = body.created_dt
    if (body.media){
        promises.lossy = await serve3.preSign('putObject','ORB',body.orb_uuid,'150x150')
        promises.lossless = await serve3.preSign('putObject','ORB',body.orb_uuid,'1920x1080');
    };
    return promises
}

router.post(`/freshorbstream`, async function (req, res, next) {
    try{
        var payload;
        let now = moment().unix()
        if(req.body.downstream){
            payload = await query.Stream.Channel().downstream("LOC", req.geolocation.hash, req.geolocation.radius,req.body.downstream).catch(err => {
                res.status = 400;
                next(err);
            });
        }
        else if(req.body.upstream){
            payload = await query.Stream.Channel().upstream("LOC", req.geolocation.hash, req.geolocation.radius,req.body.upstream).catch(err => {
                res.status = 400;
                next(err);
            });
        }
        else{
            payload = await query.Stream.Channel().start("LOC", req.geolocation.hash, req.geolocation.radius).catch(err => {
                res.status = 400;
                next(err);
            });
        }
        if(payload.Items){
            let page = [];
            for( let item of payload.Items){
                let dao = {};
                dao.orb_uuid = item.SK.slice(15);
                dao.expiry_dt = item.time
                dao.active = item.time > now
                dao.geolocation = item.geohash
                dao.available = item.available
                if (item.payload){
                    dao.payload = item.payload
                    if(item.payload.media) dao.payload.media_asset = await serve3.preSign('getObject','ORB',dao.orb_uuid,'150x150')
                    if(item.payload.init){
                        dao.payload.init = item.payload.init;
                        if(item.payload.init.media) dao.payload.init.media_asset = await serve3.preSign('getObject','USR',item.payload.user_id,'150x150')}
                }
                page.push(dao);
            }
            if (page.length > 0) {
                res.json(page)
            } else {
                res.status(204).json("nothing burger")
            }
        }
    }catch(err){
        next(err);}
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
        expiry_dt = moment().add(parseInt(dt), 'seconds').unix();
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
