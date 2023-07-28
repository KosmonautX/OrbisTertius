// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
import Hooks from "./hooks";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import ModalApplication, { VideoMute } from "./modal_application";

let csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute("content");


let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken,
        locale: Intl.NumberFormat().resolvedOptions().locale,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        timezone_offset: -new Date().getTimezoneOffset(),
    },
    metadata: {
        keyup: (e, el) => {
            return {
                key: e.key,
                metaKey: e.metaKey,
                repeat: e.repeat,
            };
        },
    },
    hooks: Hooks
});

// Show progress bar on live navigation and form submits
topbar.config({
    barColors: {
        0: "#00A86B"
    },
    shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", info => {
    if (info.detail.kind == "redirect") {
        const main = document.querySelector("main");
        main.classList.add("phx-page-loading")
    }
})

window.addEventListener("phx:page-loading-stop", (info) => {
    const main = document.querySelector("main");
    main.classList.remove("phx-page-loading")
    VideoMute();
    topbar.hide();
    if (
        window.location.hostname == "web.scratchbac.com" && ["redirect", "patch"].includes(info.detail.kind)
    ) {
        gtag("event", "page_view", {
            page_title: document.title,
            page_location: location.href,
            page_path: location.pathname,
        });
    }
});

window.addEventListener("DOMContentLoaded", () => {
    ModalApplication();
});

window.addEventListener("phos:clipcopy", (event) => {
    if ("share" in navigator) {
        const text = event.target.textContent;
        navigator.share({
            title: document.querySelector('meta[property="og:title"]')?.content,
            url: text,
        });
    } else if ("clipboard" in navigator) {
        const text = event.target.textContent;
        navigator.clipboard.writeText(text);
    } else {
        alert(
            "Sorry, your browser does not support clipboard copy or sharing functions."
        );
    }
});

// Add event listener to the search icon
document.addEventListener('DOMContentLoaded', () => {
    const searchIcon = document.querySelector('.search-icon');
    const cancelIcon = document.querySelector('.cancel-icon');
    const searchInput = document.querySelector('.search-input');

    searchIcon.addEventListener('click', () => {
        searchIcon.classList.add('hidden');
        cancelIcon.classList.remove('hidden');
        searchInput.style.display = 'block';
        searchInput.focus();
    });

    cancelIcon.addEventListener('click', () => {
        searchIcon.classList.remove('hidden');
        cancelIcon.classList.add('hidden');
        searchInput.style.display = 'none';
    });
});


// Hide the input box initially
searchInput.style.display = 'none';




// dark mode js code

var themeToggleDarkIcon = document.getElementById("theme-toggle-dark-icon");
var themeToggleLightIcon = document.getElementById("theme-toggle-light-icon");

// Change the icons inside the button based on previous settings
if (themeToggleDarkIcon && themeToggleLightIcon) {
    if (
        localStorage.getItem("color-theme") === "dark" ||
        (!("color-theme" in localStorage) &&
            window.matchMedia("(prefers-color-scheme: dark)").matches)
    ) {
        themeToggleLightIcon.classList.remove("hidden");
    } else {
        themeToggleDarkIcon.classList.remove("hidden");
    }

    var themeToggleBtn = document.getElementById("theme-toggle");

    themeToggleBtn.addEventListener("click", function () {
        // toggle icons inside button
        themeToggleDarkIcon.classList.toggle("hidden");
        themeToggleLightIcon.classList.toggle("hidden");

        // if set via local storage previously
        if (localStorage.getItem("color-theme")) {
            if (localStorage.getItem("color-theme") === "light") {
                document.documentElement.classList.add("dark");
                localStorage.setItem("color-theme", "dark");
            } else {
                document.documentElement.classList.remove("dark");
                localStorage.setItem("color-theme", "light");
            }

            // if NOT set via local storage previously
        } else {
            if (document.documentElement.classList.contains("dark")) {
                document.documentElement.classList.remove("dark");
                localStorage.setItem("color-theme", "light");
            } else {
                document.documentElement.classList.add("dark");
                localStorage.setItem("color-theme", "dark");
            }
        }
    });
}

// connect if there are any LiveViews on the page
liveSocket.connect();
liveSocket.enableDebug();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;



