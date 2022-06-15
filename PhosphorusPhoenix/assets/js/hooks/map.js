export const InitIndexMap = {
  mounted() {
    var centred = false;
    const mapid = this.el.id;
    const style = document.createElement("link");
    style.href = "https://unpkg.com/leaflet@1.8.0/dist/leaflet.css";
    style.rel = "stylesheet";
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(style);

    const js = document.createElement("script");
    js.src = "https://unpkg.com/leaflet@1.8.0/dist/leaflet.js";
    js.type = "text/javascript";
    var map = L.map(mapid).setView([1.3521, 103.8198], 11);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap'
    }).addTo(map);
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(js);

    this.handleEvent("centre_marker", (latlon) => {
      L.marker([latlon.latitude, latlon.longitude]).addTo(map)

      // Centres to live latlon
      if (!centred) {
        centred = true
        map.flyTo([latlon.latitude, latlon.longitude], 15);
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
    // const style = document.createElement("link");
    // style.href = "https://unpkg.com/leaflet@1.8.0/dist/leaflet.css";
    // style.rel = "stylesheet";
    // (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(style);

    const js = document.createElement("script");
    js.src = "https://unpkg.com/leaflet@1.8.0/dist/leaflet.js";
    js.type = "text/javascript";
    var map = L.map(mapid, { center: [1.3521, 103.8198], zoom: 12 })
    var currMarker = new L.Marker([1.3521, 103.8198]).addTo(map);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
    }).addTo(map);
    (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(js);

    const view = this;
    map.on("click", function (e) {
      currMarker.setLatLng(e.latlng)
      view.pushEventTo(view.el, "modalmap_setloc", e.latlng)
    });
  }
}
