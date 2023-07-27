const SearchToggler = {
    mounted() {
      this.searchIcon = this.el.querySelector('.search-icon');
      this.cancelIcon = this.el.querySelector('.cancel-icon');
      this.searchInput = this.el.querySelector('.search-input');
      this.searchIcon.addEventListener('click', this.toggleSearch.bind(this));
      this.cancelIcon.addEventListener('click', this.toggleSearch.bind(this));
    },
    toggleSearch() {
      this.searchIcon.classList.toggle('hidden');
      this.cancelIcon.classList.toggle('hidden');
      this.searchInput.classList.toggle('hidden');
      if (!this.searchInput.classList.contains('hidden')) {
        this.searchInput.focus();
      }
    },
  };
  
  export default SearchToggler;
  