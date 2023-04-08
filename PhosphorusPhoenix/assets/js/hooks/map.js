export const InitIndexMap = {
  mounted() {
    var centred = false
    const mapid = this.el.id;
    var map = L.map(mapid, { zoomControl: false}).setView([1.3521, 103.8198], 11);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap'
    }).addTo(map);

        // detect changes to map size due to modal
    setTimeout(function() {
        map.invalidateSize();
    }, 100);


    this.handleEvent("centre_marker", (latlng) => {
      L.marker([latlng.latitude, latlng.longitude]).addTo(map)

      // Centres to live latlng
      if (!centred) {
        centred = true
        map.flyTo([latlng.latitude, latlng.longitude], latlng.geolock || 15);
      }
    })

    this.handleEvent("add_polygon", (boundaries) => {
      L.polygon(boundaries.geo_boundaries, {color: 'teal'}).addTo(map);
    })
  }

}

export const InitModalMap  = {
  mounted() {
    const mapid = this.el.id;
    var map = L.map(mapid, { center: [1.3521, 103.8198], zoom: 12})
    var currMarker = new L.Marker([1.3521, 103.8198]).addTo(map);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
    }).addTo(map);


    // detect changes to map size due to modal
    setTimeout(function() {
        map.invalidateSize();
    }, 100);

    const view = this;
    map.on("click", function (e) {
      currMarker.setLatLng(e.latlng)
      view.pushEventTo(view.el, "modalmap_setloc", e.latlng)
    });

    this.handleEvent("add_old_marker", (latlngObject) => {
      var defaultLatLng = L.latLng(1.3521, 103.8198)
      var latlng = L.latLng(latlngObject.latitude, latlngObject.longitude);
      currMarker.setLatLng(latlng)

      if (!latlng.equals(defaultLatLng)) {
        map.setView(latlng, 15);
      }
    })
  }
}