package au.org.ala.bie

import org.codehaus.groovy.grails.web.json.JSONObject

/**
 * Species Controller
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class SpeciesController {

    def bieService
    def utilityService
    def biocacheService
    def grailsApplication

    /**
     * Search page - display search results fro the BIE (includes results for non-species pages too)
     */
    def search = {
        def query = params.q ?: "".trim()
        if(query == "*") query = ""
        def filterQuery = params.list("fq") // will be a list even with only one value
        def startIndex = params.offset ?: 0
        def rows = params.rows ?: 25
        def sortField = params.sortField ?: ""
        def sortDirection = params.dir ?: "desc"

        if (params.dir && !params.sortField) {
            sortField = "score" // default sort (field) of "score" when order is defined on its own
        }

        def requestObj = new SearchRequestParamsDTO(query, filterQuery, startIndex, rows, sortField, sortDirection)
        def searchResults = bieService.searchBie(requestObj)

        // empty search -> search for all records
        if (query.isEmpty()) {
            //render(view: "../error", model: [message: "No search term specified"])
            query = "*:*";
        }

        if (filterQuery.size() > 1 && filterQuery.findAll { it.size() == 0 }) {
            // remove empty fq= params IF more than 1 fq param present
            def fq2 = filterQuery.findAll { it } // excludes empty or null elements
            redirect(
                action: "search",
                params: [q: query, fq: fq2, start: startIndex, rows: rows, score: sortField, dir: sortDirection]
            )
        }

        def searchError = ""
        if(searchResults instanceof JSONObject) {
            if(searchResults?.error != null) {
                searchError = "${searchResults?.error}"
                // a super hacky way of checking whether search input is faulty. user input isn't validated at all, so we
                // search 400 from error message and just tell user to check input
                if(!searchError.contains("Server returned HTTP response code: 400")) {
                    // no point in spamming rollbar with faulty searches
                    log.info "TaxonConcept get Error: search() | params: ${params} | ${searchResults}"
                }
            }
        }

        render(view: "search", model: [
            errors: searchError,
            searchResults: searchResults?.searchResults ? searchResults.searchResults : [],
            facetMap: utilityService.addFacetMap(filterQuery),
            query: query?.trim(),
            filterQuery: filterQuery,
            idxTypes: utilityService.getIdxtypes(searchResults?.searchResults?.facetResults),
            collectionsMap: utilityService.addFqUidMap(filterQuery)
        ])
    }

    /**
     * Species page - display information about the requested taxa
     *
     * TAXON: a taxon is "any group or rank in a biological classification in which organisms are related."
     * It is also any of the taxonomic units. So basically a taxon is a catch-all term for any of the
     * classification rankings; i.e. domain, kingdom, phylum, etc.
     *
     * TAXON CONCEPT: A taxon concept defines what the taxon means - a series of properties
     * or details about what we mean when we use the taxon name.
     *
     */
    def show = {
        def guid = params.guid

        def taxonDetails = bieService.getTaxonConcept(guid)

        if (!taxonDetails) {
            log.info("TaxonConcept Not Found: ${guid} | params: ${params}")
            response.status = 404
            render(view: "../404", model: [message: "Requested taxon <b>${guid}</b> was not found"])
        } else if (taxonDetails instanceof JSONObject && taxonDetails.has("error")) {
            if (taxonDetails.error?.contains("FileNotFoundException")) {
                log.info("TaxonConcept FileNotFoundException: ${guid} | params: ${params} | ${taxonDetails.error}")
                response.status = 404
                render(view: "../404", model: [message: "Requested taxon <b>${guid}</b> was not found"])
            } else {
                log.info("TaxonConcept get Error: show() | ${guid} | params: ${params} | ${taxonDetails.error}")
                render(view: "../error", model: [message: taxonDetails.error])
            }
        } else if (taxonDetails.taxonConcept?.guid && taxonDetails.taxonConcept.guid != guid) {
            // old identifier so redirect to current taxon page
            redirect(uri: "/species/${taxonDetails.taxonConcept.guid}", permanent: true)
        } else {
            render(
                view: "show",
                model: [
                    tc: taxonDetails,
                    synonyms: utilityService.getSynonymsForTaxon(taxonDetails),
                    sortCommonNameSources: utilityService.getNamesAsSortedMap(taxonDetails.commonNames),
                    taxonHierarchy: bieService.getClassificationForGuid(taxonDetails.taxonConcept.guid),
                    childConcepts: bieService.getChildConceptsForGuid(taxonDetails.taxonConcept.guid),
                    speciesList: bieService.getSpeciesList(taxonDetails.taxonConcept?.guid ?: guid)
            ])
        }
    }

    /**
     * Display images of species for a given higher taxa.
     * Note: page is AJAX driven so very little is done here.
     */
    def imageSearch = {
        def model = [:]
        if(params.id) {
            def taxon = bieService.getTaxonConcept(params.id)
            model["taxonConcept"] = taxon
        }
        model
    }

    def bhlSearch = {
        render (view: "bhlSearch")
    }

    def soundSearch = {
        def result = biocacheService.getSoundsForTaxon(params.s)
        render(contentType: "text/json") {
            result
        }
    }
}
