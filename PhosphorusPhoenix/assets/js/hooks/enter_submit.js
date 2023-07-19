export const EnterSubmit = {
  mounted() {
    map = {}
    
    this.el.addEventListener("keydown", event => {
      if (event.key == "Control" || event.key == "Enter") {
        map[event.key] = true
        if (map["Control"] && map["Enter"]){
          event.preventDefault();
          this.el.dispatchEvent(
            new Event("submit", {bubbles: true, cancelable: true})
          )
          map["Control"] = false
          map["Enter"] = false
          document.getElementById("new-memory-form_message").value = ""          
          document.getElementById("new_on_desktop-memory-form_message").value=""
        }

      }
    })

    this.el.addEventListener("keyup", event => {
      if (event.key == "Control" || event.key == "Enter"){
        map[event.key] = false
      }
    })
  },

  updated(){
    let scrollDivDesktop = document.getElementById("message_container")
    scrollDivDesktop.scrollTop = scrollDivDesktop.clientHeight
  }
}