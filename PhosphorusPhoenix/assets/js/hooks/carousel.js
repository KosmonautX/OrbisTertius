import Glide, { Swipe, Controls, Breakpoints } from "../../vendor/glide.modular.esm"

const findVideo = el => {
  if (!el) return null
  if (el.localName === "video") return el
  if (el.localName === "a" && el.nextElementSibling) return findVideo(el.nextElementSibling)
  return findVideo(el.firstElementChild)
}

const Carousel = {
  mounted() {
    const glide = new Glide(`#${this.el.id}`, {
      perView: 1,
      swipeThreshold: 88,
      type: 'carousel'
    })
    glide.mount({ Controls, Breakpoints, Swipe })

    glide.on(['move.after', 'swipe.after'], (mov) => {
      const el = this.el.querySelector(".glide__slide--active")
      const media = findVideo(el)
      if (!media) return

      if (media.localName === "video" && media.paused) {
        media.play()
      }
    })
  }
}

export default Carousel
