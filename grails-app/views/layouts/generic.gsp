<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <g:render template="/manifest" plugin="elurikkus-commons" />

        <title>
            <g:layoutTitle />
        </title>

        <r:require modules="jquery, searchOverride" />
        <r:require modules="menu", plugin="elurikkus-commons" />

        <r:layoutResources />

        <g:layoutHead />
    </head>

    <body>
        <g:render template="/menu" plugin="elurikkus-commons" />

        <div class="wrap">
            <g:layoutBody />
        </div>

        <g:render template="/footer" plugin="elurikkus-commons" />

        <r:layoutResources />
    </body>
</html>
