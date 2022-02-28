import {Direction, LatLonBox, LatLonPoint} from "../types/geohash"

/**
 * * typed geohash library
 * Copyright (c) 2011, Sun Ning. started from ngeohash package
 * will need to customise for internal use case in future
 * Obfuscate lat-lon data and posting data into pure hash format
 * front-end client library needed for _int
 *
 * **/
var BASE32_CODES = "0123456789bcdefghjkmnpqrstuvwxyz";
var BASE32_CODES_DICT: any = {};
for (var i = 0; i < BASE32_CODES.length; i++) {
  BASE32_CODES_DICT[BASE32_CODES.charAt(i)] = i;
}

var MIN_LAT = -90;
var MAX_LAT = 90;
var MIN_LON = -180;
var MAX_LON = 180;
/**
 * Significant Figure Hash Length
 *
 * This is a quick and dirty lookup to figure out how long our hash
 * should be in order to guarantee a certain amount of trailing
 * significant figures. This was calculated by determining the error:
 * 45/2^(n-1) where n is the number of bits for a latitude or
 * longitude. Key is # of desired sig figs, value is minimum length of
 * the geohash.
 * @type Array
 */
//     Desired sig figs:  0  1  2  3  4   5   6   7   8   9  10
var SIGFIG_HASH_LENGTH: number[] = [0, 5, 7, 8, 11, 12, 13, 15, 16, 17, 18];
/**
 * Encode Integer
 *
 * Create a Geohash out of a latitude and longitude that is of 'bitDepth'.
 *
 * @param {Number} latitude
 * @param {Number} longitude
 * @param {Number} bitDepth
 * @returns {Number}
 */
var encode_int = function (latitude: number, longitude: number, bitDepth?: number): number {

  bitDepth = bitDepth || 52;

  var bitsTotal = 0,
  maxLat = MAX_LAT,
  minLat = MIN_LAT,
  maxLon = MAX_LON,
  minLon = MIN_LON,
  mid,
  combinedBits = 0;

  while (bitsTotal < bitDepth) {
    combinedBits *= 2;
    if (bitsTotal % 2 === 0) {
      mid = (maxLon + minLon) / 2;
      if (longitude > mid) {
        combinedBits += 1;
        minLon = mid;
      } else {
        maxLon = mid;
      }
    } else {
      mid = (maxLat + minLat) / 2;
      if (latitude > mid) {
        combinedBits += 1;
        minLat = mid;
      } else {
        maxLat = mid;
      }
    }
    bitsTotal++;
  }
  return combinedBits;
};

/**
 * Decode Bounding Box Integer
 *
 * Decode hash number into a bound box matches it. Data returned in a four-element array: [minlat, minlon, maxlat, maxlon]
 * @param {Number} hashInt
 * @param {Number} bitDepth
 * @returns {Array}
 */
var decode_bbox_int = function (hashInt: number, bitDepth: number) : LatLonBox {

  bitDepth = bitDepth || 52;

  var maxLat = MAX_LAT,
  minLat = MIN_LAT,
  maxLon = MAX_LON,
  minLon = MIN_LON;

  var latBit = 0, lonBit = 0;
  var step = bitDepth / 2;

  for (var i = 0; i < step; i++) {

    lonBit = get_bit(hashInt, ((step - i) * 2) - 1);
    latBit = get_bit(hashInt, ((step - i) * 2) - 2);

    if (latBit === 0) {
      maxLat = (maxLat + minLat) / 2;
    }
    else {
      minLat = (maxLat + minLat) / 2;
    }

    if (lonBit === 0) {
      maxLon = (maxLon + minLon) / 2;
    }
    else {
      minLon = (maxLon + minLon) / 2;
    }
  }
  return [minLat, minLon, maxLat, maxLon];
};

function get_bit(bits: number, position: number) {
  return (bits / Math.pow(2, position)) & 0x01;
}

/**
 * Decode Integer
 *
 * Decode a hash number into pair of latitude and longitude. A javascript object is returned with keys `latitude`,
 * `longitude` and `error`.
 * @param {Number} hash_int
 * @param {Number} bitDepth
 * @returns {Object}
 */
var decode_int = function (hash_int: number, bitDepth: number): LatLonPoint {
  var bbox = decode_bbox_int(hash_int, bitDepth);
  var lat = (bbox[0] + bbox[2]) / 2;
  var lon = (bbox[1] + bbox[3]) / 2;
  var latErr = bbox[2] - lat;
  var lonErr = bbox[3] - lon;
  return {latitude: lat, longitude: lon,
          error: {latitude: latErr, longitude: lonErr}};
};

/**
 * Neighbor Integer
 *
 * Find neighbor of a geohash integer in certain direction. Direction is a two-element array, i.e. [1,0] means north, [-1,-1] means southwest.
 * direction [lat, lon], i.e.
 * [1,0] - north
 * [1,1] - northeast
 * ...
 * @param {String} hash_string
 * @returns {Array}
*/
var neighbor_int = function (hash_int: number, direction: Direction, bitDepth?: number): number {
    bitDepth = bitDepth || 52;
    var lonlat = decode_int(hash_int, bitDepth);
    var neighbor_lat = lonlat.latitude + direction[0] * lonlat.error.latitude * 2;
    var neighbor_lon = lonlat.longitude + direction[1] * lonlat.error.longitude * 2;
    neighbor_lon = ensure_valid_lon(neighbor_lon);
    neighbor_lat = ensure_valid_lat(neighbor_lat);
    return encode_int(neighbor_lat, neighbor_lon, bitDepth);
};

/**
 * Neighbors Integer
 *
 * Returns all neighbors' hash integers clockwise from north around to northwest
 * 7 0 1
 * 6 x 2
 * 5 4 3
 * @param {Number} hash_int
 * @param {Number} bitDepth
 * @returns {encode_int'd neighborHashIntList|Array}
 */
var neighbors_int = function(hash_int: number, bitDepth: number): Array<number>{

    bitDepth = bitDepth || 52;

    var lonlat = decode_int(hash_int, bitDepth);
    var lat = lonlat.latitude;
    var lon = lonlat.longitude;
    var latErr = lonlat.error.latitude * 2;
    var lonErr = lonlat.error.longitude * 2;

    var neighbor_lat,
        neighbor_lon;

    var neighborHashIntList = [
                               encodeNeighbor_int(1,0),
                               encodeNeighbor_int(1,1),
                               encodeNeighbor_int(0,1),
                               encodeNeighbor_int(-1,1),
                               encodeNeighbor_int(-1,0),
                               encodeNeighbor_int(-1,-1),
                               encodeNeighbor_int(0,-1),
                               encodeNeighbor_int(1,-1)
                               ];

    function encodeNeighbor_int(neighborLatDir: number, neighborLonDir: number){
        neighbor_lat = lat + neighborLatDir * latErr;
        neighbor_lon = lon + neighborLonDir * lonErr;
        neighbor_lon = ensure_valid_lon(neighbor_lon);
        neighbor_lat = ensure_valid_lat(neighbor_lat);
        return encode_int(neighbor_lat, neighbor_lon, bitDepth);
    }

    return neighborHashIntList;
};

/**
 * Bounding Boxes Integer
 *
 * Return all the hash integers between minLat, minLon, maxLat, maxLon in bitDepth
 * @param {Number} minLat
 * @param {Number} minLon
 * @param {Number} maxLat
 * @param {Number} maxLon
 * @param {Number} bitDepth
 * @returns {bboxes_int.hashList|Array}
 */
var bboxes_int = function(minLat: number, minLon: number, maxLat: number, maxLon: number, bitDepth?: number): Array<number>{
    bitDepth = bitDepth || 52;

    var hashSouthWest = encode_int(minLat, minLon, bitDepth);
    var hashNorthEast = encode_int(maxLat, maxLon, bitDepth);

    var latlon = decode_int(hashSouthWest, bitDepth);

    var perLat = latlon.error.latitude * 2;
    var perLon = latlon.error.longitude * 2;

    var boxSouthWest = decode_bbox_int(hashSouthWest, bitDepth);
    var boxNorthEast = decode_bbox_int(hashNorthEast, bitDepth);

    var latStep = Math.round((boxNorthEast[0] - boxSouthWest[0])/perLat);
    var lonStep = Math.round((boxNorthEast[1] - boxSouthWest[1])/perLon);

    var hashList = [];

    for(var lat = 0; lat <= latStep; lat++){
        for(var lon = 0; lon <= lonStep; lon++){
            hashList.push(neighbor_int(hashSouthWest,[lat, lon], bitDepth));
        }
    }

  return hashList;
};

function ensure_valid_lon(lon: number) {
  if (lon > MAX_LON)
    return MIN_LON + lon % MAX_LON;
  if (lon < MIN_LON)
    return MAX_LON + lon % MAX_LON;
  return lon;
};

function ensure_valid_lat(lat: number) {
  if (lat > MAX_LAT)
    return MAX_LAT;
  if (lat < MIN_LAT)
    return MIN_LAT;
  return lat;
};

var geohash = {
  'encode_int': encode_int,
  'decode_int': decode_int,
  'decode_bbox_int': decode_bbox_int,
  'neighbor_int': neighbor_int,
  'neighbors_int': neighbors_int,
  'bboxes_int': bboxes_int
};

module.exports = geohash;
