//= require common
//= require jquery.sortElemets
//= require jquery.htmlClean
//= require jquery.jsonp-2.3.1.min
//= require leaflet
//= require ekko-lightbox-5.2.0
//= require moment.min
//= require ala-charts
//= require species.show
//= require search

$(function() {
    // Sticky footer
    var footerHeight = $('.site-footer').outerHeight();
    var imageId, attribution, recordUrl;
    $('.wrap').css('margin-bottom', -footerHeight);
    $('.push').height(footerHeight);

    // Lightbox
    $(document).delegate('*[data-toggle="lightbox"]', 'click', function(event) {
        event.preventDefault();
        switch(SHOW_CONF.imageDialog) {
            case 'MODAL':
                $(this).ekkoLightbox();
                break;
            case 'LEAFLET':
                imageId = $(this).attr('data-image-id');
                attribution = $(this).attr('data-footer');
                recordUrl = $(this).attr('data-record-url');
                setDialogSize();
                $('#imageDialog').modal('show');
                break;
        }
    });

    // show image only after modal dialog is shown. otherwise, image position will be off the viewing area.
    $('#imageDialog').on('shown.bs.modal', function() {
        imgvwr.viewImage($('#viewerContainerId'), imageId, SHOW_CONF.scientificName, SHOW_CONF.guid, {
            imageServiceBaseUrl: SHOW_CONF.imageServiceBaseUrl,
            addSubImageToggle: false,
            addCalibration: false,
            addDrawer: false,
            addCloseButton: true,
            addAttribution: true,
            addLikeDislikeButton: true,
            addPreferenceButton: SHOW_CONF.addPreferenceButton,
            attribution: attribution,
            disableLikeDislikeButton: SHOW_CONF.disableLikeDislikeButton,
            likeUrl: SHOW_CONF.likeUrl + '?id=' + imageId,
            dislikeUrl: SHOW_CONF.dislikeUrl + '?id=' + imageId,
            userRatingUrl: SHOW_CONF.userRatingUrl + '?id=' + imageId,
            userRatingHelpText: SHOW_CONF.userRatingHelpText.replace('RECORD_URL', recordUrl),
            savePreferredSpeciesListUrl: SHOW_CONF.savePreferredSpeciesListUrl + '?id=' + imageId + '&scientificName=' + SHOW_CONF.scientificName,
            getPreferredSpeciesListUrl: SHOW_CONF.getPreferredSpeciesListUrl
        });
    });

    // set size of modal dialog during a resize
    $(window).on('resize', setDialogSize);
    function setDialogSize() {
        var height = $(window).height();
        height *= 0.8;
        $('#viewerContainerId').height(height);
    }

    // Search: Refine results accordions
    $('.refine-box h2 a').click(function() {
        $(this).children('.glyphicon').toggleClass('glyphicon-chevron-down glyphicon-chevron-up');
    });

    $('a.expand-options').click(function() {
        $(this).text(function(i, text) {
            return text.trim() === 'More' ? 'Less' : 'More';
        });
    });
});
