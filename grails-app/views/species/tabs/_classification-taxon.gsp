<bie:formatSciName
    rankId="${taxon.rankID}"
    rank="${taxon.rank}"
    name="${name}${(taxon.commonName ? ('; ' + taxon.commonName) : '')}"
    simpleName="${false}"
/>

<g:if test="${taxon.occurrenceCount}">
    (${taxon.occurrenceCount})
</g:if>
