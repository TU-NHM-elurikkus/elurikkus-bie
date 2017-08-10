<form id="search-inpage" action="search" method="get" name="search-form">
    <div class="input-plus">
        <input
            id="search"
            type="text"
            name="q"
            value="${request.query == "*:*" ? '' : request.query}"
            placeholder="Search the Atlas"
            autocomplete="off"
            autofocus
            onfocus="this.value = this.value;"
            class="input-plus__field"
        />

        <button type="submit" class="erk-button erk-button--dark input-plus__addon">
            Search
        </button>
    </div>
</form>
