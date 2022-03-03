const geohash = require('ngeohash');
const hexhash = require('h3-js')
// migrate in parts by converting to hexagonal when radius less than 30,
// support both frameworks and translate into hexhash till you throw error and
// have retry logic routes are unchanged
// const fs = require('fs');
// const rawdata = fs.readFileSync('./HeimdallrNode/resources/onemap3.json', 'utf-8');
// const onemap = JSON.parse(rawdata);
const onemap = require('../resources/onemap3.json');

function postal_to_geo(postal, radius=8) {
    if (postal == null || postal == "") {
        return null;
    }
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    // if the zero got omitted due to integers
    if (postal.length == 5) {
        postal = "0" + postal;
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!");
    }
    return latlon_to_geo(latlon, radius);
};

function postal_to_geo52(postal) {
    if (postal == null || postal == "") {
        return null;
    }
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    if (postal.length == 5) {
        postal = "0" + postal;
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo52(latlon);
}

function latlon_to_geo(latlon, radius=8) {
    return hexhash.geoToH3(parseFloat(latlon.lat), parseFloat(latlon.lon), radius);
};

function latlon_to_geo52(latlon) {
    return hexhash.geoToH3(parseFloat(latlon.lat), parseFloat(latlon.lon), 12);
}

function neighbour(geohashing, radius=8) {
    return hexhash.kRing(geohashing, radius);
}

function boundaries(geohashing, radius=8) {
    return hexhash.kRing(geohashing, radius);
}

function check_postal(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        return false;
    } else {
        return true;
    }
}

function transcode_geohash(geohash, fineGrain, coarseGrain){
    return hexhash.h3ToParent(h3Index, coarseGrain)
}

function geohash_to_hexhash(geohash, radius){
    return hexhash.geoToH3(geohash.decode_int(geohash, radius), coarseGrain) //fine grained and coarse grained
}
function decode_hash(hash, bit){
    return geohash.decode_int(hash, bit);
}
module.exports = {
    postal_to_geo: postal_to_geo,
    postal_to_geo52: postal_to_geo52,
    latlon_to_geo: latlon_to_geo,
    latlon_to_geo52: latlon_to_geo52,
    neighbour: neighbour,
    check_postal: check_postal,
    decode_hash: decode_hash,
    transcode_geohash: transcode_geohash
}
