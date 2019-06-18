class UrlMappings {

	static mappings = {
        "/" (controller: "species", action: "search")

        "/proxy/biocache-service/$path**" (controller: "proxy") {
            action = [GET:'doGet']
        }

        "/proxy/plutof/$path**" (controller: "plutof") {
            action = [GET: "doGet"]
        }

        "/$controller/$action?/$id?(.$format)?" {
            constraints {
                // apply constraints here
            }
        }

        "/species/$guid**"(controller: "species", action: "show")
        "/geo"(controller: "species", action: "geoSearch")
        "/search" (controller: "species", action: "search")
        "/image-search"(controller: "species", action: "imageSearch")
        "/image-search/showSpecies"(controller: "species", action: "imageSearch")
        "/image-search/infoBox"(controller: "species", action: "infoBox")
        "/image-search/$id"(controller: "species", action: "imageSearch")
        "/bhl-search"(controller: "species", action: "bhlSearch")
        "/sound-search"(controller: "species", action: "soundSearch")
        "/logout"(controller: "species", action: "logout")
        "/"(view:"/index")

        name search: "/search" {
            controller = "species"
            action = "search"
        }

        "500" (view: "/error")
	}
}
