const express = require('express');
const router = express.Router();
/*
 * Fetch App Version
 */
router.get(`/:version`, async function (req, res, next) {
    try{
        const orbs = req.params.version
        const minimum_version = "1.0.7"
        const latest_version = "1.0.9"
        if (req.params.version.localeCompare(minimum_version, undefined, { numeric: true, sensitivity: 'base' }) == -1) {
            res.status(409).send({
                "update": "required",
            });
        } else {
            if(req.params.version.localeCompare(latest_version, undefined, { numeric: true, sensitivity: 'base' }) == -1){
                update = {
                "update": "available"
                }} else{
                    update = {"update": "unrequired"}
                }
            res.status(200).send(update);
        }

    }catch(err){
        if (err.message == "Recall Version failed") err.status = 401;
        next(err);
    }
});

module.exports = router;
