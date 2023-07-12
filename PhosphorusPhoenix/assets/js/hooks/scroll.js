import { VideoMute } from "../modal_application";

// assets/js/infinite_scroll.js
export default Scroll = {
    page() { return this.el.dataset.page;},
    archetype() { return this.el.dataset.archetype;},
    loadMore(entries) {
        const target = entries[0];
        if (target.isIntersecting && this.pending == this.page()) {
            this.pending = this.page() + 1;
            this.pushEvent("load-more", {archetype: this.archetype()});
        }
    },
    mounted() {
        this.pending = this.page();
        this.observer = new IntersectionObserver(
            (entries) => this.loadMore(entries),
            {
                root: null, // window by default
                rootMargin: "400px",
                threshold: 0.1,
            }
        );
        this.observer.observe(this.el);
    },
    destroyed() {
        this.observer.unobserve(this.el);
    },
    updated() {
        this.pending = this.page();
        VideoMute()
    },
};

export const ScrollBottom = {
  mounted() {
    this.scrolledElement = this.el

    if (!this.scrolledElement) return

    this.scrolledElement.addEventListener('scroll', ({ target }) => {
      if (target.scrollHeight - target.scrollTop <= (target.clientHeight + 50)) {
        this.pushEvent("load-relations", {})
      }
    })
  },
};

export const ScrollTop = {
  mounted() {
    this.scrolledElement = this.el

    if (!this.scrolledElement) return
    if (this.scrolledElement.clientHeight > 0) this.scrolledElement.scrollTop = this.scrolledElement.clientHeight
    prevHeight = this.scrolledElement.scrollHeight    
    this.scrolledElement.addEventListener('scroll', ({ target }) => {
      if (target.scrollTop <= 150) {
          this.pushEvent("load-messages", {})
          prevScrollTop = target.scrollTop
      }
    });
  },

  updated() {
    this.el.scrollTop = this.el.scrollHeight - prevHeight + prevScrollTop
    prevScrollTop = this.el.scrollTop
    prevHeight = this.el.scrollHeight
  }
}