import fontawesome from "../vendor/font-awesome.min";

const clickFunction = (e) => {
  console.log({ e });
};

document.addEventListener("DOMContentLoaded", () => {
  const navbar = document.getElementById("navbar");
  const navItems = navbar.querySelectorAll("a");
  navItems.forEach((item) => {
    item.addEventListener("click", (e) => {
      console.log({ e });
    });
  });
});

window.addEventListener("phx:page-loading-stop", () => {
  const navbar = document.getElementById("navbar");
  if (!navbar) return;
  const navItems = navbar.querySelectorAll("a");
  const url = new URL(document.URL);
  url.search = "";
  navItems.forEach((item) => {
    const ref = new URL(item.href);
    ref.search = "";

    if (ref.toString() === url.toString()) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
});
