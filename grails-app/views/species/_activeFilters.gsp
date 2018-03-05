<p class="active-filters">
    <span class="active-filters__title">
        <g:message code="activefilters.title" />:
    </span>

    <g:each var="item" in="${facetMap}" status="facetIdx">
        <span class="active-filters__filter">
            <span class="active-filters__label">
                <g:set var="facetValue">
                    <bie:trimQuotes value="${item.value}" />
                </g:set>

                <g:if test="${item.key?.contains("uid")}">
                    <g:set var="resourceType">
                        ${bie.trimQuotes(value: item.value)}_resourceType
                    </g:set>

                    <%-- XXX I am not confident this even works --%>
                    ${collectionsMap?.get(resourceType)}: ${collectionsMap?.get(item.value)}
                </g:if>

                <g:else>
                    <g:message code="facet.${item.key}" default="${item.key}" />:

                    <g:if test="${item.key == 'rank'}">
                        <g:message code="taxonomy.rank.${bie.formatI18nKey(value: item.value)}" default="${facetValue}" />
                    </g:if>

                    <g:else>
                        <g:message code="${item.key}.${bie.formatI18nKey(value: item.value)}" default="${facetValue}" />
                    </g:else>
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
