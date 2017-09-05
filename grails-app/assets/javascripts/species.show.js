function showSpeciesPage() {
    // load content
    loadOverviewImages();
    loadMap();
    loadGalleries();
    loadExpertDistroMap();
    loadExternalSources();
    loadSpeciesLists();
    loadDataProviders();

    loadReferences('plutof-references', SHOW_CONF.guid);
}

function loadSpeciesLists() {
    $.getJSON(SHOW_CONF.speciesListUrl + '/ws/species/' + SHOW_CONF.guid + '?callback=?', function(data) {
        for(var i = 0; i < data.length; i++) {
            var specieslist = data[i];
            var maxListFields = 10;

            if(specieslist.list.isBIE) {
                var $description = $('#descriptionTemplate').clone();
                $description.css({ 'display': 'block' });
                $description.attr('id', '#specieslist-block-' + specieslist.dataResourceUid);
                $description.addClass('species-list-block');
                $description.find('.title').html(specieslist.list.listName);

                if(specieslist.kvpValues.length > 0) {
                    var content = '<table class="table">';
                    $.each(specieslist.kvpValues, function(idx, kvpValue) {
                        if(idx >= maxListFields) {
                            return false;
                        }
                        var value = kvpValue.value;
                        if(kvpValue.vocabValue) {
                            value = kvpValue.vocabValue;
                        }
                        content += '<tr><td>' + (kvpValue.key + '</td><td>' + value + '</td></tr>');
                    });
                    content += '</table>';
                    $description.find('.content').html(content);
                } else {
                    $description.find('.content').html('A species list provided by ' + specieslist.list.listName);
                }

                $description.find('.source').css({ 'display': 'none' });
                $description.find('.rights').css({ 'display': 'none' });

                $description.find('.providedBy').attr('href', SHOW_CONF.speciesListUrl + '/speciesListItem/list/' + specieslist.dataResourceUid);
                $description.find('.providedBy').html(specieslist.list.listName);

                $description.appendTo('#listContent');
            }
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
            ENV: SHOW_CONF.mapEnvOptions
        }
    );

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

    var baseLayers = {
        'Base layer': defaultBaseLayer
    };

    var sciName = SHOW_CONF.scientificName;

    var overlays = {};
    overlays[sciName] = taxonLayer;

    L.control.layers(baseLayers, overlays).addTo(SHOW_CONF.map);

    SHOW_CONF.map.invalidateSize(false);

    updateOccurrenceCount();
    fitMapToBounds();
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

function fitMapToBounds() {
    var jsonUrl = SHOW_CONF.biocacheServiceUrl + '/mapping/bounds.json?q=lsid:' + SHOW_CONF.guid + '&callback=?';
    $.getJSON(jsonUrl, function(data) {
        if(data.length === 4) {
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
        }
    });
}

function loadDataProviders() {

    var url = SHOW_CONF.biocacheServiceUrl +
        '/occurrences/search.json?q=lsid:' +
        SHOW_CONF.guid +
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
                    var dataResourceUrl =  SHOW_CONF.collectoryUrl + '/public/show/' + uid;
                    var tableRow = '<tr><td><a href="' + dataResourceUrl + '"><span class="data-provider-name">' + facetValue.label + '</span></a>';

                    $.getJSON(SHOW_CONF.collectoryUrl + '/ws/dataResource/' + uid, function(collectoryData) {

                        if(collectoryData.provider) {
                            tableRow += '<br/><small><a href="' + SHOW_CONF.collectoryUrl + '/public/show/' + uid + '">' + collectoryData.provider.name + '</a></small>';
                        }
                        tableRow += '</td>';
                        tableRow += '<td>' + collectoryData.licenseType + '</td>';

                        var queryUrl = uiUrl + '&fq=' + facetValue.fq;
                        tableRow += '</td><td><a href="' + queryUrl + '"><span class="record-count">' + facetValue.count + '</span></a></td>';
                        tableRow += '</tr>';
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
                if(dataObject.language == SHOW_CONF.eolLanguage || !dataObject.language) {
                    var $description = $('#descriptionTemplate').clone();
                    $description.css({ 'display': 'block' });
                    $description.attr('id', dataObject.id);
                    $description.find('.title').html(dataObject.title ? dataObject.title : 'Description');

                    var descriptionDom = $.parseHTML(dataObject.description);
                    var body = $(descriptionDom).find('#bodyContent > p:lt(2)').html(); // for really long EOL blocks

                    if(body) {
                        $description.find('.content').html(body);
                    } else {
                        $description.find('.content').html(dataObject.description);
                    }

                    if(dataObject.source && dataObject.source.trim().length !== 0) {
                        var sourceText = dataObject.source;
                        var sourceHtml = '';

                        if(sourceText.match('^http')) {
                            sourceHtml = '<a href=\'' + sourceText + '\' target=\'eol\'>' + sourceText + '</a>'
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

            var soundsDiv = '<div class="panel panel-default"><div class="panel-heading">';
            soundsDiv += '<h3 class="panel-title">Sounds</h3></div><div class="panel-body">';
            soundsDiv += '<audio controls class="audio-player">';

            soundsDiv += '<source src="' + source + '">';

            soundsDiv += "Your browser doesn't support playing audio</audio>"
            soundsDiv += '</div><div class="panel-footer audio-player-footer"><p>';

            if(data.processed.attribution.collectionName) {
                var source = '';
                var attrUrl = '';
                var attrUrlafix = SHOW_CONF.collectoryUrl + '/public/show/';

                if(data.raw.attribution.dataResourceUid) {
                    attrUrl = attrUrlPrefix + data.raw.attribution.dataResourceUid;
                } else if(data.processed.attribution.collectionUid) {
                    attrUrl = attrUrlPrefix + data.processed.attribution.collectionUid;
                }

                if(data.raw.attribution.dataResourceUid === 'dr341') {
                    // hard-coded copyright as most sounds are from ANWC and are missing attribution data fields
                    source += '&copy; ' + data.processed.attribution.collectionName + ' ' + data.processed.event.year + '<br>';
                }

                if(attrUrl) {
                    source += 'Source: <a href=\'' + attrUrl + '\' target=\'biocache\'>' + data.processed.attribution.collectionName + '</a>';
                } else {
                    source += data.processed.attribution.collectionName;
                }

                soundsDiv += source + '<br />';
            } else if(data.processed.attribution.dataResourceName) {
                soundsDiv += 'Source: ' + data.processed.attribution.dataResourceName;
            }

            soundsDiv += '<a href="' + SHOW_CONF.biocacheUrl + '/occurrence/' + data.raw.uuid + '">View more details of this audio</a>';
            soundsDiv += '</p></div></div>';

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
    loadGalleryType('type', 0)
    loadGalleryType('specimen', 0)
    loadGalleryType('other', 0)
    loadGalleryType('uncertain', 0)
}

var entityMap = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': '&quot;',
    "'": '&#39;',
    "/": '&#x2F;'
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
            alert('Error loading overview image: ' + textStatus + ', ' + error);
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
        alert('Error loading overview images: ' + textStatus + ', ' + error);
    }).always(function() {
        $('#gallerySpinner').hide();
    });
}

function addOverviewImages(imagesArray, hasPreferredImage) {

    if(!hasPreferredImage) {
        // no preferred image so use first in results set
        addOverviewImage(imagesArray[0]);
    }

    for(j = 1; j < 5; j++) {
        // load smaller thumb images
        if(imagesArray.length > j) {
            addOverviewThumb(imagesArray[j], j)
        }
    }
}

function addOverviewImage(overviewImageRecord) {
    $('#noOverviewImages').addClass('hidden-node');
    $('.main-img').removeClass('hidden-node');
    $('.thumb-row').removeClass('hidden-node');
    var $categoryTmpl = $('#overviewImages');
    $categoryTmpl.removeClass('hidden-node');

    var $mainOverviewImage = $('.mainOverviewImage');
    $mainOverviewImage.attr('src', overviewImageRecord.largeImageUrl);
    $mainOverviewImage.parent().attr('href', overviewImageRecord.largeImageUrl);
    $mainOverviewImage.parent().attr('data-footer', getImageFooterFromOccurrence(overviewImageRecord));
    $mainOverviewImage.parent().attr('data-image-id', overviewImageRecord.image);
    $mainOverviewImage.parent().attr('data-record-url', SHOW_CONF.biocacheUrl + '/occurrences/' + overviewImageRecord.uuid);

    $('.mainOverviewImageInfo').html(getImageTitleFromOccurrence(overviewImageRecord));
}

function addOverviewThumb(record, i) {
    if (i < 4) {
        var $thumb = generateOverviewThumb(record, i);
        $('#overview-thumbs').append($thumb);
    } else {
        $('#more-photo-thumb-link').attr('style', 'background-image:url(' + record.smallImageUrl + ')');
    }
}

function generateOverviewThumb(occurrence, id){
    var $taxonSummaryThumb = $('#taxon-summary-thumb-template').clone();
    var $taxonSummaryThumbLink = $taxonSummaryThumb.find('a');
    $taxonSummaryThumb.removeClass('hidden-node');
    $taxonSummaryThumb.attr('id', 'taxon-summary-thumb-' + id);
    $taxonSummaryThumb.attr('style', 'background-image:url(' + occurrence.smallImageUrl + ')');
    $taxonSummaryThumbLink.attr('data-title', getImageTitleFromOccurrence(occurrence));
    $taxonSummaryThumbLink.attr('data-footer', getImageFooterFromOccurrence(occurrence));
    $taxonSummaryThumbLink.attr('href', occurrence.largeImageUrl);
    $taxonSummaryThumbLink.attr('data-image-id', occurrence.image);
    $taxonSummaryThumbLink.attr('data-record-url', SHOW_CONF.biocacheUrl + '/occurrences/' + occurrence.uuid);
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
                // clone template div & populate with metadata
                var $taxonThumb = $('.gallery-thumb-template').clone();
                var $anchor = $taxonThumb.find('a.cbLink');

                $taxonThumb.removeClass('gallery-thumb-template').removeClass('invisible');
                $anchor.attr('id', 'thumb_' + category + i);
                $anchor.attr('href', el.largeImageUrl);
                $anchor.find('img').attr('src', el.smallImageUrl);

                // brief metadata
                var briefHtml = getImageTitleFromOccurrence(el);
                $anchor.find('.gallery-thumb__footer').html(briefHtml);

                // write to DOM
                $anchor.attr('data-footer', getImageFooterFromOccurrence(el));
                $anchor.attr('data-image-id', el.image);
                $anchor.attr('data-record-url', SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid);
                $categoryTmpl.find('.taxon-gallery').append($taxonThumb);
            });

            $('.loadMore.' + category).remove();  // remove 'load more images' button that was just clicked

            if(data.totalRecords > (start + pageSize)) {
                // add new 'load more images' button if required
                var spinnerLink = $('img#gallerySpinner').attr('src');
                var btnLabel = 'Load more';  // ToDo: translation key == general.btn.loadMore
                var btn =
                    '<div class="loadMore ' + category + '">' +
                        '<br />' +
                        '<button type="button" class="erk-button erk-button--light" onCLick="loadGalleryType(\'' + category + '\',' + (start + pageSize) + ');">' +
                            btnLabel + ' <img src="' + spinnerLink + '" class="hidden-node" />' +
                        '</button>' +
                    '</div>';
                $categoryTmpl.find('.taxon-gallery').append(btn);
            }
        }
    }).fail(function(jqxhr, textStatus, error) {
        alert('Error loading gallery: ' + textStatus + ', ' + error);
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
    var rightDetail = '<b>Taxon: </b>' + el.raw_scientificName;
    if(el.typeStatus) { rightDetail += br + '<b>Type: </b>' + el.typeStatus; }
    if(el.collector) { rightDetail += br + '<b>By: </b>' + el.collector; }
    if(el.eventDate) { rightDetail += br + '<b>Date: </b>' + moment(el.eventDate).format('YYYY-MM-DD'); }
    if(el.institutionName && el.institutionName !== undefined) {
        rightDetail += br + '<b>Source: </b>' + el.institutionName;
    } else if(el.dataResourceName) {
        rightDetail += br + '<b>Source: </b>' + el.dataResourceName;
    }
    if(el.imageMetadata && el.imageMetadata.length > 0 && el.imageMetadata[0].rightsHolder !== null) {
        rightDetail += br + '<b>Rights holder: </b>' + el.imageMetadata[0].rightsHolder;
    }
    rightDetail = '<div class="col-sm-8">' + rightDetail + '</div>';

    // write to DOM
    var leftDetail =
        '<div class="col-sm-4 recordLink">' +
            '<a href="' + SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid + '">' +
                'View details of this record' +
            '</a>' +
            '<br />' +
            '<br />' +
            'If this image is incorrectly identified please flag an issue on the ' +
            '<a href=' + SHOW_CONF.biocacheUrl + '/occurrences/' + el.uuid + '>' +
                'record.' +
            '</a>' +
        '</div>';

    var detailHtml = '<div class="row">' + rightDetail + leftDetail + '</div>';
    return detailHtml;
}

function loadBhl() {
    loadBhl(0, 10, false);
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
        if (terms > 2) {
            query += taxonName.split(/\s+/).join(" AND ");
        } else if (terms == 2) {
            query += '"' + taxonName + '"';
        } else {
            query += taxonName;
        }
    }

    if (synonyms) {
        synonyms = synonyms.replace(/\\\"/g,'"'); // remove escaped quotes

        if (taxonName) {
            query += ' OR (' + synonyms + ")"
        } else {
            query += synonyms
        }
    }

    if (!query) {
        return cancelSearch("No names were found to search BHL");
    }

    var url = "http://bhlidx.ala.org.au/select?q=" + query + '&start=' + start + "&rows=" + rows +
        "&wt=json&fl=name%2CpageId%2CitemId%2Cscore&hl=on&hl.fl=text&hl.fragsize=200&" +
        "group=true&group.field=itemId&group.limit=7&group.ngroups=true&taxa=false";

    var buf = "";
    $("#status-box").css("display", "block");
    $("#synonyms").html("").css("display", "none")
    $("#bhl-results-list").html("");

    $.ajax({
        url: url,
        dataType: 'jsonp',
        jsonp: "json.wrf",
        success:  function(data) {
            var itemNumber = parseInt(data.responseHeader.params.start, 10) + 1;
            var maxItems = parseInt(data.grouped.itemId.ngroups, 10);
            if (maxItems == 0) {
                return cancelSearch("No references were found for <pre>" + query + "</pre>");
            }
            var startItem = parseInt(start, 10);
            var pageSize = parseInt(rows, 10);
            var showingFrom = startItem + 1;
            var showingTo = (startItem + pageSize <= maxItems) ? startItem + pageSize : maxItems ;
            buf += '<div class="results-summary">Showing ' + showingFrom + " to " + showingTo + " of " + maxItems +
                ' results for the query <pre>' + query + '</pre></div>'
            // grab highlight text and store in map/hash
            var highlights = {};
            $.each(data.highlighting, function(idx, hl) {
                highlights[idx] = hl.text[0];
            });
            //console.log("highlighting", highlights, itemNumber);
            $.each(data.grouped.itemId.groups, function(idx, obj) {
                buf += '<div class="result">';
                buf += '<h3><b>' + itemNumber++;
                buf += '.</b> <a target="item" href="http://biodiversitylibrary.org/item/' + obj.groupValue + '">' + obj.doclist.docs[0].name + '</a> ';
                var suffix = '';
                if (obj.doclist.numFound > 1) {
                    suffix = 's';
                }
                buf += '(' + obj.doclist.numFound + '</b> matching page' + suffix + ')</h3><div class="thumbnail-container">';

                $.each(obj.doclist.docs, function(idx, page) {
                    var highlightText = $('<div>'+highlights[page.pageId]+'</div>').htmlClean({allowedTags: ["em"]}).html();
                    buf += '<div class="page-thumbnail"><a target="page image" href="http://biodiversitylibrary.org/page/' +
                        page.pageId + '"><img src="http://biodiversitylibrary.org/pagethumb/' + page.pageId +
                        '" alt="' + escapeHtml(highlightText) + '"  width="60px" height="100px"/></a></div>';
                })
                buf += "</div><!--end .thumbnail-container -->";
                buf += "</div>";
            })

            var prevStart = start - rows;
            var nextStart = start + rows;

            buf += '<div id="button-bar">';
            if (prevStart >= 0) {
                buf += '<input type="button" class="btn" value="Previous page" onclick="loadBhl(' + prevStart + ',' + rows + ', true)">';
            }
            buf += '&nbsp;&nbsp;&nbsp;';
            if (nextStart <= maxItems) {
                buf += '<input type="button" class="btn" value="Next page" onclick="loadBhl(' + nextStart + ',' + rows + ', true)">';
            }

            buf += '</div>';

            $("#bhl-results-list").html(buf);
            if (data.synonyms) {
                buf = "<b>Synonyms used:</b>&nbsp;";
                buf += data.synonyms.join(", ");
                $("#synonyms").html(buf).css("display", "block");
            } else {
                $("#synonyms").html("").css("display", "none");
            }
            $("#status-box").css("display", "none");

            if (scroll) {
                $('html, body').animate({scrollTop: '300px'}, 300);
            }
        },
        error: function(jqXHR, textStatus, errorThrown) {
            $("#status-box").css("display", "none");
            $("#solr-results").html('An error has occurred, probably due to invalid query syntax');
        }
    });
} // end doSearch

function cancelSearch(msg) {
    $("#status-box").css("display", "none");
    $("#solr-results").html(msg);
    return true;
}

function loadExpertDistroMap() {
    var url = SHOW_CONF.layersServiceUrl + '/distribution/map/' + SHOW_CONF.guid + '?callback=?';
    $.getJSON(url, function(data) {
        if(data.available) {
            $('#expertDistroDiv img').attr('src', data.url);
            if(data.dataResourceName && data.dataResourceUrl) {
                var attr = $('<a>').attr('href', data.dataResourceUrl).text(data.dataResourceName)
                $('#expertDistroDiv #dataResource').html(attr);
            }
            $('#expertDistroDiv').show();
        }
    });
}

function toggleImageGallery(btn) {
    if($(btn).hasClass('fa-caret-square-o-up')) {
        $(btn).removeClass('fa-caret-square-o-up');
        $(btn).addClass('fa-caret-square-o-down');
        $(btn).parents('.image-section').find('.taxon-gallery').slideUp(400)
    } else {
        $(btn).removeClass('fa-caret-square-o-down');
        $(btn).addClass('fa-caret-square-o-up');
        $(btn).parents('.image-section').find('.taxon-gallery').slideDown(400);
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

    var count = 0;
    var currentPage = 0;
    var pageCount = 0;
    var loadPage;

    function showPage(pageNumber, page) {
        $list.empty();

        page.forEach(function(occurrence) {
            var el = $(
                '<li class="plutof-references__item">' +
                    '<h3 class="plutof-references__header">' +
                        '<a href="https://plutof.ut.ee/#/referencebased/view/' + occurrence.id + '">' +
                            occurrence.reference +
                        '</a>' +
                    '</h3>' +
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

            $entry.attr('id', 'sequence-' + $entry.attr('id'));
            $entry.removeAttr('id'); // Do not clone the ID.
            $entry.find('.externalLink').attr('href', 'https://plutof.ut.ee/#/sequence/view/' + entry.id);
            $entry.find('.externalLink').html(entry.name);

            if(entry.sequence_types) {
                content += 'Sequenced regions: ' + entry.sequence_types + '<br>';
            }

            if(entry.gathering_agents) {
                content += 'Collected by: ' + [entry.gathering_agents].join(', ') + '<br>';
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
