const findContainer = el => {
  if(el.localName == "section" && el.classList.contains("carousel-container")) {
    return el
  } else {
    return findContainer(el.parentElement)
  }
}

const shouldChangeElement = (el, selector) => {
  if (selector == "next" && el.nextElementSibling) return el.nextElementSibling
  if (selector == "prev" && el.previousElementSibling) return el.previousElementSibling
  return null
}

const toggle = (el, selector) => {
  if (!el) return

  const changedElement = shouldChangeElement(el, selector)

  if (!changedElement) return toggle(el.nextElementSibling, selector)
  if (changedElement.classList.contains("opacity-0") && el.classList.contains("opacity-100")) {
    changedElement.classList.remove("opacity-0", "hidden")
    changedElement.classList.add("opacity-100")
      el.classList.add("opacity-0", "hidden")
      el.classList.remove("opacity-100")

    return
  }

  return toggle(el.nextElementSibling, selector)
}

export const NextCarousel = {
  mounted() {
    this.el.addEventListener("click", e => {
      const container = findContainer(e.target)
      if (container.firstElementChild.localName == "div"  && container.firstElementChild.classList.contains("carousel-inner")) {
        return toggle(container.firstElementChild.firstElementChild, "next")
      }
    })
  }
}

export const PrevCarousel = {
  mounted() {
    this.el.addEventListener("click", e => {
      const container = findContainer(e.target)
      if (container.firstElementChild.localName == "div"  && container.firstElementChild.classList.contains("carousel-inner")) {
        return toggle(container.firstElementChild.firstElementChild, "prev")
      }
    })
  }
}
