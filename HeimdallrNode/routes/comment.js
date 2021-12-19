const express = require('express');
const router = express.Router();
const {v4 : uuidv4} = require('uuid');
const moment = require('moment');
const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
AWS.config.update({
    region: ddb_config.region
});
const docClient = new AWS.DynamoDB.DocumentClient({endpoint: ddb_config.dyna});
const dynaOrb = require('../controller/dynamoOrb').comment;

router.get(`/check`, async function (req, res, next) {
    try {
        let comments = await dynaOrb.checkComment(req.query);
        if (comments.Items.length > 0) {
            let result = [];
            for (let item of comments.Items) {
                let dao = {};
                dao.comment_id = item.SK.slice(4);
                dao.user_id = item.inverse.slice(4);
                dao.orb_uuid = item.PK.slice(4);
                dao.created_dt = item.time;
                dao.comment = item.payload.comment;
                dao.available = item.available;
                result.push(dao);
            }
            res.json(result);
        } else {
            res.status(204).send();
        }
    } catch (err) {
        err.status = 404;
        next(err);
    }
});

// can only get parent comments
router.get(`/query`, async function (req, res, next) {
    try {
        let comments = await dynaOrb.queryComment(req.query);
        if (comments.Items.length > 0) {
            let result = [];
            for (let item of comments.Items) {
                let dao = {};
                dao.comment_id = item.SK.slice(4);
                dao.user_id = item.inverse.slice(4);
                if (item.payload.orb_uuid) {
                    dao.orb_uuid = item.payload.orb_uuid.slice(4);
                }
                dao.created_dt = item.time;
                dao.comment = item.payload.comment;
                dao.available = item.available;
                result.push(dao);
            }
            res.json(result);
        } else {
            res.status(204).send();
        }
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

router.post(`/post`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        body.comment_id = uuidv4();
        await dynaOrb.postComment(body).catch((err)=>{
            if (err.code == 'ConditionalCheckFailedException'){
                err.status = 404
                err.message = "ORBs no existe"
            }
            next(err)
        });
        await dynaOrb.postCommentRel(body);
        res.status(201).json({comment_id: body.comment_id});
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

router.post(`/reply`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        body.comment_id = moment().unix();
        present = await dynaOrb.childPresent(body).catch((err)=>{
            if (err.code == 'ConditionalCheckFailedException'){
                err.status = 404
                err.message = "Comments no existe"
            }
            next(err)
        })
        if(present){
            await dynaOrb.postChildComment(body);
            res.status(201).send({comment_id: body.comment_id});}
    }catch (err) {
        err.status = 400;
        next(err);
    }
});

// admin function for now?
// consequences to child comment if parent comment is deleted 
router.delete(`/delete`, async function (req, res, next) {
    try {
        let body = { ...req.body };
        await dynaOrb.deleteComment(body);
        if (body.parent_id == body.comment_id) {
            let comment = await dynaOrb.getComment(body);
            body.orb_uuid = comment.Item.payload.orb_uuid;
            await dynaOrb.deleteCommentRel(body);
        }
        res.status(200).send();
    } catch (err) {
        err.status = 400;
        next(err);
    }
});

router.get(`/get`, async function (req, res, next) {
    try {
        let comments = await dynaOrb.getComment(req.query);
        if (comments.Item) {
            let item = comments.Item;
            let dao = {};
            dao.comment_id = item.SK.slice(4);
            dao.user_id = item.inverse.slice(4);
            if (item.payload.orb_uuid) {
                dao.orb_uuid = item.payload.orb_uuid.slice(4);
            }
            dao.created_dt = item.time;
            dao.comment = item.payload.comment;
            dao.available = item.available;     
            res.json(dao);
        } else {
            res.status(204).send();
        }
    } catch (err) {
        next(err);
    }
});

module.exports = router;
