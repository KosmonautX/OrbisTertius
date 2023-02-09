const ModalApplication = {
  mounted() {
    console.log(this.el)
    var el = this.el

    window.addEventListener("DOMContentLoaded", () => {
      console.log(el)
    })

    window.addEventListener("phx:page-loading-stop", () => {
      console.log(el)
    })
  }
}

export default ModalApplication
