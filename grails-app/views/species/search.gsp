<%@ page import="au.org.ala.BieTagLib" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<g:set var="biocacheUrl" value="${grailsApplication.config.occurrences.ui.url}" />

<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="${grailsApplication.config.skin.layout}" />
        <g:set var="searchQuery" value="${!searchResults?.queryTitle || searchResults.queryTitle == 'all records' ? message(code: 'search.query.allRecords') : searchResults.queryTitle}" />

        <title>
            <g:message code="index.body.title" />
        </title>

        <asset:stylesheet src="search.css" />
        <asset:javascript src="search.js" />

        <g:javascript>
            // global var to pass GSP vars into JS file
            var SEARCH_CONF = {
                query: "${BieTagLib.escapeJS(query)}",
                bieUrl: "${grailsApplication.config.bie.ui.url}",
                biocacheUrl: "${biocacheUrl}",
                biocacheServicesUrl: "${grailsApplication.config.biocacheService.ui.url}",
                biocacheQueryContext: "${grailsApplication.config.biocacheService.queryContext}",
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
                    <a class="page-header-links__link" href="${request.contextPath}/species/674802#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Animalia" />
                    </a>
                    <a class="page-header-links__link" href="${request.contextPath}/species/191045#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Bacteria" />
                    </a>
                    <a class="page-header-links__link" href="${request.contextPath}/species/191044#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Chromista" />
                    </a>
                    <a class="page-header-links__link" href="${request.contextPath}/species/118934#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Fungi" />
                    </a>
                    <a class="page-header-links__link" href="${request.contextPath}/species/674814#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Plantae" />
                    </a>
                    <a class="page-header-links__link" href="${request.contextPath}/species/191531#classification">
                        <span class="fa fa-sitemap"></span>
                        <g:message code="search.header.kingdom.Protista" />
                    </a>
                </div>
            </div>

            <div class="search-section">
                <g:render template="searchBox" />
                <p>
                    <g:message code="search.results.overview" args="${[searchQuery, formatNumber(number: searchResults?.totalRecords ? searchResults.totalRecords : 0)] }" />
                </p>

                <g:if test="${facetMap}">
                    <g:render template="activeFilters" />
                </g:if>
            </div>

            <g:if test="${searchResults?.totalRecords}">
                <g:set var="paramsValues" value="${[:]}" />

                <%-- Buttons --%>
                <div class="filters-control-row">
                    <div class="filters-control-col order-sm-2">
                        <a
                            id="view-records-btn"
                            class="erk-button erk-button-link erk-button--dark"
                            href=""
                            title="${message(code: 'general.btn.viewRecords')}"
                            style="display: none;"
                        >
                            <span class="fa fa-list"></span>
                            <g:message code="general.btn.viewRecords" />
                        </a>
                    </div>

                    <div class="filters-control-col">
                        <button type="button" onclick="filtersContainer.toggle()" class="filters-container-btn">
                            <span class="fa fa-filter"></span>
                            <g:message code="search.facets.refine" />
                        </button>
                    </div>
                </div>

                <div class="row results-row">
                    <%-- Refine filters --%>
                    <div id="filters-container" class="filters-container filters-container--collapsed">
                        <div id="filters-card" class="card card-body">
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

                                <%-- facets --%>
                                <g:each var="facetResult" in="${searchResults.facetResults}">
                                    <div id="facet-${facetResult.fieldName}" class="search-facet">
                                        <h4 class="search-facet__header">
                                            <g:message code="facet.${facetResult.fieldName}" default="${facetResult.fieldName}" />
                                        </h4>

                                        <g:if test="${!facetMap?.get(facetResult.fieldName) && !filterQuery?.contains(facetResult.fieldResult?.opt(0)?.label) && !facetResult.fieldName?.contains('idxtype1') && facetResult.fieldResult.length() > 0 }">
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
                                                            <a href="?${request.queryString}&fq=${facetResult.fieldName}:${fieldResult.label}">
                                                                <span class="fa fa-square-o"></span>

                                                                <g:if test="${facetResult.fieldName == 'rank'}">
                                                                    <g:message code="taxonomy.rank.${bie.formatI18nKey(value: fieldResult.label)}" />
                                                                </g:if>
                                                                <g:else>
                                                                    <g:message code="${facetResult.fieldName}.${bie.formatI18nKey(value: fieldResult.label)}" default="${fieldResult.label?:"[unknown]"}" />
                                                                </g:else>

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
                                        </g:if>
                                    </div>
                                </g:each>
                            </div>
                        </div>
                    </div>


                    <%-- Search results --%>
                    <div class="results-container">
                        <div id="search-results-panel" class="card card-body">
                            <div class="search-header">
                                <g:if test="${idxTypes.contains("TAXON")}">
                                    <g:set var="downloadUrl" value="${grailsApplication.config.bieService.ui.url}/download?${request.queryString?:''}${grailsApplication.config.bieService.queryContext}" />

                                    <%-- XXX XXX XXX --%>
                                    <a
                                        class="erk-button erk-button--light erk-button-link float-left"
                                        href="${downloadUrl}"
                                        title="${message(code: 'search.download.link.title')}"
                                    >
                                        <span class="fa fa-download"></span>
                                        <g:message code="general.btn.download.label" />
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

                            <div class="search-results list-unstyled">
                                <g:each var="result" in="${searchResults.results}">
                                    <g:set var="speciesPageLink">${request.contextPath}/species/${result.guid}#overview</g:set>

                                    <div class="search-result">
                                        <div>
                                            <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                                <div class="search-result__header">
                                                    <g:message code="taxonomy.rank.${result.rank}" default="${result.rank}"/>:

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
                                                            <g:message code="taxonomy.rank.${fieldToDisplay}" />:
                                                            ${result."${fieldToDisplay}"}
                                                        </div>
                                                    </g:if>
                                                </g:each>
                                            </g:if>

                                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'COMMON'}">
                                                <div class="search-result__header">
                                                    <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:

                                                    <a href="${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}">
                                                        ${result.name}
                                                    </a>
                                                </div>
                                            </g:elseif>

                                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'IDENTIFIER'}">
                                                <div class="search-result__header">
                                                    <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                    <a href="${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}">
                                                        ${result.guid}
                                                    </a>
                                                </div>
                                            </g:elseif>

                                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'REGION'}">
                                                <div class="search-result__header">
                                                    <g:message code="idxtype.${result.idxtype}" default="${result.idxtype}" />:
                                                    <a href="${grailsApplication.config.regions.ui.url}/feature/${result.guid}">
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

                                                    %{-- We don't use Spatial Portal. Remove this block entirely? --}%
                                                    <a href="${grailsApplication.config.spatial.ui.url}?layers=${result.guid}">
                                                        ${result.name}
                                                    </a>
                                                </div>

                                                <g:if test="${result.dataProviderName}">
                                                    <div class="search-result__extra-field">
                                                        <g:message code="show.names.field.source" />: ${result.dataProviderName}
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
                                                    <a href="${speciesPageLink}">
                                                        ${result.name}
                                                    </a>
                                                </div>
                                            </g:else>

                                            <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                                <g:if test="${grailsApplication.config.occurrenceCounts.enabled.toBoolean() && result?.occurrenceCount?:0 > 0}">
                                                    <div class="search-result__view-records">
                                                        <a href="${biocacheUrl}/occurrences/search?q=lsid:${result.guid}">
                                                            <span class="fa fa-list"></span>
                                                            <g:message code="general.btn.viewRecords" />
                                                            (<g:formatNumber number="${result.occurrenceCount}" />)
                                                        </a>
                                                    </div>
                                                </g:if>
                                            </g:if>

                                        </div>

                                        <g:if test="${result.image}">
                                            <div class="result-thumbnail">
                                                <a href="${speciesPageLink}">
                                                    <img src="${result.thumbnailUrl}" alt="">
                                                </a>
                                            </div>
                                        </g:if>
                                    </div>
                                </g:each>
                            </div>

                            <div>
                                <g:paginate
                                    mapping="search"
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
            <g:elseif test="${errors}">
                <div class="row">
                    <div class="col erk-text erk-text--error">
                        <g:message code="search.errorMsg" />
                    </div>
                </div>
            </g:elseif>
        </div>
    </body>
</html>
