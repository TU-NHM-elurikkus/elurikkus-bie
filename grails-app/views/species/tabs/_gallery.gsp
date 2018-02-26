<section class="tab-pane" id="tab-gallery" role="tabpanel">
    <g:each in="${["observation", "specimen", "type", "other"]}" var="cat">
        <div id="cat_${cat}" class="hidden-node image-section">
            <h3>
                <a href="javascript:void(0)" onclick="toggleImageGallery(this)" class="undecorated">
                    <g:message code="images.heading.${cat}" default="${cat}" />
                    <span class="fa fa-caret-square-o-up"></span>
                </a>
            </h3>

            <div class="taxon-gallery"></div>
        </div>
    </g:each>

    <div id="cat_nonavailable">
        <h3>
            <g:message code="show.gallery.noImages" />
        </h3>

        <p>
            <g:message code="show.gallery.upload.desc" />
        </p>
    </div>

    <img
        id="gallerySpinner"
        src="${assetPath(src: 'spinner.gif', plugin: 'biePlugin')}"
        class="hidden-node"
        alt="spinner icon"
    />

</section>
