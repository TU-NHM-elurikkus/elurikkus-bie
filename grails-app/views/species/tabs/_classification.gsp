<section class="tab-pane" id="classification" role="tabpanel">
    <h2>
        <g:if test="${grailsApplication.config.classificationSupplier}">
            <g:message
                code="show.classification.field.classificationSupplier"
                args="${[grailsApplication.config.classificationSupplier]}"
            />
        </g:if>
        <g:else>
            <g:message code="show.classification.title" />
        </g:else>
    </h2>

    <g:if test="${tc.taxonConcept.rankID < 7000}">
        <div class="col-sm-6 col-xs-12 classification-actions">
            <div class="page-header-links">
                <g:set var="taxonName">
                    <bie:formatSciName
                        rankId="${tc.taxonConcept.rankID}"
                        name="${tc.taxonConcept.nameString}"
                        simpleName="${true}"
                    />
                </g:set>

                <a
                    href="${grailsApplication.config.bie.index.url}/download?q=rkid_${tc.taxonConcept.rankString}:${tc.taxonConcept.guid}&${grailsApplication.config.bieService.queryContext}"
                    class="page-header-links__link"
                >
                    <span class="fa fa-download"></span>
                    <g:message
                        code="show.classification.btn.download.childTaxa"
                        args="${[taxonName]}"
                    />
                </a>

                <a
                    href="${grailsApplication.config.bie.index.url}/download?q=rkid_${tc.taxonConcept.rankString}:${tc.taxonConcept.guid}&fq=rank:species&${grailsApplication.config.bieService.queryContext}"
                    class="page-header-links__link"
                >
                    <span class="fa fa-download"></span>
                    <g:message
                        code="show.classification.btn.download.species"
                        args="${[tc.taxonConcept.nameString]}"
                    />
                </a>

                <a
                    href="${createLink(controller: 'species', action: 'search')}?q=${'rkid_' + tc.taxonConcept.rankString + ':' + tc.taxonConcept.guid}"
                    class="page-header-links__link"
                >
                    <span class="fa fa-search"></span>
                    <g:message
                        code="show.classification.btn.search.childTaxa"
                        args="${[tc.taxonConcept.nameString]}"
                    />
                </a>
            </div>
        </div>
    </g:if>

    <div class="row">
        <div class="col-sm-6 col-xs-12">
            <g:each in="${taxonHierarchy}" var="taxon">
                <!-- taxon = ${taxon} -->
                <g:if test="${taxon.guid != tc.taxonConcept.guid}">
                    <%-- XXX Intentional unclosed tag. --%>
                    <dl>
                        <dt>
                            <g:if test="${taxon.rankID ?: 0 != 0}">
                                ${taxon.rank}
                            </g:if>
                        </dt>

                        <dd>
                            <a
                                href="${request?.contextPath}/species/${taxon.guid}#classification"
                                title="${message(code: 'rank.' + taxon.rank, default: taxon.rank)}"
                            >
                                <bie:formatSciName
                                    rankId="${taxon.rankID}"
                                    name="${taxon.scientificName}"
                                    simpleName="${true}"
                                />

                                <g:if test="${taxon.commonNameSingle}">
                                    : ${taxon.commonNameSingle}
                                </g:if>
                            </a>
                        </dd>
                    <%-- XXX The dl is left open on purpose --%>
                </g:if>
                <g:else>
                    <%-- XXX Intentional unclosed tag. --%>
                    <dl>
                        <dt id="currentTaxonConcept">
                            ${taxon.rank}
                        </dt>

                        <dd>
                            <span>
                                <bie:formatSciName
                                    rankId="${taxon.rankID}"
                                    name="${taxon.scientificName}"
                                    simpleName="${true}"
                                />

                                <g:if test="${taxon.commonNameSingle}">
                                    : ${taxon.commonNameSingle}
                                </g:if>
                            </span>
                        </dd>
                    <%-- XXX The dl is left open on purpose --%>
                </g:else>
            </g:each>

            <dl class="child-taxa">
                <g:each in="${childConcepts}" var="child" status="i">
                    <dt>
                        ${child.rank}
                    </dt>

                    <g:set var="taxonLabel">
                        <bie:formatSciName
                            rankId="${child.rankID}"
                            name="${child.name}"
                            simpleName="${true}"
                        />
                        <g:if test="${child.commonNameSingle}">
                            : ${child.commonNameSingle}
                        </g:if>
                    </g:set>

                    <dd>
                        <a href="${request?.contextPath}/species/${child.guid}#classification">
                            ${raw(taxonLabel.trim())}
                        </a>
                    </dd>
                </g:each>
            </dl>

            <%-- XXX Close tags previously left open. --%>
            <g:each in="${taxonHierarchy}" var="taxon">
                </dl>
            </g:each>
        </div>
    </div>
</section>
