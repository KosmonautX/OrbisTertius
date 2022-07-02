const InitPosition = {
  mounted() {
    navigator.geolocation.watchPosition(
      (pos) => {
        this.pushEvent("live_location_update", { latitude: pos.coords.latitude, longitude: pos.coords.longitude })
      },
      (err) => console.log(err),
      { maximumAge: 10000, enableHighAccuracy: true }
    )
  }
}

export default InitPosition;
