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

declare default element namespace "http://www.w3.org/1999/xhtml" ;

import module namespace c = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";

import module namespace uv = "http://www.marklogic.com/roxy/user-view"
  at "/app/views/helpers/user-lib.xqy";

import module namespace facet = "http://marklogic.com/roxy/facet-lib"
  at "/app/views/helpers/facet-lib.xqy";
import module namespace thl = "http://marklogic.com/roxy/tabs-lib"
  at "/app/views/helpers/tabs-lib.xqy";
import module namespace lh = "http://www.marklogic.com/roxy/view-helper/layout"
  at "/app/views/helpers/layout-lib.xqy";

declare variable $mature as xs:boolean := (vh:get("mature"), false())[1];
declare variable $q as xs:string? := vh:get("q");
declare variable $scripts as item()* := vh:get("scripts");
declare variable $title as xs:string? := vh:get("title");
declare variable $view as item()* := vh:get("view");
declare variable $search-form :=
  <form id="searchform" name="searchform" method="GET" action="/" /> ;
declare variable $wide-form as xs:boolean := (vh:get('wide-form'), false())[1] ;

'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=8" />
    <title>{$title}</title>
    <link href="/css/themes/smoothness/jquery-ui.css" type="text/css" rel="stylesheet"/>
    <link href="/css/three-column.less" type="text/css" rel="stylesheet/less"/>
    <link href="/css/app.less" type="text/css" rel="stylesheet/less"/>
    <link href="/css/jquery.dataTables.css" type="text/css" rel="stylesheet/less"/>
    {vh:get("view-css")}
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
    <script src="/js/three-column.js" type='text/javascript'></script>
{
  $scripts ! element script {
    attribute type { 'text/javascript' },
    attribute src { . } }
}
  </head>

  <body>
{
  (: Either wrap the entire page, or only the search widget. :)
  lh:maybe-wrap(
    $wide-form,
    $search-form,
    (<div id="header">
      <a href="/" class="logo"/>
      <h1><a href="/">{$title}</a></h1>
      {
        uv:build-user(),

        lh:maybe-wrap(
          not($wide-form),
          $search-form,
          <div class="search">
            <label>Search</label>
            <div class="searchbox">
              <input accesskey="s" type="text" id="q" name="q" class="searchbox"
          value="{$q}"/>
              <button type="submit" title="Run Search">
                <img src="/images/mt_icon_search.gif"/>
              </button>
              <div id="suggestions"><!--suggestions here--></div>
            </div>
            </div>),

        (: Optional top-level tabs. :)
        thl:maybe-wrap(
          $c:TABS-TOP,
          vh:get("tab-active"),
          (: Pass query through for reports. :)
          facet:query-string('mature='||$mature, $q))
      }
      </div>,
      $view))
}
  </body>
{vh:get("view-js")}
</html>
