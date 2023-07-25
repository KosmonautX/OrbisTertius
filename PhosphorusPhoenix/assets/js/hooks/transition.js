const TransitionHook = {
    mounted() {
        this.from = this.el.getAttribute('data-transition-from').split(' ');
        this.to = this.el.getAttribute('data-transition-to').split(' ');

        // Add classes from 'data-transition-from'
        this.el.classList.add(...this.from);

        // After a short delay (10ms), remove 'data-transition-from' classes and add 'data-transition-to' classes
        setTimeout(() => {
            this.el.classList.remove(...this.from);
            this.el.classList.add(...this.to);
        }, 10);
    },
    updated() {
        // Remove 'transition' class and 'data-transition-from' classes when the element is updated
        this.el.classList.remove('transition');
        this.el.classList.remove(...this.from);
    },
};

export default TransitionHook;
