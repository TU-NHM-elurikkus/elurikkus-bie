<g:set var="taxonStyleClass" value="${taxon.rankID > 5999 ? 'taxon-name-italic' : ''}" />

<span class=${taxonStyleClass}>
    ${name}${taxon.commonName ? "; " : ""}
</span>
${taxon.commonName ?: ""}


<g:if test="${taxon.occurrenceCount}">
    (${taxon.occurrenceCount})
</g:if>
