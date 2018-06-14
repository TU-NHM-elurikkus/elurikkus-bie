package au.org.ala.bie

import grails.converters.deep.JSON
import groovy.json.JsonSlurper
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

    def geoSearch = {

        def searchResults = []
        try {
            def googleMapsKey = grailsApplication.config.googleMapsApiKey
            def url = "https://maps.googleapis.com/maps/api/geocode/json?key=${googleMapsKey}&address=" +
                URLEncoder.encode(params.q, "UTF-8")
            def response = new URL(url).text
            def js = new JsonSlurper()
            def json = js.parseText(response)

            if (json.results) {
                json.results.each {
                    searchResults << [
                        name: it.formatted_address,
                        latitude: it.geometry.location.lat,
                        longitude: it.geometry.location.lng
                    ]
                }
            }
        } catch (Exception e) {
            log.error(e.getMessage(), e)
        }

        render searchResults as JSON
    }

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

        if (searchResults instanceof JSONObject && searchResults.has("error")) {
            log.error "TaxonConcept get Error: ${searchResults.error} | params: ${params} | ${searchResults.error}"
            render(view: "../error", model: [message: searchResults.error])
        } else {
            render(view: "search", model: [
                searchResults: searchResults?.searchResults,
                facetMap: utilityService.addFacetMap(filterQuery),
                query: query?.trim(),
                filterQuery: filterQuery,
                idxTypes: utilityService.getIdxtypes(searchResults?.searchResults?.facetResults),
                collectionsMap: utilityService.addFqUidMap(filterQuery)
            ])
        }
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
                log.info("TaxonConcept get Error: ${guid} | params: ${params} | ${taxonDetails.error}")
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
