const InitPosition = {
  mounted() {
    past = {latitude: 1.3521, longitude: 103.8188}

    navigator.geolocation.watchPosition(
      (pos) => {
        distance = haversine(past.latitude, past.longitude, pos.coords.latitude, pos.coords.longitude)
        console.log(distance)
        if (distance > 0.05){
          past = pos.coords
          this.pushEvent("live_location_update", { latitude: pos.coords.latitude, longitude: pos.coords.longitude })
        }
      },
      (err) => console.log(err),
      { maximumAge: 10000, enableHighAccuracy: true }
    )
  }
}

function haversine(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;    // Math.PI / 180
  var c = Math.cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 +
          c(lat1 * p) * c(lat2 * p) *
          (1 - c((lon2 - lon1) * p))/2;

  return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
}

export default InitPosition;
