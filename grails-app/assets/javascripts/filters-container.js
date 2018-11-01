var filtersContainer = {};

(function() {
    this.container = null;

    this.collapse = function() {
        this.container.classList.add('filters-container--collapsed');
    };

    this.expand = function() {
        this.container.classList.remove('filters-container--collapsed');
    };

    this.toggle = function() {
        if(this.container.classList.contains('filters-container--collapsed')) {
            this.expand();
        } else {
            this.collapse();
        }
    };

    this.init = function() {
        this.container = document.getElementById('filters-container');

        if(this.container === null) {
            // Something went wrong, pack your bags.
            this.collapse = this.expand = this.toggle = null;
        } else if(window.innerWidth > 720) {
            this.expand();
        }
    }
}).apply(filtersContainer);
