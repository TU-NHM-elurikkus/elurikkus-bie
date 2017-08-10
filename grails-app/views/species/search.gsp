<%--
  - Copyright (C) 2012 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
--%>

<%@ page import="au.org.ala.bie.BieTagLib" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<g:set var="biocacheUrl" value="${grailsApplication.config.biocache.baseURL}" />

<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="${grailsApplication.config.skin.layout}" />
        <title>
            ${query} | Search
        </title>

        <r:require modules="searchOverride" />

        <r:script disposition='head'>
            // global var to pass GSP vars into JS file
            SEARCH_CONF = {
                searchResultTotal: ${searchResults.totalRecords},
                query: "${BieTagLib.escapeJS(query)}",
                serverName: "${grailsApplication.config.grails.serverURL}",
                bieUrl: "${grailsApplication.config.bie.baseURL}",
                biocacheUrl: "${biocacheUrl}",
                biocacheServicesUrl: "${grailsApplication.config.biocacheService.baseURL}",
                bhlUrl: "${grailsApplication.config.bhl.baseURL}",
                biocacheQueryContext: "${grailsApplication.config.biocacheService.queryContext}",
                geocodeLookupQuerySuffix: "${grailsApplication.config.geocode.querySuffix}"
            }
        </r:script>
    </head>

    <body>
        <div id="main-content">
            <div id="listHeader", class="page-header">
                <h1 class="page-header__title">
                    Search for Taxa
                </h1>

                <div class="page-header__subtitle">
                    Search for taxa in eElurikkus
                </div>

                <div class="page-header-links">
                    <div id="related-searches" class="related-searches">
                    </div>
                </div>
            </div>

            <section class="search-section">
                <g:render template="searchBox" />

                <p>
                    Search for

                    <strong>
                        ${searchResults.queryTitle == "*:*" ? 'everything' : searchResults.queryTitle}
                    </strong>

                    returned

                    <strong>
                        <g:formatNumber number="${searchResults.totalRecords}" />
                    </strong>

                    results
                </p>

                <g:if test="${facetMap}">
                    <g:render template="activeFilters" />
                </g:if>
            </section>

            <g:if test="${searchResults.totalRecords}">
                <g:set var="paramsValues" value="${[:]}" />

                <div class="row">
                    <div class="col-md-3">
                        <div class="card card-block filters-container">
                            <h2 class="card-title">
                                Refine results
                            </h2>

                            <div id="refine-options">
                                <g:if test="${query && filterQuery}">
                                    <g:set var="queryParam">q=${query.encodeAsHTML()}
                                        <g:if test="${!filterQuery.isEmpty()}">
                                            &fq=${filterQuery?.join("&fq=")}
                                        </g:if>
                                    </g:set>
                                </g:if>

                                <g:else>
                                    <g:set var="queryParam">q=${query.encodeAsHTML()}
                                        <g:if test="${params.fq}">
                                            &fq=${fqList?.join("&fq=")}
                                        </g:if>
                                    </g:set>
                                </g:else>

                                <!-- facets -->
                                <g:each var="facetResult" in="${searchResults.facetResults}">
                                    <g:if test="${!facetMap?.get(facetResult.fieldName) && !filterQuery?.contains(facetResult.fieldResult?.opt(0)?.label) && !facetResult.fieldName?.contains('idxtype1') && facetResult.fieldResult.length() > 0 }">
                                        <div class="refine-list" id="facet-${facetResult.fieldName}">
                                            <h4>
                                                <g:message code="facet.${facetResult.fieldName}" default="${facetResult.fieldName}" />
                                            </h4>

                                            <ul class="list-unstyled">
                                                <g:set var="lastElement" value="${facetResult.fieldResult?.get(facetResult.fieldResult.length()-1)}" />

                                                <g:if test="${lastElement.label == 'before'}">
                                                    <li>
                                                        <g:set var="firstYear" value="${facetResult.fieldResult?.opt(0)?.label.substring(0, 4)}" />
                                                        <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[* TO ${facetResult.fieldResult.opt(0)?.label}]">
                                                            Before ${firstYear}
                                                        </a>
                                                        (<g:formatNumber number="${lastElement.count}" />)
                                                    </li>
                                                </g:if>

                                                <g:each var="fieldResult" in="${facetResult.fieldResult}" status="vs">
                                                    <g:if test="${vs == 5}">
                                                        </ul>
                                                        <ul class="list-unstyled">  <%-- WTF --%>
                                                    </g:if>

                                                    <g:set var="dateRangeTo">
                                                        <g:if test="${vs == lastElement}">
                                                            *
                                                        </g:if>
                                                        <g:else>
                                                            ${facetResult.fieldResult[vs+1]?.label}
                                                        </g:else>
                                                    </g:set>

                                                    <g:if test="${facetResult.fieldName?.contains("occurrence_date") && fieldResult.label?.endsWith("Z")}">
                                                        <li>
                                                            <g:set var="startYear" value="${fieldResult.label?.substring(0, 4)}" />
                                                            <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[${fieldResult.label} TO ${dateRangeTo}]">
                                                                ${startYear} - ${startYear + 10}
                                                            </a>
                                                            (<g:formatNumber number="${fieldResult.count}" />)
                                                        </li>
                                                    </g:if>

                                                    <g:elseif test="${fieldResult.label?.endsWith("before")}">
                                                        <%-- skip --%>
                                                    </g:elseif>

                                                    <g:elseif test="${fieldResult.label?.isEmpty()}">
                                                    </g:elseif>

                                                    <g:else>
                                                        <li>
                                                            <a href="?${request.queryString}&fq=${facetResult.fieldName}:%22${fieldResult.label}%22">
                                                                <g:message code="${facetResult.fieldName}.${fieldResult.label}" default="${fieldResult.label?:"[unknown]"}" />
                                                            </a>
                                                            (<g:formatNumber number="${fieldResult.count}" />)
                                                        </li>
                                                    </g:else>
                                                </g:each>
                                            </ul>

                                            <g:if test="${facetResult.fieldResult.size() > 5}">
                                                <a class="expand-options" href="javascript:void(0)">
                                                    More
                                                </a>
                                            </g:if>
                                        </div>
                                    </g:if>
                                </g:each>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-9">
                        <div id="search-results" class="card card-block">
                            <div class="search-controls">
                                <g:if test="${idxTypes.contains("TAXON")}">
                                    <g:set var="downloadUrl" value="${grailsApplication.config.bie.index.url}/download?${request.queryString?:''}${grailsApplication.config.bieService.queryContext}" />

                                    <%-- XXX XXX XXX --%>
                                    <a class="download-button" href="${downloadUrl}" title="Download a list of taxa for your search">
                                        <button class="erk-button erk-button--light">
                                            <span class="fa fa-download"></span>
                                            Download
                                        </button>
                                    </a>
                                </g:if>

                                <form class="form-inline float-right">
                                    <div class="form-group">
                                        <label for="per-page">
                                            Results per page
                                        </label>

                                        <select id="per-page" name="per-page">
                                            <option value="10"}>
                                                10
                                            </option>
                                            <option value="25" selected="selected">
                                                25
                                            </option>
                                            <option value="50">
                                                50
                                            </option>
                                            <option value="100">
                                                100
                                            </option>
                                        </select>
                                    </div>

                                    <div class="form-group">
                                        <label for="sort-by">
                                            Sort by
                                        </label>

                                        <select id="sort-by" name="sort-by">
                                            <option value="score" ${(params.sortField == 'score') ? "selected=\"selected\"" : ""}>
                                                Best match
                                            </option>
                                            <option value="scientificName" ${(params.sortField == 'scientificName') ? "selected=\"selected\"" : ""}>
                                                Scientific name
                                            </option>
                                            <option value="commonNameSingle" ${(params.sortField == 'commonNameSingle') ? "selected=\"selected\"" : ""}>
                                                Common name
                                            </option>
                                            <option value="rank" ${(params.sortField == 'rank') ? "selected=\"selected\"" : ""}>
                                                Taxon rank
                                            </option>
                                        </select>
                                    </div>

                                    <div class="form-group">
                                        <label for="sort-order">
                                            Sort order
                                        </label>

                                        <select id="sort-order" name="sort-order">
                                            <option value="asc" ${(params.dir == 'asc') ? "selected=\"selected\"" : ""}>
                                                Ascending
                                            </option>
                                            <option value="desc" ${(params.dir == 'desc' || !params.dir) ? "selected=\"selected\"" : ""}>
                                                Descending
                                            </option>
                                        </select>
                                    </div>
                                </form>
                            </div>

                            <input type="hidden" value="${pageTitle}" name="title" />

                            <ol id="search-results-list" class="search-results-list list-unstyled">
                                <g:each var="result" in="${searchResults.results}">
                                    <li class="search-result clearfix">
                                        <g:set var="sectionText">
                                            <g:if test="${!facetMap.idxtype}">
                                                <%-- XXX Not sure why we have span here. --%>
                                                <span>
                                                    <b>Section:</b> <g:message code="idxType.${result.idxType}" />
                                                </span>
                                            </g:if>
                                        </g:set>

                                        <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                            <g:set var="speciesPageLink">
                                                ${request.contextPath}/species/${result.linkIdentifier?:result.guid}
                                            </g:set>

                                            <g:if test="${result.image}">
                                                <div class="result-thumbnail">
                                                    <a href="${speciesPageLink}">
                                                        <img src="${grailsApplication.config.image.thumbnailUrl}${result.image}" alt="">
                                                    </a>
                                                </div>
                                            </g:if>

                                            <h4>
                                                ${result.rank}:
                                                <a href="${speciesPageLink}">
                                                    <bie:formatSciName
                                                        rankId="${result.rankID}"
                                                        taxonomicStatus="${result.taxonomicStatus}"
                                                        nameFormatted="${result.nameFormatted}"
                                                        nameComplete="${result.nameComplete}"
                                                        name="${result.name}"
                                                        acceptedName="${result.acceptedConceptName}"
                                                    />
                                                </a>

                                                <g:if test="${result.commonNameSingle}">
                                                    <span class="commonNameSummary">
                                                        &nbsp;&ndash;&nbsp;${result.commonNameSingle}
                                                    </span>
                                                </g:if>
                                            </h4>

                                            <g:if test="${result.commonName != result.commonNameSingle}">
                                                <p class="alt-names">
                                                    ${result.commonName}
                                                </p>
                                            </g:if>

                                            <g:each var="fieldToDisplay" in="${grailsApplication.config.additionalResultsFields.split(",")}">
                                                <g:if test='${result."${fieldToDisplay}"}'>
                                                    <p class="summary-info">
                                                        <strong>
                                                            <g:message code="${fieldToDisplay}" default="${fieldToDisplay}" />:
                                                        </strong>
                                                        ${result."${fieldToDisplay}"}
                                                    </p>
                                                </g:if>
                                            </g:each>
                                        </g:if>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'COMMON'}">
                                            <g:set var="speciesPageLink">
                                            ${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}
                                        </g:set>

                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                <a href="${speciesPageLink}">
                                                    ${result.name}
                                                </a>
                                            </h4>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'IDENTIFIER'}">
                                            <g:set var="speciesPageLink">
                                                ${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}
                                            </g:set>

                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                <a href="${speciesPageLink}">
                                                    ${result.guid}
                                                </a>
                                            </h4>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'REGION'}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                <a href="${grailsApplication.config.regions.baseURL}/feature/${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <span>
                                                    ${result?.description &&  result?.description != result?.name ?  result?.description : ""}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'LOCALITY'}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                <bie:constructEYALink result="${result}">
                                                    ${result.name}
                                                </bie:constructEYALink>
                                            </h4>

                                            <p>
                                                <span>
                                                    ${result?.description?:""}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'LAYER'}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${grailsApplication.config.spatial.baseURL}?layers=${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <g:if test="${result.dataProviderName}">
                                                    <strong>
                                                        Source: ${result.dataProviderName}
                                                    </strong>
                                                </g:if>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("name")}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <span>
                                                    ${result?.description?:""}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("acronym") && result.get("acronym")}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <span>
                                                    ${result.acronym}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("description") && result.get("description")}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <span class="searchDescription">
                                                    ${result.description?.trimLength(500)}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:elseif test="${result.has("highlight") && result.get("highlight")}">
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>

                                            <p>
                                                <span>
                                                    ${result.highlight}
                                                </span>
                                            </p>
                                        </g:elseif>

                                        <g:else>
                                            <h4>
                                                <g:message code="idxtype.${result.idxtype}" /> TEST:
                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </h4>
                                        </g:else>



                                        <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                            <ul class="summary-actions list-inline">
                                                <g:if test="${result.rankID < 7000}">
                                                    <li>
                                                        <g:link controller="species" action="imageSearch" params="[id:result.guid]">
                                                            View images of species within this ${result.rank}
                                                        </g:link>
                                                    </li>
                                                </g:if>

                                                <g:if test="${grailsApplication.config.sightings.guidUrl}">
                                                    <li>
                                                        <a href="${grailsApplication.config.sightings.guidUrl}${result.guid}">
                                                            Record a sighting/share a photo
                                                        </a>
                                                    </li>
                                                </g:if>

                                                <g:if test="${grailsApplication.config.occurrenceCounts.enabled.toBoolean() && result?.occurrenceCount?:0 > 0}">
                                                    <li>
                                                        <a href="${biocacheUrl}/occurrences/search?q=lsid:${result.guid}">
                                                            Occurrences:
                                                            <g:formatNumber number="${result.occurrenceCount}" />
                                                        </a>
                                                    </li>
                                                </g:if>
                                            </ul>
                                        </g:if>
                                    </li>
                                </g:each>
                            </ol>

                            <div>
                                <tb:paginate
                                    total="${searchResults?.totalRecords}"
                                    action="search"
                                    params="${[q: params.q, fq: params.fq, dir: params.dir]}"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </g:if>
        </div>

        <%-- TODO --%>
        <div id="result-template" class="row hidden-node">
            <div class="col-sm-12">
                <ol class="search-results-list list-unstyled">
                    <li class="search-result clearfix">
                        <h4>
                            <g:message code="idxtype.LOCALITY" /> :

                            <a class="exploreYourAreaLink" href="">
                                Address here
                            </a>
                        </h4>
                    </li>
                </ol>
            </div>
        </div>

        <g:if test="${searchResults.totalRecords == 0}">
            <script>
                $(function() {
                    console.log(SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix);

                    $.get( SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query  + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix, function( searchResults ) {
                        for(var i=0; i< searchResults.length; i++) {
                            var $results = $('#result-template').clone(true);

                            $results.attr('id', 'results-lists');
                            $results.removeClass('hidden-node');
                            console.log(searchResults)

                            if(searchResults.length > 0) {
                                $results.find('.exploreYourAreaLink').html(searchResults[i].name);
                                $results.find('.exploreYourAreaLink').attr('href', '${biocacheUrl}/explore/your-area#' +
                                        searchResults[0].latitude  +
                                        '|' +  searchResults[0].longitude +
                                        '|12|ALL_SPECIES'
                                );
                                $('#search-results').append($results.html());
                            }
                        }
                    });
                });
            </script>
        </g:if>
    </body>
</html>
