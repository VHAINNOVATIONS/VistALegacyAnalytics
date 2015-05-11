xquery version "1.0-ml";
(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

(:
 : This layout is used for pages where search widgets are unavailable.
 : For example, a login form.
 : There are no tabs either.
 :)

import module namespace c = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";
import module namespace uv = "http://www.marklogic.com/roxy/user-view"
  at "/app/views/helpers/user-lib.xqy";

declare variable $view as item()* := vh:get("view") ;
declare variable $title as xs:string? := vh:get("title") ;

'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>{$title}</title>
    <link href="/css/themes/smoothness/jquery-ui.css" type="text/css" rel="stylesheet"/>
    <link href="/css/three-column.less" type="text/css" rel="stylesheet/less"/>
    <link href="/css/app.less" type="text/css" rel="stylesheet/less"/>
    <link href="/css/jquery.dataTables.css" type="text/css" rel="stylesheet/less"/>
    <script type="text/javascript">
      less = {{ env: {
        (: This is XQuery - confused? :)
        concat(
          '"',
          xdmp:quote(
            if ($c:ENVIRONMENT = ('development', 'local')) then "development"
            else "production"),
          '"') } }};
    </script>
{ $vh:HEAD-SCRIPTS }
  </head>

  <body>

    <div id="header">
      <a href="/" class="logo"/>
      <h1><a href="/">{$title}</a></h1>
    </div>

  { $view }

    <div id="footer">

    </div>

  </body>

</html>

(: layouts/minimal.html.xqy :)
