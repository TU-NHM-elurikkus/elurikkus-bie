<ul>
    <li>
        <a href="${grailsApplication.config.bie.index.url}/species/${tc?.taxonConcept?.guid}.json" target="_blank">
            <g:message code="onlineResources.json" />
        </a>
    </li>
    <li>
        <a href="http://www.gbif.org/species/search?q=${tc?.taxonConcept?.nameString}" target="_blank">
            <g:message code="onlineResources.gbif" />
        </a>
    </li>
    <li>
        <a href="http://eol.org/search?q=${tc?.taxonConcept?.nameString}&show_all=true" target="_blank">
            <g:message code="onlineResources.eol" />
        </a>
    </li>
    <li>
        <a href="http://www.biodiversitylibrary.org/search?searchTerm=${tc?.taxonConcept?.nameString}#/names" target="_blank">
            <g:message code="onlineResources.bhl" />
        </a>
    </li>
    <li>
        <a href="http://www.eu-nomen.eu/portal/" target="_blank">
            <g:message code="onlineResources.pesi" />
        </a>
    </li>
    <li>
        <a href="http://www.arkive.org/explore/species?q=${tc?.taxonConcept?.nameString}" target="_blank">
            <g:message code="onlineResources.arkive" />
        </a>
    </li>
</ul>
