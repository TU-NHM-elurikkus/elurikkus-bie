<section class="tab-pane active" id="tab-overview" role="tabpanel">
    <div class="row taxon-row">
        <div class="col-12 col-md-5">

            <%-- Gallery --%>
            <div class="taxon-summary-gallery hidden-node">
                <div class="main-img">
                    <a
                        class="lightbox-img"
                        data-toggle="lightbox"
                        data-gallery="taxon-summary-gallery"
                        data-parent=".taxon-summary-gallery"
                    >
                        <img class="mainOverviewImage img-responsive" src="" />
                        <div class="gallery-thumb__footer mainOverviewImageInfo"></div>
                    </a>

                </div>

                <div class="thumb-row">
                    <div id="overview-thumbs"></div>

                    <div id="more-photo-thumb-link" class="taxon-summary-thumb">
                        <a
                            class="more-photos tab-link"
                            href="#gallery"
                            title="${message(code: 'show.overview.showMore')}"
                            onclick="openTab('#tab-gallery')"
                        >
                           <span>
                               +
                           </span>
                        </a>
                    </div>
                </div>
            </div>

            <%-- Sounds --%>
            <div id="sounds"></div>

            <%-- Conservation Info --%>
            <g:if test="${tc.conservationStatuses}">
                <div class="card">
                    <div class="card-header">
                        <h3>
                            <g:message code="show.overview.conservationStatus" />
                        </h3>
                    </div>

                    <div class="card-body">
                        <ul class="conservationList">
                            <g:each in="${tc.conservationStatuses.entrySet().sort { it.key }}" var="cs">
                                <li>
                                    <g:if test="${cs.value.dr}">
                                        <a href="${collectoryUrl}/public/show/${cs.value.dr}">
                                            <span class="iucn <bie:colourForStatus status="${cs.value.status}" />">
                                                ${cs.key}
                                            </span>

                                            ${cs.value.status}
                                        </a>
                                    </g:if>
                                    <g:else>
                                        <span class="iucn <bie:colourForStatus status="${cs.value.status}" />">
                                            ${cs.key}
                                        </span>

                                        ${cs.value.status}
                                    </g:else>
                                </li>
                            </g:each>
                        </ul>
                    </div>
                </div>
            </g:if>

            <%-- Dynamic descriptions --%>
            <div id="descriptiveContent"></div>

            <%-- Online resources --%>
            <div class="card bie-card">
                <div class="card-header">
                    <h3>
                        <g:message code="show.overview.onlineResources" />
                    </h3>
                </div>

                <div class="card-body">
                    <g:render template="onlineResources" plugin="bie-plugin" />
                </div>
            </div>
        </div>

        <div class="col">
            <div id="expertDistroDiv" style="display:none;margin-bottom: 20px;">
                <h3>
                    <g:message code="show.map.distroMap.title" />
                </h3>

                <img
                    id="distroMapImage"
                    src="${resource(dir: 'images', file: 'noImage.jpg')}"
                    class="distroImg"
                    style="width:316px;"
                    alt="occurrence map"
                    onerror="this.style.display='none'"
                />

                <p class="mapAttribution">
                    <g:message code="show.map.distroMap.providedBy" />

                    <span id="dataResource">
                        [<g:message code="show.map.distroMap.dataResource.unknown" />]
                    </span>
                </p>
            </div>

            <div class="taxon-map">
                <h3>
                    <g:message code="show.overview.occurrencesMap.title" />
                    (<span class="occurrenceRecordCount">0</span>
                    <g:message code="show.overview.occurrencesMap.nrRecords" />)
                </h3>

                <div id="leafletMap"></div>

                <g:set
                    var="recordSearchUrl"
                    value="${biocacheUrl}/occurrences/search?q=lsid:${tc?.taxonConcept?.guid}"
                />
                <div class="container-fluid">
                    <div class="row">
                        <div class="col-md-6 map-button-outer">
                            <a
                                class="btn col-md-12 erk-button--dark map-button-inner"
                                href="${recordSearchUrl}#map"
                                title="${message(code: 'show.overview.map.btn.viewMap')}"
                            >
                                <span class="fa fa-map-o" aria-hidden="true"></span>
                                <g:message code="show.overview.map.btn.viewMap" />
                            </a>
                        </div>
                        <div class="col-md-6 map-button-outer">
                            <a
                                class="btn col-md-12 erk-button--dark map-button-inner"
                                href="${recordSearchUrl}#records"
                                title="${message(code: 'general.btn.viewRecords')}"
                            >
                                <span class="fa fa-list" aria-hidden="true"></span>
                                <g:message code="general.btn.viewRecords" />
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card detached-card panel-data-providers">
                <div class="card-header">
                    <h3>
                        <g:message code="show.datasets.title" />
                    </h3>
                </div>

                <div class="card-body">
                    <p>
                        <strong>
                            <span class="datasetCount">0</span>
                        </strong>
                        <g:message code="show.overview.datasets.summary" />
                    </p>

                    <p>
                        <a class="tab-link" href="#datasets" onclick="openTab('#tab-datasets')">
                            <g:message code="show.overview.datasets.desc.01" />
                        </a>
                        <g:message code="show.overview.datasets.desc.02" />
                    </p>
                </div>
            </div>

            <div id="listContent"></div>
        </div>
    </div>
</section>
