import Glide, { Swipe, Controls, Breakpoints } from "../../vendor/glide.modular.esm"

const Carousel = {
  mounted() {
    const glide = new Glide(`#${this.el.id}`, {
      perView: 1,
      swipeThreshold: 88,
      type: 'carousel'
    })
    console.log({ glide })
    glide.mount({ Controls, Breakpoints, Swipe })
  }
}

export default Carousel
