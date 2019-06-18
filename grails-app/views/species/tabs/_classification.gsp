<section class="tab-pane" id="tab-classification" role="tabpanel">
    <h3>
        <g:if test="${grailsApplication.config.classificationSupplier}">
            <g:message
                code="show.classification.field.classificationSupplier"
                args="${[grailsApplication.config.classificationSupplier]}"
            />
        </g:if>
        <g:else>
            <g:message code="show.classification.title" />
        </g:else>
    </h3>
    <div>
        <g:message code="show.classification.updatedAt" /> 2019-03-08
    </div>

    <g:if test="${tc.taxonConcept.rankID < 7000}">
        <div class="col classification-actions">
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
                    href="${createLink(mapping: 'search')}?q=${tc.taxonConcept.rankString + 'ID_s:' + tc.taxonConcept.guid}"
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
        <div class="col">
            <g:each in="${taxonHierarchy}" var="taxon">
                <%-- if not current taxon --%>
                <g:if test="${taxon.guid != tc.taxonConcept.guid}">
                    <%-- XXX Intentional unclosed tag. --%>
                    <dl>
                        <dt>
                            <g:message code="taxonomy.rank.${taxon.rank?.replaceAll('[\\W]_', '')}" default="${taxon.rank}" />
                        </dt>

                        <dd>
                            <a
                                href="${request?.contextPath}/species/${taxon.guid}#classification"
                                title="${message(code: 'taxonomy.rank.' + taxon.rank, default: taxon.rank)}"
                            >
                                <g:render
                                    template="tabs/classification-taxon"
                                    model="['taxon': taxon, 'name': taxon.scientificName]" />
                            </a>
                        </dd>
                    <%-- XXX The dl is left open on purpose --%>
                </g:if>
                <g:else>
                    <%-- XXX Intentional unclosed tag. --%>
                    <dl>
                        <dt id="currentTaxonConcept">
                            <g:message code="taxonomy.rank.${taxon.rank?.replaceAll('[\\W]_', '')}" default="${taxon.rank}" />
                        </dt>

                        <dd>
                            <span>
                                <g:render
                                    template="tabs/classification-taxon"
                                    model="['taxon': taxon, 'name': taxon.scientificName]" />
                            </span>
                        </dd>
                    <%-- XXX The dl is left open on purpose --%>
                </g:else>
            </g:each>

            <dl class="child-taxa">
                <g:each in="${childConcepts}" var="child" status="i">
                    <dt>
                        <g:message code="taxonomy.rank.${child.rank?.replaceAll('[\\W]_', '')}" default="${child.rank}" />
                    </dt>

                    <g:set var="taxonLabel">
                        <%-- Yep, rendering template to prepare value for assignment... --%>
                        <g:render
                            template="tabs/classification-taxon"
                            model="['taxon': child, 'name': child.name ]" />
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
