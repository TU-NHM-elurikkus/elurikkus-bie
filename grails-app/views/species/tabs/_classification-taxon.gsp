<bie:formatSciName
    rankId="${taxon.rankID}"
    rank="${taxon.rank}"
    name="${name}${(taxon.commonName ? ('; ' + taxon.commonName) : '')}"
    simpleName="${false}"
/>

(${taxon.occurrenceCount})
