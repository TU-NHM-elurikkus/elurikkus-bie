package au.org.ala.bie
import grails.converters.JSON
import org.codehaus.groovy.grails.web.json.JSONObject

import javax.annotation.PostConstruct


class BieService {

    def webService
    def grailsApplication

    String BIE_SERVICE_BACKEND_URL, LISTS_BACKEND_URL

    @PostConstruct
    def init() {
        BIE_SERVICE_BACKEND_URL = grailsApplication.config.bieService.internal.url
        LISTS_BACKEND_URL = grailsApplication.config.lists.internal.url
    }

    def searchBie(SearchRequestParamsDTO requestObj) {

        def queryUrl = "${BIE_SERVICE_BACKEND_URL}/search?${requestObj.getQueryString()}&facets=${grailsApplication.config.facets}&q.op=OR"
        // add a query context for BIE - to reduce taxa to a subset
        if(grailsApplication.config.bieService.queryContext){
            queryUrl = queryUrl + "&" + URLEncoder.encode(grailsApplication.config.bieService.queryContext, "UTF-8")
        }

        // add a query context for biocache - this will influence record counts
        if(grailsApplication.config.biocacheService.queryContext) {
            queryUrl = queryUrl + "&bqc=" + grailsApplication.config.biocacheService.queryContext
        }

        def json = webService.get(queryUrl)
        JSON.parse(json)
    }

    def getSpeciesList(guid) {
        if(!guid){
            return null
        }
        try {
            def url = "${LISTS_BACKEND_URL}/ws/species/${guid.replaceAll(/\s+/,'+')}?isBIE=true"
            def json = webService.get(url, true)
            return JSON.parse(json)
        } catch(Exception e) {
            // handles the situation where timeout exceptions etc occur.
            log.error("Error retrieving species list.", e)
            return []
        }
    }

    def getTaxonConcept(guid) {
        if (!guid && guid != "undefined") {
            return null
        }

        def json = webService.get("${BIE_SERVICE_BACKEND_URL}/taxon/${guid.replaceAll(/\s+/,'+')}")

        try{
            JSON.parse(json)
        } catch (Exception e){
            log.warn "Problem retrieving information for Taxon: " + guid
            null
        }
    }

    def getClassificationForGuid(guid) {
        def url = "${BIE_SERVICE_BACKEND_URL}/classification/${guid.replaceAll(/\s+/,'+')}"
        def json = webService.getJson(url)

        if (json instanceof JSONObject && json.has("error")) {
            log.warn "classification request error: " + json.error
            return [:]
        } else {
            return json
        }
    }

    def getChildConceptsForGuid(guid) {
        def url = "${BIE_SERVICE_BACKEND_URL}/childConcepts/${guid.replaceAll(/\s+/,'+')}"

        if(grailsApplication.config.bieService.queryContext){
            url = url + "?" + URLEncoder.encode(grailsApplication.config.bieService.queryContext, "UTF-8")
        }

        def json = webService.getJson(url).sort() { it.rankID?:0 }

        if (json instanceof JSONObject && json.has("error")) {
            log.warn "child concepts request error: " + json.error
            return [:]
        } else {
            return json
        }
    }
}
