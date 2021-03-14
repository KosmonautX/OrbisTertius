const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment');
const geohash = require('../controller/geohash');
const dynaUser = require('../controller/telegramUser').dynaUser;
const dynaOrb = require('../controller/telegramUser').dynaOrb;
const checkAvailable = require('../controller/telegramUser').checkAvailable;

// body: first, second, username, gender, age
router.post(`/setup`, async function (req, res, next) {
    let body = { ...req.body };
    // body.orb_uuid = uuidv4();
    body.join_dt = moment().unix();
    try {
        body.geohashing = {
            first: null,
            second: null
        };
        body.geohashing52 = {
            first: null,
            second: null
        };
        if (body.first && body.second) {
            body.geohashing = {
                first: geohash.postal_to_geo(body.first),
                second: geohash.postal_to_geo(body.second)
            };
            body.geohashing52 = {
                first: geohash.postal_to_geo52(body.first),
                second: geohash.postal_to_geo52(body.second)
            };
        } else if (body.first) {
            body.geohashing.first = geohash.postal_to_geo(body.first);          
            body.geohashing52.first = geohash.postal_to_geo52(body.first);
        }
        let success = await dynaUser.Tcreate(body).catch(err => {
            res.status(400).json(err.message);
        })
        if (success == true) {
            await dynaUser.Bcreate(body);
            if (body.second) await dynaUser.putSecondLocation(body);
            res.status(201).json({
                "User created": body.user_id,
            });
        }
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});

// returns commercial, first, second, no. of users (count)
router.get(`/start`, async function (req, res, next) {
    try {
        await checkAvailable(req.query);
        let pteData = await dynaUser.getPTEinfo(req.query);
        let pubData = await dynaUser.getPUBinfo(req.query);
        if (pteData.Item && pubData.Item) {
            let homeUser = await dynaUser.getAllUsers(pubData.Item.numeric).catch(err => {
                err.status = 500;
                throw err;
            })
            let officeUser = await dynaUser.getAllUsers(pubData.Item.geohash).catch(err => {
                err.status = 500;
                throw err;
            })
            let checkGender = true;
            let checkAge = true;
            if (pteData.Item.payload.gender == null) checkGender = false;
            if (pteData.Item.payload.age == null) checkAge = false;
            if (pteData.Item.numeric == null) homeUser.Count = null;
            if (pteData.Item.geohash == null) officeUser.Count = null;
            
            res.status(200).send({
                "commercial": pubData.Item.payload.commercial,
                "first": pteData.Item.numeric,
                "second": pteData.Item.geohash,
                "firstGeo": pubData.Item.numeric,
                "secondGeo": pubData.Item.geohash,
                "homeCount": homeUser.Count,
                "officeCount": officeUser.Count,
                "gender": checkGender,
                "age": checkAge,
                "star": pubData.Item.payload.star,
            })
        } else {
            res.status(404).json("User not found")
        }
    } catch (err) {
        next(err)
    }
});

// receive user id, commercial?, first | second location
// returns list of users
router.get(`/recipients`, async function (req, res, next) {
    try {
        const geohashing = geohash.postal_to_geo(req.query.postal_code);
        let blockedList = await dynaUser.getBlockedList(req.query);
        let blockedUsers = [];
        if (blockedList.Count != 0) {
            blockedList.Items.forEach( item => {
                blockedUsers.push(parseInt(item.SK.slice(4)));
            });
        }
        if (req.query.commercial == true || req.query.commercial.toLowerCase() == 'true') {
            let users = await dynaUser.getCommercialUsers(geohashing).catch(err => {
                err.status = 500;
                throw err;
            });
            if (users.Count == 0 ) {
                res.status(204).send();
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.slice(5)));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item));
                }
                res.status(200).send({
                    "users": users_arr,
                })
            }
        } else {
            let users = await dynaUser.getAllUsers(geohashing);
            if (users.Count == 0 ) {
                res.status(204).send();
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.split('#')[1]));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item))
                }
                res.status(200).send({
                    "users": users_arr,
                })
            }
        }
    } catch (err) {
        next(err)
    }
});

// user block a user
router.post(`/block`, async function (req, res, next) {
    let body = { ...req.body};
    let orbInfo = await dynaOrb.retrieve(body).catch(err => {
        err.status = 500;
        next(err);
    });
    let block;
    if (orbInfo) {
        body.block_id = orbInfo.user_id;
        block = await dynaUser.blockUser(body).catch(err => {
            err.status = 500;
            next(err);
        });
    }
    if (block) res.status(200).send("user block");
});

// user set age  
router.put(`/setAge`, async function (req, res, next) {
    let body = { ...req.body};
    let setting = await dynaUser.setAge(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (setting) res.status(200).send("Age set");
});

// user set gender
router.put(`/setGender`, async function (req, res, next) {
    let body = { ...req.body};
    let setting = await dynaUser.setGender(body).catch(err => {
        err.status = 500;
        next(err);
    });
    if (setting) res.status(200).send("Gender set");
});

// Set commercial setting
router.put(`/setCommercial`, async function (req, res, next) {
    try {
        let body = { ...req.body};
        let userInfo = await dynaUser.getPUBinfo(body);
        body.first = userInfo.Item.numeric;
        body.second = userInfo.Item.geohash;
        if (userInfo.Item.payload.commercial) {
            body.old = "c";
            body.new = "";
        } else {
            body.old = "";
            body.new = "c";
        }
        dynaUser.setCommercial(body);
        dynaUser.setCommercial2(body);
        res.status(200).send();
        
    } catch (err) {
        next(err);
    }
});

// Set new postal code setting
// receive user_id, postal_code, old_postal, setting: first | second
router.put(`/setPostal`, async function (req, res, next) {
    try {
        let body = { ...req.body};
        let userInfo = await dynaUser.getPUBinfo(body);
        if (userInfo.Item.payload.commercial == true){
            body.value = "c";
        } else {
            body.value = "";
        };
        if (body.setting == "first") {
            // set geohash first to check if postal code exists
            await dynaUser.setNumericPostal(body, 'pub', geohash.postal_to_geo(body.postal_code));
            await dynaUser.setNumericPostal(body, 'pte', body.postal_code);
            await dynaUser.setPostal2(body);
        } else {
            await dynaUser.setGeohashPostal(body, 'pub', geohash.postal_to_geo(body.postal_code));
            await dynaUser.setGeohashPostal(body, 'pte', body.postal_code);
            await dynaUser.setPostal2(body);
        };
        res.status(200).send();
        
    } catch (err) {
        next(err);
    }
});

router.get('/getuuid', async function (req, res, next) {
    const uuid = uuidv4();
    res.status(200).send(uuid);
})

// receive offer/request (orb), info, where, when, tip, username, postal_code, commercial, success_dict
router.post(`/post_orb`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        body.expiry_dt = moment().add(7, 'days').unix();
        body.created_dt = moment().unix();
        body.geohashing = geohash.postal_to_geo(body.postal_code);
        body.geohashing52 = geohash.postal_to_geo52(body.postal_code);
        body.title = body.info.split(' ').slice(0,2).join(' ');
        body.title = "From Telegram: " + body.title + "...";
        body.media = false;
        // offer/request logic
        if (body.orb == "offer") {
            body.nature = 600;
        } else {
            body.nature = 700;
        }
        // if the post is commercial, we have to keep track
        if (body.commercial == true) {
            let pubData = await dynaUser.getPUBinfo(body);
            if ((pubData.Item.payload.lastCommercialPost + 576000) > moment().unix()) {
                let err = new Error("Please wait before posting another commercial ORB.");
                err.status = 405;
                throw err;
            } else if ((pubData.Item.payload.lastCommercialPost + 576000) <= moment().unix()) {
                dynaUser.setLastCommercialPost(body);
            } else {
                let err = new Error("User not found");
                err.status = 404;
                throw err;
            }
        } 
        await dynaOrb.postOrb(body);
        res.status(201).json({
            "orb_uuid": body.orb_uuid
        });
    } catch (err) {
        if (err.message == 'Postal code does not exist!') err.status = 404;
        next(err);
    }
});

router.get(`/commercial_buffer`, async function (req, res, next) {
    let pubData = await dynaUser.getPUBinfo(req.query);
    if (pubData.Item) {
        res.status(200).json({
            "previous": pubData.Item.payload.lastCommercialPost
        });
    }
});

// receive orb uuid, user id
router.put(`/complete_orb`, async function (req, res, next) {
    let body = { ...req.body };
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found";
    });
    if (orbData) {
        if (orbData.user_id == body.user_id) {
            // initiator complete
            body.expiry_dt = orbData.expiry_dt;
            body.geohash = orbData.geohash;
            const completion = await dynaOrb.update(body).catch(err => {
                err.status = 500;
                next(err);
            });
            if (completion == true) {
                const sDict = await dynaOrb.retrieveSucc(body).catch(err => {
                    err.status = 500;
                    next(err);
                });
                if (sDict) {
                    res.status(200).send(sDict);
                } else {
                    res.status(204).send();
                }
            }
        } else {
            // someone else complete
            await dynaOrb.acceptance(body);
            res.status(200).send();
        }
    }
});

// receive orb uuid, user id
router.put(`/delete_orb`, async function (req, res, next) {
    let body = { ...req.body};
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found"
    });
    if (orbData) {
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        body.payload = orbData.payload;
        body.payload.available = false;
        const deletion = await dynaOrb.delete(body).catch(err => {
            err.status = 500;
            next(err);
        });
        if (deletion == true) {
            const sDict = await dynaOrb.retrieveSucc(body).catch(err => {
                err.status = 500;
                next(err);
            });
            if (sDict) {
                res.status(200).send(sDict);
            } else {
                res.status(204).send();
            }
        }
    }
});

router.post(`/report`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        await dynaOrb.report(body);
        res.status(201).send();
    } catch (err) {
        next(err)
    }
});

// ADMIN FUNCTIONS
router.post(`/ban`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        await dynaUser.banUser(body);
        // remove user from location stream: LOC#geohash
        let pubData = await dynaUser.getPUBinfo(body);
        if (pubData.Item.payload.commercial) {
            body.comm = 'c';
            if (pubData.Item.numeric) {
                dynaUser.removeLocation(body, pubData.Item.numeric);
                dynaUser.setNumericPostal(body, 'pub', null);
                dynaUser.setNumericPostal(body, 'pte', null);
            } 
            if (pubData.Item.geohash) {
                dynaUser.removeLocation(body, pubData.Item.geohash);
                dynaUser.setGeohashPostal(body, 'pub', null);
                dynaUser.setGeohashPostal(body, 'pte', null);
            }
            
        } else {
            body.comm = '';
            if (pubData.Item.numeric) {
                dynaUser.removeLocation(body, pubData.Item.numeric);
                dynaUser.setNumericPostal(body, 'pub', null);
                dynaUser.setNumericPostal(body, 'pte', null);
            } 
            if (pubData.Item.geohash) {
                dynaUser.removeLocation(body, pubData.Item.geohash);
                dynaUser.setGeohashPostal(body, 'pub', null);
                dynaUser.setGeohashPostal(body, 'pte', null);
            }
        }
        res.status(201).send()
    } catch (err) {
        next(err)
    }
});

router.post(`/unban`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        await dynaUser.unbanUser(body);
        res.status(201).send()
    } catch (err) {
        next(err)
    }
});

router.post(`/star`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        await dynaUser.starUser(body);
        res.status(201).send();
    } catch (err) {
        next(err)
    }
});

router.put(`/delete_orb_admin`, async function (req, res, next) {
    let body = { ...req.body};
    const orbData = await dynaOrb.retrieve(body).catch(err => {
        err.status = 404;
        err.message = "ORB not found"
    });
    if (orbData) {
        body.expiry_dt = orbData.expiry_dt;
        body.geohash = orbData.geohash;
        body.admin_id = body.user_id;
        body.user_id = orbData.user_id; // change user_id from admin to orb initiator

        const deletion = await dynaOrb.adminDelete(body).catch(err => {
            err.status = 500;
            next(err);
        });
        if (deletion == true) {
            const sDict = await dynaOrb.retrieveSucc(body).catch(err => {
                err.status = 500;
                next(err);
            });
            if (sDict) {
                res.status(200).send(sDict);
            } else {
                res.status(204).send();
            }
        }
    }
});

module.exports = router;

