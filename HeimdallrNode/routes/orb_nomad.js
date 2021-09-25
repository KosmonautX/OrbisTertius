const security = require('../controller/security');
const express = require('express');
const router = express.Router();
const serve3 = require ('../controller/orbjectStore').serve3
const query  = require('../controller/graphStream')
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;
const moment = require('moment')
const userQuery = require("../controller/dynamoUser").userQuery
const territory_markers = [30,42,52]
const geofencer = require('ngeohash').decode_bbox_int
const geoneighbour = require("../controller/geohash").get_geo_array

router.use(function(req,res,next){
    security.checkTerritory(req, next);
    next()
})


/**
 * API 1
 * Get specific orb (all info) by ORB:uuids
 */
router.post(`/freshorbstream`, async function (req, res, next) {
    try{
        var payload;
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
                dao.expiry_dt = item.extinguish
                dao.geolocation = item.geohash
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

/**
 * API 0.0
 * Create orb
 * No checking for empty fields yet
 * user_id = telegram_id
 */
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        let promises = new Map();
        body.expiry_dt = slider_time(body.expires_in);
        body.created_dt = moment().unix();
        body.geolocation = req.geolocation
        //body.geolocation.radii = territory_markers.filter(function(x){ return x>=req.geolocation.radius})
        // when listener frequencies become adaptable not now
        if(body.geolocation.radius === territory_markers[0]) body.geolocation.hashes = geoneighbour(body.geolocation.hash,body.geolocation.radius)
        else body.geolocation.hashes = [body.geolocation.hash]

        if(req.geolocation.geolock === true) body.geolocation.geofence = geofencer(req.geolocation.hash,req.geolocation.radius)
        //initators public data
        let pubData = await userQuery.queryPUB(req.body.user_id).catch(err => {
            err.status = 400;
            next(err);
        });
        if (pubData.Item){
            body.init = {}
            body.init.username = pubData.Item.alphanumeric
            if(pubData.Item.payload){
                if(pubData.Item.payload.media) body.init.media = true;
                if(pubData.Item.payload.profile_pic) body.init.profile_pic= pubData.Item.payload.profile_pic;
            }
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
        }

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

function slider_time(dt){
    let expiry_dt = moment().add(1, 'days').unix(); // default expire in 1 day
    if (dt) {
        expiry_dt = moment().add(parseInt(dt), 'seconds').unix();
    }
    return expiry_dt;
}


module.exports = router;
