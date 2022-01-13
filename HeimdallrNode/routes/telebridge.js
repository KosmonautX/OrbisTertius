const express = require('express');
const router = express.Router();
const moment = require('moment');
const security = require('../controller/security');
const dynaOrb = require('../controller/dynamoOrb').dynaOrb;

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
        if(!body.geohashing || !body.geohashing52){
            if (body.latlon) {
                body.geohashing = geohash.latlon_to_geo(body.latlon);
                body.geohashing52 = geohash.latlon_to_geo52(body.latlon);
            } else if (body.postal_code) {
                body.geohashing = geohash.postal_to_geo(body.postal_code);
                body.geohashing52 = geohash.postal_to_geo52(body.postal_code);
            } else{
                throw new Error('Postal code does not exist!')
            }
        };
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
                if(pubData.Item.payload.profile_pic)body.init.profile_pic= pubData.Item.payload.profile_pic;
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

module.exports = router;
