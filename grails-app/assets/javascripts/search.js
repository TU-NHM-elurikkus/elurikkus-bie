var SEARCH_CONF;  // This constant is populated by search.gsp inline javascript

$(document).ready(function() {
    // set the search input to the current q param value
    if(typeof SEARCH_CONF !== 'undefined') {
        var query = SEARCH_CONF.query;

        if(query) {
            $(':input#search-2011').val(query);
        }

        // listeners for sort widgets
        $('select#sort-by').change(function() {
            var val = $('option:selected', this).val();
            reloadWithParam('sortField', val);
        });

        $('select#sort-order').change(function() {
            var val = $('option:selected', this).val();
            reloadWithParam('dir', val);
        });

        $('select#per-page').change(function() {
            var val = $('option:selected', this).val();
            reloadWithParam('rows', val);
        });

        // AJAX search results
        injectBiocacheResults();

        // in mobile view toggle display of facets
        $('#toggleFacetDisplay').click(function() {
            $(this).find('i').toggleClass('icon-chevron-down icon-chevron-right');

            if($('#accordion').is(':visible')) {
                $('#accordion').removeClass('overrideHide');
            } else {
                $('#accordion').addClass('overrideHide');
            }
        });
    }
});

/**
 * Build URL params to remove selected fq
 *
 * @param facet
 */
function removeFacet(facetIdx) {
    var q = $.getQueryParam('q') ? $.getQueryParam('q') : SEARCH_CONF.query; // $.query.get('q')[0];
    var fqList = $.getQueryParam('fq'); // $.query.get('fq');

    var paramList = [];

    if(q !== null) {
        paramList.push('q=' + q);
    }

    fqList.splice(facetIdx, 1);

    if(fqList !== null && fqList.length > 0) {
        paramList.push('fq=' + fqList.join('&fq='));
    } else {
        // empty fq so redirect doesn't happen
        paramList.push('fq=');
    }

    window.location.href = window.location.pathname + '?' + paramList.join('&');
}

function removeAllFacets() {
    var q = $.getQueryParam('q') ? $.getQueryParam('q') : SEARCH_CONF.query; // $.query.get('q')[0];
    var paramList = [];

    if(q !== null) {
        paramList.push('q=' + q);
    }

    window.location.href = window.location.pathname + '?' + paramList.join('&');
}

/**
 * Catch sort drop-down and build GET URL manually
 */
function reloadWithParam(paramName, paramValue) {
    var paramList = [];
    var q = $.getQueryParam('q');
    var fqList = $.getQueryParam('fq');
    var sort = $.getQueryParam('sortField');
    var dir = $.getQueryParam('dir');

    q = q ? q : SEARCH_CONF.query;
    dir = dir ? dir : $('select#sort-order').val();

    // add query param
    if(q) {
        paramList.push('q=' + q);
    }

    // add filter query param
    if(fqList) {
        paramList.push('fq=' + fqList.join('&fq='));
    }

    // add sort param if already set
    if(paramName !== 'sortField' && sort) {
        paramList.push('sortField=' + sort);
    }

    // add dir param if already set
    if(paramName !== 'dir' && dir) {
        paramList.push('dir=' + dir);
    }

    // add the changed value
    if(paramName && paramValue) {
        paramList.push(paramName + '=' + paramValue);
    }

    window.location.href = window.location.pathname + '?' + paramList.join('&');
}

// jQuery getQueryParam Plugin 1.0.0 (20100429)
// By John Terenzio | http://plugins.jquery.com/project/getqueryparam | MIT License
// Adapted by Nick dos Remedios to handle multiple params with same name - return a list
(function($) {
    // jQuery method, this will work like PHP's $_GET[]
    $.getQueryParam = function(param) {
        // get the pairs of params fist
        var pairs = location.search.substring(1).split('&');
        var values = [];

        // now iterate each pair
        for(var i = 0; i < pairs.length; i++) {
            var params = pairs[i].split('=');

            if(params[0] === param) {
                // if the param doesn't have a value, like ?photos&videos, then return an empty srting
                values.push(params[1]);
            }
        }

        if(values.length > 0) {
            return values;
        } else {
            // otherwise return undefined to signify that the param does not exist
            return undefined;
        }

    };
})(jQuery);

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function injectBiocacheResults() {
    var queryToUse = (SEARCH_CONF.query === '' || SEARCH_CONF.query === '*' ? '*:*' : SEARCH_CONF.query);
    var url = SEARCH_CONF.biocacheServicesUrl + '/occurrences/search.json?q=' + queryToUse +
        '&start=0&pageSize=0&facet=off&qc=' + SEARCH_CONF.biocacheQueryContext;

    $.ajax({
        url: url,
        dataType: 'jsonp',
        success:  function(data) {
            var maxItems = parseInt(data.totalRecords);
            var url = SEARCH_CONF.biocacheUrl + '/occurrences/search?q=' + queryToUse;
            var html =
            '<a href="' + url + '" class="page-header-links__link">' +
                '<span class="fa fa-list"></span>\n' +
                'View records (' + numberWithCommas(maxItems) + ')' +
            '</a>';

            insertSearchLinks(html);
        }
    });
}

function insertSearchLinks(html) {
    // add content
    $('#related-searches').append(html);
}
