<%@ page import="au.org.ala.BieTagLib" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<g:set var="biocacheUrl" value="${grailsApplication.config.biocache.baseURL}" />

<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="${grailsApplication.config.skin.layout}" />
        <g:set var="searchQuery" value="${!searchResults.queryTitle || searchResults.queryTitle == '*:*' ? message(code: 'search.query.allRecords') : searchResults.queryTitle}" />
        <title>
            <g:message code="index.body.title" />
        </title>

        <g:javascript>
            // global var to pass GSP vars into JS file
            var SEARCH_CONF = {
                searchResultTotal: "${searchResults.totalRecords}",
                query: "${BieTagLib.escapeJS(query)}",
                serverName: "${grailsApplication.config.grails.serverURL}",
                bieUrl: "${grailsApplication.config.bie.baseURL}",
                biocacheUrl: "${biocacheUrl}",
                biocacheServicesUrl: "${grailsApplication.config.biocacheService.baseURL}",
                bhlUrl: "${grailsApplication.config.bhl.baseURL}",
                biocacheQueryContext: "${grailsApplication.config.biocacheService.queryContext}",
                geocodeLookupQuerySuffix: "${grailsApplication.config.geocode.querySuffix}"
            }
        </g:javascript>
    </head>

    <body>
        <div id="main-content">
            <div id="listHeader" class="page-header">
                <h1 class="page-header__title">
                    <g:message code="index.body.title" />
                </h1>

                <div class="page-header__subtitle">
                    <g:message code="search.body.subTitle" />
                </div>

                <div class="page-header-links">
                    <div id="related-searches" class="related-searches"></div>
                </div>
            </div>

            <section class="search-section">
                <g:render template="searchBox" />
                <p>
                    <g:message code="search.results.overview" args="${[searchQuery, formatNumber(number: searchResults.totalRecords)] }" />
                </p>

                <g:if test="${facetMap}">
                    <g:render template="activeFilters" />
                </g:if>
            </section>

            <g:if test="${searchResults.totalRecords}">
                <g:set var="paramsValues" value="${[:]}" />

                <div class="vertical-block">
                    <span class="fa fa-info-circle"></span>
                    <g:message code="search.facets.refine" />
                </div>

                <div class="row">
                    <div class="col-md-3">
                        <div class="card card-body filters-container">
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
                                        <div id="facet-${facetResult.fieldName}" class="search-facet">
                                            <h4 class="search-facet__header">
                                                <g:message code="facet.${facetResult.fieldName}" default="${facetResult.fieldName}" />
                                            </h4>

                                            <ul id="facet-${facetResult.fieldName}-list" class="search-facet__values list-unstyled">
                                                <g:set var="lastElement" value="${facetResult.fieldResult?.get(facetResult.fieldResult.length() - 1)}" />

                                                <g:if test="${lastElement.label == 'before'}">
                                                    <li class="search-facet__value">
                                                        <g:set var="firstYear" value="${facetResult.fieldResult?.opt(0)?.label.substring(0, 4)}" />

                                                        <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[* TO ${facetResult.fieldResult.opt(0)?.label}]">
                                                            <span class="fa fa-square-o"></span>
                                                            <g:message code="search.facets.beforeYear" args="${[firstYear]}" />
                                                            (<g:formatNumber number="${lastElement.count}" />)
                                                        </a>
                                                    </li>
                                                </g:if>

                                                <g:each var="fieldResult" in="${facetResult.fieldResult}" status="vs">
                                                    <g:set var="dateRangeTo">
                                                        <g:if test="${vs == lastElement}">
                                                            *
                                                        </g:if>
                                                        <g:else>
                                                            ${facetResult.fieldResult[vs + 1]?.label}
                                                        </g:else>
                                                    </g:set>

                                                    <g:if test="${facetResult.fieldName?.contains("occurrence_date") && fieldResult.label?.endsWith("Z")}">
                                                        <li class="search-facet__value ${vs > 4 ? 'collapse' : ''}">
                                                            <g:set var="startYear" value="${fieldResult.label?.substring(0, 4)}" />

                                                            <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[${fieldResult.label} TO ${dateRangeTo}]">
                                                                <span class="fa fa-square-o"></span>
                                                                ${startYear} - ${startYear + 10}
                                                                (<g:formatNumber number="${fieldResult.count}" />)
                                                            </a>
                                                        </li>
                                                    </g:if>

                                                    <g:elseif test="${fieldResult.label?.endsWith("before")}">
                                                        <%-- skip --%>
                                                    </g:elseif>

                                                    <g:elseif test="${fieldResult.label?.isEmpty()}"></g:elseif>

                                                    <g:else>
                                                        <li class="search-facet__value ${vs > 4 ? 'collapse' : ''}">
                                                            <a href="?${request.queryString}&fq=${facetResult.fieldName}:%22${fieldResult.label}%22">
                                                                <span class="fa fa-square-o"></span>
                                                                <g:message code="${facetResult.fieldName}.${fieldResult.label}" default="${fieldResult.label?:"[unknown]"}" />
                                                                (<g:formatNumber number="${fieldResult.count}" />)
                                                            </a>
                                                        </li>
                                                    </g:else>
                                                </g:each>
                                            </ul>

                                            <g:if test="${facetResult.fieldResult.size() > 5}">
                                                <ul class="list-unstyled">
                                                    <a
                                                        class="expand-options"
                                                        href="#facet-${facetResult.fieldName}-list .collapse"
                                                        data-toggle="collapse"
                                                    >
                                                        <g:message code="search.facets.showMore" />
                                                    </a>
                                                </ul>
                                            </g:if>
                                        </div>
                                    </g:if>
                                </g:each>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-9">
                        <div id="search-results-panel" class="card card-body">
                            <div>
                                <g:if test="${idxTypes.contains("TAXON")}">
                                    <g:set var="downloadUrl" value="${grailsApplication.config.bie.index.url}/download?${request.queryString?:''}${grailsApplication.config.bieService.queryContext}" />

                                    <%-- XXX XXX XXX --%>
                                    <a class="download-button float-left" href="${downloadUrl}" title="Download a list of taxa for your search">
                                        <button class="erk-button erk-button--light">
                                            <span class="fa fa-download"></span>
                                            <g:message code="general.btn.download" />
                                        </button>
                                    </a>
                                </g:if>

                                <div class="inline-controls inline-controls--right">
                                    <div class="inline-controls__group">
                                        <label for="per-page">
                                            <g:message code="search.controls.pageSize" />
                                        </label>
                                        <g:set var="pageSize" value="${params.rows ? params.rows : 25}" />
                                        <g:select
                                            id="per-page"
                                            name="per-page"
                                            value="${pageSize}"
                                            from="${[10, 25, 50, 100]}"
                                        />
                                    </div>

                                    <div class="inline-controls__group">
                                        <label for="sort-by">
                                            <g:message code="search.controls.sortBy.label" />
                                        </label>

                                        <g:select
                                            id="sort-by"
                                            name="sort-by"
                                            value="${params.sortField}"
                                            from="${['score', 'scientificName', 'commonNameSingle', 'rank']}"
                                            optionValue="${{opt -> message(code: "search.controls.sortBy.${opt}")}}"
                                        />

                                    </div>

                                    <div class="inline-controls__group">
                                        <label for="sort-order">
                                            <g:message code="search.controls.sortOrder.label" />
                                        </label>

                                        <g:select
                                            id="sort-order"
                                            name="sort-order"
                                            value="${params.dir}"
                                            from="${['asc', 'desc']}"
                                            optionValue="${{opt -> message(code: "search.controls.sortOrder.${opt}")}}"
                                        >
                                        </g:select>
                                    </div>
                                </div>
                            </div>

                            <input type="hidden" value="${pageTitle}" name="title" />

                            <ol class="search-results list-unstyled">
                                <g:each var="result" in="${searchResults.results}">
                                    <li class="search-result clearfix">
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

                                            <div class="search-result__header">
                                                <g:message code="taxonomy.rank.${result.rank}" />:

                                                <a href="${speciesPageLink}">
                                                    <span class="fa fa-tag"></span>
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
                                                        |&nbsp;${result.commonNameSingle}
                                                    </span>
                                                </g:if>
                                            </div>

                                            <g:if test="${result.commonName != result.commonNameSingle}">
                                                <div class="search-result__all-common-names">
                                                    ${result.commonName}
                                                </div>
                                            </g:if>

                                            <g:each var="fieldToDisplay" in="${grailsApplication.config.additionalResultsFields.split(",")}">
                                                <g:if test='${result."${fieldToDisplay}"}'>
                                                    <div class="search-result__extra-field">
                                                        <g:message code="${fieldToDisplay}" default="${fieldToDisplay}" />:
                                                        ${result."${fieldToDisplay}"}
                                                    </div>
                                                </g:if>
                                            </g:each>
                                        </g:if>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'COMMON'}">
                                            <g:set var="speciesPageLink">
                                                ${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}
                                            </g:set>

                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                <a href="${speciesPageLink}">
                                                    ${result.name}
                                                </a>
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'IDENTIFIER'}">
                                            <g:set var="speciesPageLink">
                                                ${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}
                                            </g:set>

                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                <a href="${speciesPageLink}">
                                                    ${result.guid}
                                                </a>
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'REGION'}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                <a href="${grailsApplication.config.regions.baseURL}/feature/${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <div class="search-result__description">
                                                ${result?.description && result?.description != result?.name ? result?.description : ""}
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'LOCALITY'}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                <bie:constructEYALink result="${result}">
                                                    ${result.name}
                                                </bie:constructEYALink>
                                            </div>

                                            <div class="search-result__description">
                                                ${result?.description?:""}
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("idxtype") && result.idxtype == 'LAYER'}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${grailsApplication.config.spatial.baseURL}?layers=${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <g:if test="${result.dataProviderName}">
                                                <div class="search-result__extra-field">
                                                    <g:message code="search.resultList.field.source" />: ${result.dataProviderName}
                                                </div>
                                            </g:if>
                                        </g:elseif>

                                        <g:elseif test="${result.has("name")}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <div class="search-result__description">
                                                ${result?.description?:""}
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("acronym") && result.get("acronym")}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <div class="search-result__description">
                                                ${result.acronym}
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("description") && result.get("description")}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <div class="search-result__description">
                                                ${result.description?.trimLength(500)}
                                            </div>
                                        </g:elseif>

                                        <g:elseif test="${result.has("highlight") && result.get("highlight")}">
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" />:

                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>

                                            <div class="search-result__dscription">
                                                ${result.highlight}
                                            </div>
                                        </g:elseif>

                                        <g:else>
                                            <div class="search-result__header">
                                                <g:message code="idxtype.${result.idxtype}" /> TEST:
                                                <a href="${result.guid}">
                                                    ${result.name}
                                                </a>
                                            </div>
                                        </g:else>

                                        <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                            <g:if test="${grailsApplication.config.occurrenceCounts.enabled.toBoolean() && result?.occurrenceCount?:0 > 0}">
                                                <div class="search-result__view-records">
                                                    <a href="${biocacheUrl}/occurrences/search?q=lsid:${result.guid}">
                                                        <span class="fa fa-list"></span>
                                                        <g:message code="show.map.btn.viewRecords" />
                                                        (<g:formatNumber number="${result.occurrenceCount}" />)
                                                    </a>
                                                </div>
                                            </g:if>
                                        </g:if>
                                    </li>
                                </g:each>
                            </ol>

                            <div>
                                <g:paginate
                                    action="search"
                                    omitLast="true"
                                    params="${[q: params.q, fq: params.fq, sortField: params.sortField, dir: params.dir, rows: params.rows ? params.rows : 25]}"
                                    total="${searchResults?.totalRecords}"
                                    next="${message(code: 'search.controls.paginate.next')}"
                                    prev="${message(code: 'search.controls.paginate.prev')}&nbsp;"
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
                <ol class="search-results list-unstyled">
                    <li class="search-result clearfix">
                        <h4>
                            <g:message code="idxtype.LOCALITY" /> :

                            <a class="exploreYourAreaLink" href="">
                                <g:message code="search.areaSearch.label" />
                            </a>
                        </h4>
                    </li>
                </ol>
            </div>
        </div>

        <g:if test="${searchResults.totalRecords == 0}">
            <script>
                $(function() {
                    $.get(SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query  + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix, function(searchResults) {
                        for(var i=0; i < searchResults.length; i++) {
                            var $results = $('#result-template').clone(true);

                            $results.attr('id', 'results-lists');
                            $results.removeClass('hidden-node');

                            if(searchResults.length > 0) {
                                $results.find('.exploreYourAreaLink').html(searchResults[i].name);
                                $results.find('.exploreYourAreaLink').attr('href',
                                    '${grailsApplication.config.biocache.baseURL}/explore/your-area#' +
                                    searchResults[0].latitude +
                                    '|' + searchResults[0].longitude +
                                    '|12|ALL_SPECIES'
                                );
                                $('#search-results-panel').append($results.html());
                            }
                        }
                    });
                });
            </script>
        </g:if>
    </body>
</html>
