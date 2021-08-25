const geohash = require('ngeohash');
// const fs = require('fs');
// const rawdata = fs.readFileSync('./HeimdallrNode/resources/onemap3.json', 'utf-8');
// const onemap = JSON.parse(rawdata);
const onemap = require('../resources/onemap3.json');

function postal_to_geo(postal, radius=30) {
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

function latlon_to_geo(latlon, radius=30) {
    let geohashing = geohash.encode_int(parseFloat(latlon.lat), parseFloat(latlon.lon), radius);
    return geohashing;
};

function latlon_to_geo52(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.lat), parseFloat(latlon.lon), 52);
    return geohashing;
}

function get_geo_array(geohashing, radius=30) {
    let arr = geohash.neighbors_int(geohashing, radius); // array
    arr.unshift(geohashing);
    return arr;
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

function decode_hash(hash, bit){
    return geohash.decode_int(hash, bit);
}
module.exports = {
    postal_to_geo: postal_to_geo,
    postal_to_geo52: postal_to_geo52,
    latlon_to_geo: latlon_to_geo,
    latlon_to_geo52: latlon_to_geo52,
    get_geo_array: get_geo_array,
    check_postal: check_postal,
    decode_hash: decode_hash,
}
