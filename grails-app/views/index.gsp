<%@ page contentType="text/html;charset=UTF-8" %>

<html>
    <head>
        <meta name="layout" content="${grailsApplication.config.skin.layout}" />
        <title>
            Biodiversity Information Explorer
        </title>
    </head>

    <body>
        <div class="container-fluid">
            <header class="page-header">
                <h1 class="page-header__title">
                    Search for Taxa
                </h1>
            </header>

            <div class="section">
                <g:render template="species/searchBox" />
            </div>
        </div>
    </body>
</html>
