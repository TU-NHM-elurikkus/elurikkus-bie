//= require leaflet-1.2.0/leaflet-src
//= require es6-promise
//= require google-mutant
//= require tile.stamen-v1.3.0
//= require ala-charts
//= require ekko-lightbox-5.2.0
//= require moment.min
//= require jquery.htmlClean

var SHOW_CONF; // This constant is populated by show.gsp inline javascript

function showSpeciesPage() {
    // load content
    loadOverviewImages();
    loadMap();
    loadGalleries();
    // loadExpertDistroMap();
    loadSpeciesLists();
    loadDataProviders();
    loadExternalSources();

    loadReferences('plutof-references', SHOW_CONF.guid);

    var langID = (SHOW_CONF.locale === 'et' ? 126 : 123);
    loadPlutoFTaxonDescription(SHOW_CONF.guid, langID);
}

function loadSpeciesLists() {
    $.getJSON(SHOW_CONF.speciesListUrl + '/ws/species/' + SHOW_CONF.guid + '?callback=?', function(data) {
        if(data) {
            var $listPanel = $('#descriptionTemplate').clone();
            var $listContent = $('<ul>');

            $listPanel.attr('id', '#specieslist-block');
            $listPanel.find('.title').html($.i18n.prop('menu.lists.label'));
            $listPanel.find('.card-footer').remove();

            data.forEach(function(speciesList) {
                $listContent.append(
                    '<li>' +
                        '<a href="' + SHOW_CONF.speciesListUrl + '/speciesListItem/list/' + speciesList.dataResourceUid + '">' +
                            '<span class="fa fa-tags"></span> ' +
                            speciesList.list.listName +
                        '</a>' +
                    '</li>'
                );
            });
            $listPanel.find('.content').html($listContent);
            $listPanel.appendTo('#listContent');
            $listPanel.show();
        }
    });
}

function loadMap() {
    if(SHOW_CONF.map !== null) {
        return;
    }

    // add an occurrence layer for this taxon
    var taxonLayer = L.tileLayer.wms(SHOW_CONF.biocacheServiceUrl + '/mapping/wms/reflect?q=lsid:' +
        SHOW_CONF.guid + '&qc=' + SHOW_CONF.mapQueryContext, {
        layers: 'ALA:occurrences',
        format: 'image/png',
        transparent: true,
        attribution: SHOW_CONF.mapAttribution,
        bgcolor: '0x000000',
        outline: SHOW_CONF.mapOutline,
        ENV: SHOW_CONF.mapEnvOptions,
        uppercase: true
    });

    var speciesLayers = new L.LayerGroup();
    taxonLayer.addTo(speciesLayers);

    SHOW_CONF.map = L.map('leafletMap', {
        center: [SHOW_CONF.defaultDecimalLatitude, SHOW_CONF.defaultDecimalLongitude],
        zoom: SHOW_CONF.defaultZoomLevel,
        layers: [speciesLayers],
        scrollWheelZoom: false
    });

    var defaultBaseLayer = L.tileLayer(SHOW_CONF.defaultMapUrl, {
        attribution: SHOW_CONF.defaultMapAttr,
        subdomains: SHOW_CONF.defaultMapDomain,
        mapid: SHOW_CONF.defaultMapId,
        token: SHOW_CONF.defaultMapToken
    });

    defaultBaseLayer.addTo(SHOW_CONF.map);

    // Google map layers
    var roadLayer = L.gridLayer.googleMutant({ type: 'roadmap' });
    var terrainLayer = L.gridLayer.googleMutant({ type: 'terrain' });
    var hybridLayer = L.gridLayer.googleMutant({ type: 'satellite' });
    var blackWhiteLayer = new L.StamenTileLayer('toner');

    var baseLayers = {};
    baseLayers[$.i18n.prop('advancedsearch.js.map.layers.Minimal')] = defaultBaseLayer;
    baseLayers[$.i18n.prop('advancedsearch.js.map.layers.Road')] = roadLayer;
    baseLayers[$.i18n.prop('advancedsearch.js.map.layers.Terrain')] = terrainLayer;
    baseLayers[$.i18n.prop('advancedsearch.js.map.layers.Satellite')] = hybridLayer;
    baseLayers[$.i18n.prop('advancedsearch.js.map.layers.BlackWhite')] = blackWhiteLayer;

    var sciName = SHOW_CONF.scientificName;

    var overlays = {};
    overlays[sciName] = taxonLayer;

    L.control.layers(baseLayers, overlays, { collapsed: true, position: 'bottomleft' }).addTo(SHOW_CONF.map);

    SHOW_CONF.map.invalidateSize(false);

    updateOccurrenceCount();
}

/**
 * Update the total records count for the occurrence map in heading text
 */
function updateOccurrenceCount() {
    $.getJSON(SHOW_CONF.biocacheServiceUrl + '/occurrences/taxaCount?guids=' + SHOW_CONF.guid + '&fq=' + SHOW_CONF.mapQueryContext, function(data) {
        if(data) {
            $.each(data, function(key, value) {
                if(value && typeof value === 'number') {
                    $('.occurrenceRecordCount').html(value.toLocaleString());
                    return false;
                }
            });
        }
    });
}

// Disabled for now - always position the map over default coordinates
function fitMapToBounds() {
    var jsonUrl = SHOW_CONF.biocacheServiceUrl + '/mapping/bounds.json?q=lsid:' + SHOW_CONF.guid + '&callback=?';

    $.getJSON(jsonUrl, function(data) {
        if(data.length !== 4) {
            return;
        }

        // If query has no mapped results, /mapping/bounds returns [0, 0, 0, 0]
        if(data.every(function(coord) { return coord === 0; })) {
            return;
        }

        var sw = L.latLng(data[1], data[0]);
        var ne = L.latLng(data[3], data[2]);
        var dataBounds = L.latLngBounds(sw, ne);

        var mapBounds = SHOW_CONF.map.getBounds();

        if(!mapBounds.contains(dataBounds) && !mapBounds.intersects(dataBounds)) {
            SHOW_CONF.map.fitBounds(dataBounds);

            if(SHOW_CONF.map.getZoom() > 3) {
                SHOW_CONF.map.setZoom(3);
            }
        }

        SHOW_CONF.map.invalidateSize(true);
    });
}

function loadDataProviders() {

    var url = SHOW_CONF.biocacheServiceUrl +
        '/occurrences/search.json?' +
        'q=lsid:' + SHOW_CONF.guid +
        '&pageSize=0&flimit=-1';

    if(SHOW_CONF.mapQueryContext) {
        url = url + '&fq=' + SHOW_CONF.mapQueryContext;
    }

    url += '&facet=on&facets=data_resource_uid&callback=?';

    var uiUrl = SHOW_CONF.biocacheUrl +
        '/occurrences/search?q=lsid:' +
        SHOW_CONF.guid;

    $.getJSON(url, function(data) {

        if(data.totalRecords > 0) {
            $('.datasetCount').html(data.facetResults[0].fieldResult.length);
            $.each(data.facetResults[0].fieldResult, function(idx, facetValue) {
                if(facetValue.count > 0) {

                    var uid = facetValue.fq.replace(/data_resource_uid:/, '').replace(/[\\"]*/, '').replace(/[\\"]/, '');
                    var dataResourceUrl = SHOW_CONF.collectoryUrl + '/public/show/' + uid;
                    var tableRow =
                        '<tr>' +
                            '<td>' +
                                '<a href="' + dataResourceUrl + '">' +
                                    '<span class="fa fa-database"></span>' +
                                    '&nbsp;' +
                                    facetValue.label +
                                '</a>';

                    $.getJSON(SHOW_CONF.collectoryUrl + '/ws/dataResource/' + uid, function(collectoryData) {

                        if(collectoryData.provider) {
                            tableRow +=
                                '<br />' +
                                '<small>' +
                                    '<a href="' + SHOW_CONF.collectoryUrl + '/public/show/' + uid + '">' +
                                        collectoryData.provider.name +
                                    '</a>' +
                                '</small>';
                        }
                        var queryUrl = uiUrl + '&fq=data_resource_uid:' + uid;

                        tableRow +=
                                '</td>' +
                                '<td>' +
                                    collectoryData.licenseType +
                                '</td>' +
                                '<td>' +
                                    '<a href="' + queryUrl + '">' +
                                        '<span class="fa fa-list"></span>' +
                                        '&nbsp;' +
                                        facetValue.count +
                                    '</a>' +
                                '</td>' +
                            '</tr>';

                        $('#data-providers-list tbody').append(tableRow);
                    });
                }
            });
        }
    });
}

function loadExternalSources() {
    // load EOL content
    $.ajax({ url: SHOW_CONF.eolUrl }).done(function(data) {
        // clone a description template...
        if(data.dataObjects) {
            $.each(data.dataObjects, function(idx, dataObject) {
                if((dataObject.language === SHOW_CONF.locale) || (!dataObject.language && SHOW_CONF.locale === 'en')) {
                    var $description = $('#descriptionTemplate').clone();
                    $description.css({ 'display': 'block' });
                    $description.attr('id', dataObject.id);
                    if(dataObject.title) {
                        $description.find('.title').html(dataObject.title);
                    }

                    var descriptionDom = $.parseHTML(dataObject.description);
                    var body = $(descriptionDom).find('#bodyContent > p:lt(2)').html(); // for really long EOL blocks

                    if(body) {
                        $description.find('.content').html(body);
                    } else {
                        $description.find('.content').html(dataObject.description);
                    }
                    $description.find('img').addClass('img-responsive');

                    if(dataObject.source && dataObject.source.trim().length !== 0) {
                        var sourceText = dataObject.source;
                        var sourceHtml = '';

                        if(sourceText.match('^http')) {
                            sourceHtml = '<a href="' + sourceText + '" target="_blank">' + sourceText + '</a>';
                        } else {
                            sourceHtml = sourceText;
                        }

                        $description.find('.sourceText').html(sourceHtml);
                    } else {
                        $description.find('.source').css({ 'display': 'none' });
                    }
                    if(dataObject.rightsHolder && dataObject.rightsHolder.trim().length !== 0) {
                        $description.find('.rightsText').html(dataObject.rightsHolder);
                    } else {
                        $description.find('.rights').css({ 'display': 'none' });
                    }

                    $description.find('.providedBy').attr('href', 'http://eol.org/pages/' + data.identifier);
                    $description.find('.providedBy').html('Encyclopedia of Life');
                    $description.appendTo('#descriptiveContent');
                }
            });
        }
    });

    loadPlutoFSequences('sequences-plutof', SHOW_CONF.guid);

    // load sound content
    $.ajax({ url: SHOW_CONF.soundUrl }).done(function(data) {
        if(data.sounds) {
            var formats = data.sounds[0].alternativeFormats;
            var links = [];

            for(var format in formats) {
                links.push(formats[format]);
            }

            if(!links) {
                return;
            }

            var source = links[0];

            var soundsDiv =
                '<div class="panel panel-default">' +
                    '<div class="panel-heading">' +
                        '<h3 class="panel-title">' +
                            $.i18n.prop('show.sounds') +
                        '</h3>' +
                    '</div>' +
                    '<div class="panel-body">' +
                        '<audio controls class="audio-player">' +
                            '<source src="' + source + '">Your browser doesn\'t support playing audio' +
                        '</audio>' +
                    '</div>' +
                    '<div class="panel-footer audio-player-footer">' +
                    '<p>';

            if(data.processed.attribution.collectionName) {
                source = '';
                var attrUrl = '';
                var attrUrlPrefix = SHOW_CONF.collectoryUrl + '/public/show/';

                if(data.raw.attribution.dataResourceUid) {
                    attrUrl = attrUrlPrefix + data.raw.attribution.dataResourceUid;
                } else if(data.processed.attribution.collectionUid) {
                    attrUrl = attrUrlPrefix + data.processed.attribution.collectionUid;
                }

                if(data.raw.attribution.dataResourceUid === 'dr341') {
                    // hard-coded copyright as most sounds are from ANWC and are missing attribution data fields
                    source += '&copy; ' + data.processed.attribution.collectionName + ' ' + data.processed.event.year + '<br />';
                }

                if(attrUrl) {
                    source +=
                        $.i18n.prop('show.names.field.source') + ': <a href="' + attrUrl + '" target="biocache">' +
                            data.processed.attribution.collectionName +
                        '</a>';
                } else {
                    source += data.processed.attribution.collectionName;
                }

                soundsDiv += source + '<br />';
            } else if(data.processed.attribution.dataResourceName) {
                soundsDiv += $.i18n.prop('show.names.field.source') + ': ' + data.processed.attribution.dataResourceName;
            }

            soundsDiv +=
                            '<a href="' + SHOW_CONF.biocacheUrl + '/occurrence/' + data.raw.uuid + '"> ' +
                                $.i18n.prop('show.sounds.details') +
                            '</a>' +
                        '</p>' +
                    '</div>' +
                '</div>';

            $('#sounds').append(soundsDiv);
        }
    }).fail(function(jqXHR, textStatus, errorThrown) {
        console.warn('AUDIO Error', errorThrown, textStatus);
    });
}

/**
 * Trigger loading of the 3 gallery sections
 */
function loadGalleries() {
    $('#gallerySpinner').show();
    loadGalleryType('type', 0);
    loadGalleryType('specimen', 0);
    loadGalleryType('other', 0);
    loadGalleryType('uncertain', 0);
}

var entityMap = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    '\'': '&#39;',
    '/': '&#x2F;'
};

function escapeHtml(string) {
    return String(string).replace(/[&<>"'\/]/g, function(s) {
        return entityMap[s];
    });
}

/**
 * Load overview images on the species page. This is separate from the main galleries.
 */
function loadOverviewImages() {
    var hasPreferredImage = false; // Could get a race condition where no main image gets loaded due callbacks

    if(SHOW_CONF.preferredImageId) {
        hasPreferredImage = true;
        var prefUrl = SHOW_CONF.biocacheServiceUrl +
            '/occurrences/search.json?q=image_url:' + SHOW_CONF.preferredImageId +
            '&fq=-assertion_user_id:*&im=true&facet=off&pageSize=1&start=0&callback=?';

        $.getJSON(prefUrl, function(data) {
            if(data && data.totalRecords > 0) {
                addOverviewImage(data.occurrences[0]);
                hasPreferredImage = true;
            } else {
                hasPreferredImage = false;
            }

        }).fail(function(jqxhr, textStatus, error) {
            console.warn('Error loading overview image: ' + textStatus + ', ' + error);
            hasPreferredImage = false;
        });
    }

    var url = SHOW_CONF.biocacheServiceUrl +
        '/occurrences/search.json?q=lsid:' +
        SHOW_CONF.guid +
        '&fq=multimedia:"Image"&fq=-assertion_user_id:*&im=true&facet=off&pageSize=5&start=0&callback=?';

    $.getJSON(url, function(data) {
        if(data && data.totalRecords > 0) {
            addOverviewImages(data.occurrences, hasPreferredImage);
        }
    }).fail(function(jqxhr, textStatus, error) {
        console.warn('Error loading overview images: ' + textStatus + ', ' + error);
    }).always(function() {
        $('#gallerySpinner').hide();
    });
}

function addOverviewImages(imagesArray, hasPreferredImage) {
    if(!hasPreferredImage) {
        // no preferred image so use first in results set
        addOverviewImage(imagesArray[0]);
    }

    for(var j = 1; j < 5; j++) {
        // load smaller thumb images
        if(imagesArray.length > j) {
            addOverviewThumb(imagesArray[j], j);
        }
    }
}

function addOverviewImage(overviewImageRecord) {
    var $categoryTmpl = $('#overviewImages');
    var $mainOverviewImage = $('.mainOverviewImage');

    $('.taxon-summary-gallery').removeClass('hidden-node');

    $categoryTmpl.removeClass('hidden-node');
    $mainOverviewImage.attr('src', overviewImageRecord.largeImageUrl);
    $mainOverviewImage.parent().attr('href', overviewImageRecord.largeImageUrl);
    $mainOverviewImage.parent().attr('data-footer', getImageFooterFromOccurrence(overviewImageRecord));
    $mainOverviewImage.parent().attr('data-image-id', overviewImageRecord.image);
    $mainOverviewImage.parent().attr('data-record-url', SHOW_CONF.biocacheUrl + '/occurrences/' + overviewImageRecord.uuid);

    $('.mainOverviewImageInfo').html(getImageTitleFromOccurrence(overviewImageRecord));
}

function addOverviewThumb(record, i) {
    if(i < 4) {
        var $thumb = generateOverviewThumb(record, i);

        $('#overview-thumbs').append($thumb);
    } else {
        $('#more-photo-thumb-link').attr('style', 'background-image:url(' + record.smallImageUrl + ')');
    }
}

function generateOverviewThumb(occurrence, id) {
    var $taxonSummaryThumb = $('<div class="taxon-summary-thumb"></div>');
    var $taxonSummaryThumbLink = $('<a></a>');

    $taxonSummaryThumb.attr('id', 'taxon-summary-thumb-' + id);
    $taxonSummaryThumb.attr('style', 'background-image:url(' + occurrence.smallImageUrl + ')');
    $taxonSummaryThumbLink.attr('data-title', getImageTitleFromOccurrence(occurrence));
    $taxonSummaryThumbLink.attr('data-footer', getImageFooterFromOccurrence(occurrence));
    $taxonSummaryThumbLink.attr('data-toggle', 'lightbox');
    $taxonSummaryThumbLink.attr('data-parent', '.taxon-summary-gallery');
    $taxonSummaryThumbLink.attr('href', occurrence.largeImageUrl);
    $taxonSummaryThumbLink.attr('data-image-id', occurrence.image);
    $taxonSummaryThumbLink.attr('data-gallery', 'taxon-summary-gallery');
    $taxonSummaryThumbLink.attr('data-record-url', SHOW_CONF.biocacheUrl + '/occurrences/' + occurrence.uuid);
    $taxonSummaryThumb.append($taxonSummaryThumbLink);

    return $taxonSummaryThumb;
}

/**
 * AJAX loading of gallery images from biocache-service
 *
 * @param category
 * @param start
 */
function loadGalleryType(category, start) {
    var imageCategoryParams = {
        type: '&fq=type_status:*',
        specimen: '&fq=basis_of_record:PreservedSpecimen&fq=-type_status:*',
        other: '&fq=-type_status:*&fq=-basis_of_record:PreservedSpecimen&fq=-identification_qualifier_s:"Uncertain"&fq=-assertion_user_id:*&sort=identification_qualifier_s&dir=asc',
        uncertain: '&fq=-type_status:*&fq=-basis_of_record:PreservedSpecimen&fq=identification_qualifier_s:"Uncertain"'
    };

    var pageSize = 20;

    if(start > 0) {
        $('.loadMore.' + category + ' button').addClass('disabled');
        $('.loadMore.' + category + ' img').removeClass('hidden-node');
    }

    // TODO a toggle between LSID based searches and names searches
    var url = SHOW_CONF.biocacheServiceUrl +
        '/occurrences/search.json?q=lsid:' +
        SHOW_CONF.guid +
        '&fq=multimedia:"Image"&pageSize=' + pageSize +
        '&facet=off&start=' + start + imageCategoryParams[category] + '&im=true&callback=?';

    $.getJSON(url, function(data) {
        if(data && data.totalRecords > 0) {
            var $categoryTmpl = $('#cat_' + category);
            $categoryTmpl.removeClass('hidden-node');
            $('#cat_nonavailable').addClass('hidden-node');

            $.each(data.occurrences, function(i, el) {
                var $galleryGrid = $('<div/>', {
                    class: 'gallery-thumb'
                }).append(
                    $('<a>', {
                        'id': 'thumb_' + category + i,
                        'data-toggle': 'lightbox',
                        'href': el.largeImageUrl,
                        'data-gallery': 'main-image-gallery',
                        'rel': 'thumbs',
                        'data-image-id': el.image,
                        'data-record-url': SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid,
                        'data-footer': getImageFooterFromOccurrence(el)
                    }).append(
                        $('<div>', {
                            'class': 'gallery-thumb__footer'
                        }).append(
                            getImageTitleFromOccurrence(el)
                        )
                    ).append(
                        $('<img>', {
                            'class': 'img-fluid gallery-thumb__img',
                            'src': el.smallImageUrl
                        })
                    )
                );

                // write to DOM
                $categoryTmpl.find('.taxon-gallery').append($galleryGrid);
            });

            $('.loadMore.' + category).remove();  // remove 'load more images' button that was just clicked

            if(data.totalRecords > (start + pageSize)) {
                // add new 'load more images' button if required
                var spinnerLink = $('img#gallerySpinner').attr('src');
                var btn =
                    '<div class="loadMore ' + category + '">' +
                        '<button type="button" class="erk-button erk-button--light" onCLick="loadGalleryType(\'' + category + '\',' + (start + pageSize) + ');">' +
                            $.i18n.prop('general.btn.loadMore') +
                            '&nbsp;<img src="' + spinnerLink + '" class="hidden-node" />' +
                        '</button>' +
                    '</div>';
                $categoryTmpl.find('.taxon-gallery').append(btn);
            }
        }
    }).fail(function(jqxhr, textStatus, error) {
        console.warn('Error loading gallery: ' + textStatus + ', ' + error);
    }).always(function() {
        $('#gallerySpinner').hide();
    });
}

function getImageTitleFromOccurrence(el) {
    var briefHtml = el.raw_scientificName;

    if(el.typeStatus) {
        briefHtml += '<br />' + el.typeStatus;
    }

    if(el.institutionName) {
        briefHtml += ((el.typeStatus) ? ' | ' : '<br />') + el.institutionName;
    }

    return briefHtml;
}

function getImageFooterFromOccurrence(el) {
    var br = '<br />';
    var rightDetail = '<b>' + $.i18n.prop('js.image.modal.taxon') + ': </b>' + el.raw_scientificName;
    if(el.typeStatus) {
        rightDetail += br + '<b>' + $.i18n.prop('js.image.modal.type') + ': </b>' + el.typeStatus;
    }
    if(el.collector) {
        rightDetail += br + '<b>' + $.i18n.prop('js.image.modal.by') + ': </b>' + el.collector;
    }
    if(el.eventDate) {
        rightDetail += br + '<b>' + $.i18n.prop('js.image.modal.date') + ': </b>' + moment(el.eventDate).format('YYYY-MM-DD');
    }
    if(el.institutionName && el.institutionName !== undefined) {
        rightDetail += br + '<b>' + $.i18n.prop('show.names.field.source') + ': </b>' + el.institutionName;
    } else if(el.dataResourceName) {
        rightDetail += br + '<b>' + $.i18n.prop('show.names.field.source') + ': </b>' + el.dataResourceName;
    }
    if(el.imageMetadata && el.imageMetadata.length > 0 && el.imageMetadata[0].rightsHolder !== null) {
        rightDetail += br + '<b>' + $.i18n.prop('show.overview.field.rightsHolder') + ': </b>' + el.imageMetadata[0].rightsHolder;
    }
    rightDetail = '<div class="col-sm-8">' + rightDetail + '</div>';

    // write to DOM
    var leftDetail =
        '<div class="col-sm-4 recordLink">' +
            '<a href="' + SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid + '">' +
                '<span class="fa fa-list"></span> ' + $.i18n.prop('general.btn.viewRecords') +
            '</a>' +
            '<br />' +
            '<br />' +
            $.i18n.prop('js.image.modal.issues') +
            '<a href="' + SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid + '"> ' +
                $.i18n.prop('js.image.modal.issue.link') +
            '</a>' +
        '</div>';

    var detailHtml = '<div class="row">' + rightDetail + leftDetail + '</div>';
    return detailHtml;
}

/**
 * BHL search to populate literature tab
 *
 * @param start
 * @param rows
 * @param scroll
 */
function loadBhl(start, rows, scroll) {
    if(!start) {
        start = 0;
    }
    if(!rows) {
        rows = 10;
    }
    // var url = "http://localhost:8080/bhl-ftindex-demo/search/ajaxSearch?q=" + $("#tbSearchTerm").val();
    var taxonName = SHOW_CONF.scientificName;
    var synonyms = SHOW_CONF.synonymsQuery;
    var query = ''; // = taxonName.split(/\s+/).join(" AND ") + synonyms;
    if(taxonName) {
        var terms = taxonName.split(/\s+/).length;
        if(terms > 2) {
            query += taxonName.split(/\s+/).join(' AND ');
        } else if(terms === 2) {
            query += '"' + taxonName + '"';
        } else {
            query += taxonName;
        }
    }

    if(synonyms) {
        synonyms = synonyms.replace(/\\\"/g, '"'); // remove escaped quotes

        if(taxonName) {
            query += ' OR (' + synonyms + ')';
        } else {
            query += synonyms;
        }
    }

    if(!query) {
        return cancelSearch('No names were found to search BHL');
    }

    var url = 'http://bhlidx.ala.org.au/select?q=' + query + '&start=' + start + '&rows=' + rows +
        '&wt=json&fl=name%2CpageId%2CitemId%2Cscore&hl=on&hl.fl=text&hl.fragsize=200&' +
        'group=true&group.field=itemId&group.limit=7&group.ngroups=true&taxa=false';

    $('#status-box').css('display', 'block');
    $('#synonyms').html('').css('display', 'none');
    $('#bhl-results-list').html('');

    $.ajax({
        url: url,
        dataType: 'jsonp',
        jsonp: 'json.wrf',
        success: function(data) {
            var itemNumber = parseInt(data.responseHeader.params.start) + 1;
            var maxItems = parseInt(data.grouped.itemId.ngroups);
            if(maxItems === 0) {
                return cancelSearch('No references were found for <pre>' + query + '</pre>');
            }
            var startItem = parseInt(start);
            var pageSize = parseInt(rows);
            var showingFrom = startItem + 1;
            var showingTo = (startItem + pageSize <= maxItems) ? startItem + pageSize : maxItems;
            var buf =
                '<div class="results-summary">' +
                    'Showing ' + showingFrom + ' to ' + showingTo + ' of ' + maxItems + ' results for the query ' +
                    '<pre>' +
                        query +
                    '</pre>' +
                '</div>';
            // grab highlight text and store in map/hash
            var highlights = {};
            $.each(data.highlighting, function(idx, hl) {
                highlights[idx] = hl.text[0];
            });
            $.each(data.grouped.itemId.groups, function(idx, obj) {
                buf += '<div class="result">';
                buf += '<h3><b>' + itemNumber++;
                buf += '.</b> <a target="_blank" href="http://biodiversitylibrary.org/item/' + obj.groupValue + '">' + obj.doclist.docs[0].name + '</a> ';
                var suffix = '';
                if(obj.doclist.numFound > 1) {
                    suffix = 's';
                }
                buf += '(' + obj.doclist.numFound + '</b> matching page' + suffix + ')</h3><div class="thumbnail-container">';

                $.each(obj.doclist.docs, function(idx, page) {
                    var highlightText = $('<div>' + highlights[page.pageId] + '</div>').htmlClean({ allowedTags: ['em'] }).html();
                    buf += '<div class="page-thumbnail"><a target="_blank" href="http://biodiversitylibrary.org/page/' +
                        page.pageId + '"><img src="http://biodiversitylibrary.org/pagethumb/' + page.pageId +
                        '" alt="' + escapeHtml(highlightText) + '"  width="60px" height="100px"/></a></div>';
                });
                buf += '</div><!--end .thumbnail-container -->';
                buf += '</div>';
            });

            var prevStart = start - rows;
            var nextStart = start + rows;

            buf += '<div id="button-bar">';
            if(prevStart >= 0) {
                buf += '<input type="button" class="btn" value="Previous page" onclick="loadBhl(' + prevStart + ',' + rows + ', true)">';
            }
            buf += '&nbsp;&nbsp;&nbsp;';
            if(nextStart <= maxItems) {
                buf += '<input type="button" class="btn" value="Next page" onclick="loadBhl(' + nextStart + ',' + rows + ', true)">';
            }

            buf += '</div>';

            $('#bhl-results-list').html(buf);
            if(data.synonyms) {
                buf = '<b>Synonyms used:</b>&nbsp;';
                buf += data.synonyms.join(', ');
                $('#synonyms').html(buf).css('display', 'block');
            } else {
                $('#synonyms').html('').css('display', 'none');
            }
            $('#status-box').css('display', 'none');

            if(scroll) {
                $('html, body').animate({ scrollTop: '300px' }, 300);
            }
        },
        error: function(jqXHR, textStatus, errorThrown) {
            $('#status-box').css('display', 'none');
            $('#solr-results').html('An error has occurred, probably due to invalid query syntax');
        }
    });
} // end doSearch

function cancelSearch(msg) {
    $('#status-box').css('display', 'none');
    $('#solr-results').html(msg);
    return true;
}

function loadExpertDistroMap() {
    var url = SHOW_CONF.layersServiceUrl + '/distribution/map/' + SHOW_CONF.guid + '?callback=?';
    $.getJSON(url, function(data) {
        if(data.available) {
            $('#expertDistroDiv img').attr('src', data.url);
            if(data.dataResourceName && data.dataResourceUrl) {
                var attr = $('<a>').attr('href', data.dataResourceUrl).text(data.dataResourceName);
                $('#expertDistroDiv #dataResource').html(attr);
            }
            $('#expertDistroDiv').show();
        }
    });
}

function toggleImageGallery(btn) {
    var iSpan = $(btn).find('span.fa-caret-square-o-up');
    if(iSpan.length) {
        iSpan.removeClass('fa-caret-square-o-up');
        iSpan.addClass('fa-caret-square-o-down');
        $(iSpan).parents('.image-section').find('.taxon-gallery').slideUp(400);
    } else {
        iSpan = $(btn).find('span.fa-caret-square-o-down');
        iSpan.removeClass('fa-caret-square-o-down');
        iSpan.addClass('fa-caret-square-o-up');
        $(iSpan).parents('.image-section').find('.taxon-gallery').slideDown(400);
    }
}

// TODO: Can abstract loadReferences and loadPlutoFSequences more
function loadReferences(containerID, taxonID) {
    var PAGE_SIZE = 20;

    var $container = $('#' + containerID);
    var $count = $container.find('.plutof-references__count');
    var $list = $container.find('.plutof-references__list');
    var $pagination = $container.find('.plutof-references__pagination');

    var endpoint = '/bie-hub/proxy/plutof/taxonoccurrence/referencebased/occurrences/search/';
    var params = {
        cn: 47, // Country = Estonia
        taxon_node: taxonID,
        page_size: PAGE_SIZE
    };

    var currentPage = 0;
    var pageCount = 0;
    var loadPage;

    function showPage(pageNumber, page) {
        $list.empty();

        page.forEach(function(occurrence) {
            var el = $(
                '<li class="plutof-references__item">' +
                    '<a href="https://plutof.ut.ee/#/referencebased/view/' + occurrence.id + '" target="_blank">' +
                        occurrence.reference +
                    '</a>' +
                    '<div class="plutof-references__content">' +
                        occurrence.locality_text +
                    '</div>' +
                '</li>'
            );

            $list.append(el);
        });

        setPlutoFPagination($pagination, pageNumber, pageCount, loadPage);
    }

    function updateCount(count, _pageCount) {
        pageCount = _pageCount;

        $count.html('(' + count + ')');

        if(count > 0) {
            $('#plutof-references').show();
        }
        setPlutoFPagination($pagination, currentPage, pageCount, loadPage);
    }

    loadPage = loadPlutoFSearchResults(endpoint, params, updateCount, showPage);

    loadPage(1);
}

function loadPlutoFSequences(containerID, taxonID) {
    var $container = $('#' + containerID);
    var $count = $container.find('.sequences__count');
    var $list = $container.find('.sequences__list');
    var $pagination = $container.find('.sequences__pagination');

    var endpoint = '/bie-hub/proxy/plutof/taxonoccurrence/sequence/sequences/search/';

    var params = {
        cn: 47, // country = Estonia
        taxon_node: taxonID,
        include_cb: false
    };

    var pageCount = 0;
    var currentPage = 1;
    var loadPage;

    function showPage(pageNumber, page) {
        currentPage = pageNumber;

        $list.empty();

        page.forEach(function(entry) {
            var $entry = $('#sequenceTemplate').clone();
            var content = '';
            var $eLink = $entry.find('.externalLink');

            $entry.attr('id', 'sequence-' + $entry.attr('id'));
            $entry.removeAttr('id'); // Do not clone the ID.

            var href;
            if(entry.unitestatus_verif || entry.insdstatus) {
                href = 'https://unite.ut.ee/bl_forw.php?id=' + entry.id;
            } else {
                href = 'https://plutof.ut.ee/#/sequence/view/' + entry.id;
            }
            $eLink.attr('href', href);
            $eLink.html(entry.name);

            if(entry.sequence_types.length) {
                content += $entry.find('.sequence-regions').text();

                if(typeof entry.sequence_types === 'string') {  // Because plutof search doesn't return list for one element
                    content += entry.sequence_types;
                } else {
                    content += entry.sequence_types.join(', ');
                }

                content += '<br />';
            }

            if(entry.gathering_agents) {
                content += $entry.find('.sequence-collected-by').text() + entry.gathering_agents;
                content += '<br />';
            }

            $entry.find('.description').html(content);
            $entry.removeClass('hidden-node');
            $list.append($entry);
        });

        setPlutoFPagination($pagination, pageNumber, pageCount, loadPage);
    }

    function updateCount(count, _pageCount) {
        pageCount = _pageCount;

        $count.html('(' + count + ')');

        setPlutoFPagination($pagination, currentPage, pageCount, loadPage);
    }

    loadPage = loadPlutoFSearchResults(endpoint, params, updateCount, showPage);

    loadPage(1);
}

function setPlutoFPagination($pagination, currentPage, pageCount, loadPage) {
    $pagination.empty();

    if(pageCount <= 1) {
        return;
    }

    // XXX TODO: not plutof-references__page
    for(var p = 1; p <= pageCount; p++) {
        var $el;

        if(p === currentPage) {
            $el = $('<span class="plutof-pagination__page plutof-pagination__page--current">' + p + '</span>');
        } else {
            $el = (function(pageNum) {
                var el = $('<span class="plutof-pagination__page">' + pageNum + '</span>');

                el.on('click', function() {
                    loadPage(pageNum);
                });

                return el;
            })(p);
        }

        $pagination.append($el);
    }
}

// updateCount :: (count:int, pageCount:int) -> ()
// showPage :: (pageNumber::int, page::[...] -> ())
//
// Returns a function for loadingPages
function loadPlutoFSearchResults(endpoint, params, updateCount, showPage) {
    var PAGE_SIZE = 20;

    params.page_size = PAGE_SIZE;

    var count;
    var pageCount;

    function loadPage(pageNumber) {
        params.page = pageNumber;

        $.getJSON(endpoint, params, function(data) {
            if(count !== data.count) {
                count = data.count;
                pageCount = Math.ceil(data.count / PAGE_SIZE);

                updateCount(count, pageCount);
            }

            showPage(pageNumber, data.results);
        });
    }

    return loadPage;
}

function loadPlutoFTaxonDescription(taxonID, languageID) {
    var endpoint = '/bie-hub/proxy/plutof/public/taxa/descriptions/';
    var params = {
        page_size: 10,
        taxon_node: taxonID,
        include: 'owner',
        language: (languageID ? languageID : 123)  // 123 == eng, 126 == est
    };

    $.getJSON(endpoint, params, function(data) {
        var excludedFields = ['created_at', 'updated_at', 'taxon_name'];
        $.each(data.data, function(_index, desObj) {
            var $description = $('#descriptionTemplate').clone();
            var owner = desObj.relationships.owner.data;

            $description.attr('id', 'taxon-description-' + desObj.id);

            var content = '';
            $.each(desObj.attributes, function(key, value) {
                if(value && excludedFields.indexOf(key) === -1) {
                    // content += '<b>' + key + ':</b> ' + value + '<br />';
                    content += '<p>' + value + '</p>';
                }
            });
            $description.find('.content').html(content);
            $description.find('.sourceText').html(
                '<a target="_blank" href="https://plutof.ut.ee/#/taxon-description/view/' + desObj.id + '">' +
                    'https://plutof.ut.ee/#/taxon-description/view/' + desObj.id +
                '</a>'
            );
            owner = data.included.find(function(includeObj) {
                return owner.id === includeObj.id && owner.type === includeObj.type;
            });
            $description.find('.rightsText').html(owner.attributes.full_name);

            $description.find('.providedBy').html($.i18n.prop('show.overview.field.providedBy.plutof'));
            $description.find('.providedBy').attr('href', 'https://plutof.ut.ee/');

            $description.appendTo('#descriptiveContent');
            $description.show();
        });
    });
}
