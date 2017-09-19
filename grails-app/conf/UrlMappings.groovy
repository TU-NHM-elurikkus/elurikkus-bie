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

        "/download/$root/$path**" (controller: "file")

        "500" (view: "/error")
	}
}
