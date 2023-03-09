const findSection = (target) => {
  if (target.localName === "section") return target
  return findSection(target.parentElement)
}

const muteVideo = vid => {
  vid.muted = true
  vid.nextElementSibling.firstElementChild.firstElementChild.classList.remove('hidden')
  vid.nextElementSibling.firstElementChild.lastElementChild.classList.add('hidden')
}

const CarouselControl = {
  mounted() {
    let section

    this.el.firstElementChild.addEventListener('click', ({ target }) => {
      section = findSection(target)
      section.querySelectorAll('video').forEach(muteVideo)
    })

    this.el.lastElementChild.addEventListener('click', ({ target }) => {
      section = findSection(target)
      section.querySelectorAll('video').forEach(muteVideo)
    })
  }
}

export default CarouselControl
