<form id="search-inpage" method="get" name="search-form">
    <div class="input-plus">
        <input
            id="search"
            type="text"
            name="q"
            placeholder="${message(code: 'searchBox.btn.placeholder')}"
            autocomplete="off"
            onfocus="this.value = this.value;"
            class="input-plus__field"
        />

        <button type="submit" class="erk-button erk-button--dark input-plus__addon">
            <span class="fa fa-search"></span>
            <g:message code="general.btn.search" />
        </button>
    </div>
</form>
