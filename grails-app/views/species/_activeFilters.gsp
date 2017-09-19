<p class="active-filters">
    <span class="active-filters__title">
        <g:message code="activefilters.title" />
    </span>

    <g:each var="item" in="${facetMap}" status="facetIdx">
        <span class="active-filters__filter">
            <span class="active-filters__label">
                <g:if test="${item.key?.contains("uid")}">
                    <g:set var="resourceType">
                        ${item.value}_resourceType
                    </g:set>

                    ${collectionsMap?.get(resourceType)}: ${collectionsMap?.get(item.value)}
                </g:if>

                <g:else>
                    <%-- TODO: Test it --%>
                    <g:message code="facet.${item.key}" default="${item.key}" />:
                    <g:message code="${item.key}.${item.value}" default="${item.value}" />
                </g:else>
            </span>

            <span
                class="fa fa-close active-filters__close-button"
                onclick="removeFacet(${facetIdx});"
            >
            </span>
        </span>
    </g:each>

    <g:if test="${facetMap?.size() > 1}">
        <span
            class="active-filters__clear-all-button"
            onclick="removeAllFacets();"
        >
            <g:message code="general.btn.clearAll.label" />
        </span>
    </g:if>
</p>
