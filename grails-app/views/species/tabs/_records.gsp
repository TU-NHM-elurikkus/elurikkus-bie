<section class="tab-pane" id="tab-records" role="tabpanel">
    <div id="occurrenceRecords">
        <div id="recordBreakdowns">
            <h3>
                <g:message code="show.records.chart.title" />
                <g:message code="show.records.recordCount.title" />
            </h3>

            <%-- This is not page header but we can use its classes to lay out links in the same way. --%>
            <div class="page-header-links">
                <a
                    href="${biocacheUrl}/occurrences/search?q=lsid:${tc?.taxonConcept?.guid ?: ''}#tab-records"
                    class="page-header-links__link"
                >
                    <span class="fa fa-list"></span>
                    <g:message code="general.btn.viewRecords" />
                    <g:message code="show.records.recordCount.title" />
                </a>

                <a
                    href="${biocacheUrl}/occurrences/search?q=lsid:${tc?.taxonConcept?.guid ?: ''}#tab-map"
                    class="page-header-links__link"
                >
                    <span class="fa fa-map-o" aria-hidden="true"></span>
                    <g:message code="show.overview.map.btn.viewMap" />
                    <g:message code="show.records.recordCount.title" />
                </a>
            </div>

            <div id="charts"></div>
        </div>
    </div>
</section>
