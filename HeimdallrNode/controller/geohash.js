const geohash = require('ngeohash');
// const fs = require('fs');
// const rawdata = fs.readFileSync('./HeimdallrNode/resources/onemap3.json', 'utf-8');
// const onemap = JSON.parse(rawdata);
const onemap = require('../resources/onemap3.json');

function postal_to_geo(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo(latlon);
};

function postal_to_geo52(postal) {
    if (typeof postal !== 'string') {
        postal = postal.toString();
    }
    let latlon = onemap[postal];
    if (latlon == "undefined" || latlon == null) {
        throw new Error("Postal code does not exist!")
    }
    return latlon_to_geo52(latlon);
}

function latlon_to_geo(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 30);
    return geohashing;
};

function latlon_to_geo52(latlon) {
    let geohashing = geohash.encode_int(parseFloat(latlon.LATITUDE), parseFloat(latlon.LONGITUDE), 52);
    return geohashing;
}

function get_geo_array(geohashing) {
    let arr = geohash.neighbors_int(geohashing, 30); // array
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

module.exports = {
    postal_to_geo: postal_to_geo,
    postal_to_geo52: postal_to_geo52,
    latlon_to_geo: latlon_to_geo,
    latlon_to_geo52: latlon_to_geo52,
    get_geo_array: get_geo_array,
    check_postal: check_postal,
}