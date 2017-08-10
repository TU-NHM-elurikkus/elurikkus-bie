modules = {
    application {
        resource url: [dir: 'js', file: 'application.js', plugin:'bie-plugin']
    }

    searchOverride {
        resource url: [dir: 'js', file: 'jquery.sortElemets.js', plugin:'bie-plugin']
        resource url: [dir: 'js', file: 'search.js']
        resource id: 'atlas', url: [dir: 'css', file: 'atlas.css']
        resource "/css/atlas.css"
    }

    myatlas {
        resource id: 'atlas', url: [dir: 'css', file: 'atlas.css']
    }

    showDependencies {
        dependsOn 'cleanHtml, ekko'

        resource url:[dir:'js/leaflet', file:'leaflet.css', plugin:'bie-plugin'], attrs: [ media: 'all' ]
        resource url:[dir:'js/leaflet', file:'leaflet.js', plugin:'bie-plugin']

        resource url: [dir: 'css', file: 'jquery.qtip.min.css', plugin:'bie-plugin']

        resource url: [dir: 'js', file: 'jquery.sortElemets.js', plugin:'bie-plugin', disposition: 'head']
        resource url: [dir: 'css', file: 'species.css', plugin:'bie-plugin']
        resource url: [dir: 'js', file: 'jquery.qtip.min.js', plugin:'bie-plugin', disposition: 'head']
        resource url: [dir: 'js', file: 'moment.min.js', plugin:'bie-plugin', disposition: 'head']
        resource url: [dir: 'js', file: 'audio.min.js', plugin:'bie-plugin', disposition: 'head']
        // Note: this should be last, because it doesn't end with color or newline. Grails resource
        // plugin just smacks everything together, leading to the return value of jquery.json module
        // (which is undefined probably) be applied to the next module...
        resource url: [dir: 'js', file: 'jquery.jsonp-2.3.1.min.js', plugin:'bie-plugin', disposition: 'head']
    }

    showOverride {
        dependsOn 'showDependencies'

        resource url: [dir: 'js', file: 'species.show.js', disposition: 'head']
    }

    cleanHtml {
        resource url: [dir: 'js', file: 'jquery.htmlClean.js', plugin:'bie-plugin', disposition: 'head']
    }

    ekko {
        resource url: [dir: 'css', file: 'ekko-lightbox.css', plugin:'bie-plugin']
        resource url: [dir: 'js', file: 'ekko-lightbox.min.js', plugin:'bie-plugin']
    }
}
