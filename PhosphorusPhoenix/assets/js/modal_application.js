const ModalApplication = () => {
  const modal = document.querySelector('[data-selector="phos_modal_message"]')

  if (!modal) return

  const encodedReturnTo = encodeURIComponent(document.location.pathname)

  modal.querySelectorAll('a[data-phx-link="redirect"]').forEach(val => {
    const url = new URL(val.href, document.location.origin)
    url.searchParams.append('return_to', encodedReturnTo)
    val.href = `${url.pathname}${url.search}`
  })
}

export default ModalApplication
