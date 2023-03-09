const ModalApplication = () => {
  const modal = document.querySelector('[data-selector="phos_modal_message"]')

  if (!modal) return

  const encodedReturnTo = encodeURIComponent(document.location.pathname)

  modal.querySelectorAll('a[data-phx-link="redirect"]').forEach(val => {
    const url = new URL(val.href, document.location.origin)
    url.searchParams.set('return_to', encodedReturnTo)
    val.href = `${val.href}${url.search}`
  })
}

export const VideoMute = () => {
  const selectors = document.querySelectorAll('[data-selector="mute"]')

  if (!selectors) return

  const searchSpan = el => {
    if (el.localName === "span") return el
    if (el.localName === "a") return searchSpan(el.firstElementChild)

    return searchSpan(el.parentElement)
  }

  const mouseEnter = el => {
    el.addEventListener('mouseover', ({ target }) => {
      searchSpan(target).classList.remove('hidden')
      searchSpan(target).classList.add('flex')
    })
  }

  const mouseLeave = el => {
    el.addEventListener('mouseout', ({ target }) => {
      searchSpan(target).classList.add('hidden')
      searchSpan(target).classList.remove('flex')
    })
  }
  
  selectors.forEach(el => {
    mouseEnter(el)
    mouseLeave(el)
  })
}

export default ModalApplication
