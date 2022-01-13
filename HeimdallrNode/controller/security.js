const geohash = require("./geohash");

var checkUser = function (req, next) {
    try{
    switch (req.verification.role){
        case "barb":
            throw new Error("Guest User needs to Login for action");
        case "pleb":
            if(req.verification.user_id === req.body.user_id){
                break;
            }
            else{
                throw new Error("User does not match");
            }
        case "boni":
            throw new Error("Return thee to your pastures")
            break;

        default:
            throw new Error("Unknown Role")
    }
    }
    catch(err){
        err.status = 401
        next(err);
    }
}

var checkTerritory = function (req, next) {
    try{
        let agentTargetTerritory = req.query.geolocation || req.body.geolocation
        req.geolocation = {}
        if(!req.verification.territory || !agentTargetTerritory) throw new Error("Geolocation Unauthorised")
        Object.entries(agentTargetTerritory).slice(0,1).forEach(([geoName, address]) =>{
            if(req.verification.territory[geoName]){
                if(address.geolock){
                    req.geolocation.geolock = true
                }
                if(address.latlon){
                    /*check moving velocity from authorisation date time*/
                    if(geohash.latlon_to_geo(address.latlon,req.verification.territory[geoName].radius) ===req.verification.territory[geoName].hash){
                        req.geolocation.hash= geohash.latlon_to_geo(address.latlon, address.target)
                        req.geolocation.radius = address.target
                        return
                    }
                }
                else if (address.postal){
                    if(geohash.postal_to_geo(address.postal,req.verification.territory[geoName].radius) ===req.verification.territory[geoName].hash){
                        req.geolocation.hash = geohash.postal_to_geo(address.postal,address.target)
                        req.geolocation.radius = address.target
                        return
                    }
                }
                else if (address.geohashing){
                    if(req.verification.territory[geoName].hash ===geohash.transcode_geohash(
                        address.geohashing.hash,address.geohashing.radius,req.verification.territory[geoName].radius)){
                        if(address.target === address.geohashing.radius) req.geolocation.hash = address.geohashing.hash
                        else req.geolocation.hash = geohash.transcode_geohash(address.geohashing.hash,address.geohashing.radius, address.target)
                        req.geolocation.radius = address.target
                        return
                    }
                }
            }
            throw new Error('Geolocation in shambles')
        })}
    catch(err){
        err.status = 401
        next(err);
    }
}

var checkActor = function(auth, actor_id){
    switch (auth.role){
        case "barb":
            throw new Error("Guest User needs to Login for action");
        case "pleb":
            if(auth.user_id === actor_id){
                break;
            }
            else{
                throw new Error("User does not match");
            }

        default:
            throw new Error("Unknown Role")
    }
}

function checkAdmin(req, next) {
    try{
    if (req.verification.role !== "boni") {
        throw new Error("You ain't serving the good men");}
}catch(err){
        err.status = 401
        next(err);
    }
}

module.exports = {
    checkUser: checkUser,
    checkAdmin: checkAdmin,
    checkActor: checkActor,
    checkTerritory: checkTerritory
}
