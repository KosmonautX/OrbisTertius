import Glide, { Controls, Breakpoints } from "../../vendor/glide.modular.esm"

const Carousel = {
  mounted() {
    const glide = new Glide(`#${this.el.id}`, { perView: 1, type: 'carousel' })
    console.log({glide})
    glide.mount({ Controls, Breakpoints })
  }
}

export default Carousel
