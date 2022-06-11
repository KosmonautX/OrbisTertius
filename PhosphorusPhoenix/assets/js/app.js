// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
import socket from  "./user_socket.js"
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.InitGps = {
  mounted() {
    navigator.geolocation.watchPosition(
      (pos) => {
        this.pushEvent("live_location_update", { latitude: pos.coords.latitude, longitude: pos.coords.longitude })
      },
      (err) => console.log(err),
      { maximumAge: 0, enableHighAccuracy: true }
    )
  }
}
Hooks.FullMap = {
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
    var map = L.map(mapid).setView([51.505, -0.09], 13);

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
        map.panTo([latlon.latitude, latlon.longitude])
        map.setZoom(15)
      }
    })

    this.handleEvent("add_polygon", (boundaries) => {

      L.polygon(boundaries.geo_boundaries, {color: 'yellow'}).addTo(map);
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#f8f0e5"}, shadowColor: "rgba(25, 39, 86, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug()
liveSocket.enableLatencySim(1000)  //enabled for duration of browser session
liveSocket.disableLatencySim()
window.liveSocket = liveSocket



let time = new Intl.DateTimeFormat("en-US" , {
  hour: "numeric",
  dayPeriod: 'narrow',
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
})
let date = new Intl.DateTimeFormat("en-GB" , {
  month: "short",
  day: "2-digit",
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
})

var present_date // your internal frame of reference date
var current_date // from inbound messages in channel
var date_state // keeping track of deltas
var past_date // past messages in reveries
let phase = window.location.pathname.replaceAll("/",":")
let topic = phase.substring(1)



let data = {}
let channel = socket.channel(topic, data); // connect to chat "room"

channel.join().receive("ok", resp => { console.log("Joined successfully", resp) })
       .receive("error", resp => { console.log("Unable to join", resp)
                                  socket.disconnect()});

channel.on('shout', function (payload) { // listen to the 'shout' event
  console.log(payload)
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.source || 'guest';    // get name from payload or set default
  current_date = date.format(payload.time)
  if(typeof present_date === "undefined"){
    li.innerHTML = '<b>' + name + '</b>: ' + payload.message + '<i style="float:right;color: gray;"> '+ time.format(payload.time)+ '</i>'; // set li contents
    li.innerHTML += '<div style="width: 100%; height: 25px;  border-bottom: 1px solid gold; text-align: center"><span style="color:#192756; padding: 0 10px; font-style: oblique;">'+ "Session Genesis" +'</span></div>'
    present_date = current_date
  }
  else if (present_date !== current_date){
    li.innerHTML = '<b>' + name + '</b>: ' + payload.message + '<i style="float:right;color: gray;"> '+ time.format(payload.time)+ '</i>'; // set li contents
    li.innerHTML += '<div style="width: 100%; height: 25px;  border-bottom: 1px solid gold; text-align: center"><span style="color:#192756; padding: 0 10px; font-style: oblique;">'+ present_date +'</span></div>'
    present_state = current_date
  }
  else {
    li.innerHTML += '<b>' + name + '</b>: ' + payload.message + '<i style="float:right;color: gray;"> '+ time.format(payload.time)+ '</i>'; // set li contents
  }


  ul.insertBefore(li, ul.childNodes[0]);                    // prepend to list
});

channel.on('reverie', function (payload) { // listen to the 'reverie' event
  console.log(payload)
  let li = document.createElement("li"); // create new list item DOM element
  payload.time = payload.time* 1000
  past_date = date.format(payload.time)
  if(date_state !== past_date){
    if(typeof date_state !== "undefined") li.innerHTML = '<div style="width: 100%; height: 25px;  border-bottom: 1px solid gold; text-align: center"><span style="color:#192756; padding: 0 10px; font-style: oblique;">'+ date_state +'</span></div>'
    date_state = past_date
  }
  let name = payload.source || 'guest';    // get name from payload or set default
  li.innerHTML += '<b>' + name  + '</b>: ' + payload.message + '<i style="float:right;color: gray;"> '+ time.format(payload.time)+ '</i>'; // set li contents
  ul.append(li);                    // append to list
});

let ul = document.getElementById('msg-list');
let message = document.getElementById('msg'); // message input field
let destination = document.getElementById('name') //only you can access your own channel so destination field necessary
// "listen" for the [Enter] keypress event to send a message:
msg.addEventListener('keypress', function (event) {
  if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
    channel.push('shout', { // send the message to the server on "shout" channel
      message: message.value,    // get message text (value) from msg input field.
      destination: destination.value,
      destination_archetype: "USR",
      time: Date.now(),
      subject_archetype: "ORB",
      subject: "1"
    });
    msg.value = '';         // reset the message input field for next message.
  }
});

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
