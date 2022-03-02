const security = require('../controller/security');
const express = require('express');
const router = express.Router();
const moment = require('moment')
const navigate = require('../controller/actSpace').Space

router.use(function (req, res, next){
    security.checkUser(req, next);
    next()
})

router.put(`/will`, async function (req, res, next) {
    let body = { ...req.body };
    Promise.resolve(navigate.Action.orb(body.user_id, body.orb_uuid, body.action, body.actor_id)).then(response => {
        res.status(201).json({"Action_Complete" : body.action});
        }).catch(error => {
            if(error.code === "ConditionalCheckFailedException") res.status(error.statusCode).json({"Will to Action Condition Guards": "failed"})
            else res.status(error.statusCode).json(error.code)
        });
});

module.exports = router;
