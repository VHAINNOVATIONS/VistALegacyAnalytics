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
xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/appbuilder";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: the controller helper library provides methods to control which view and template get rendered :)
import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace facet = "http://marklogic.com/roxy/facet-lib"
  at "/app/views/helpers/facet-lib.xqy";

(: The request library provides awesome helper methods to abstract get-request-field :)
import module namespace req = "http://marklogic.com/roxy/request"
  at "/roxy/lib/request.xqy";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace patient-lib = "ns://va.gov/2012/ip401/patient"
  at "/app/models/patient-lib.xqy";

import module namespace search-lib="ns://va.gov/2012/ip401/search-lib"
  at "/lib/search-lib.xqy";

import module namespace search="http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace cfg = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";
import module namespace vpr = "ns://va.gov/2012/ip401/vpr"
  at "/lib/vpr.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util"
  at "/lib/util.xqy";
import module namespace saved-search = "http://marklogic.com/roxy/models/saved-search" at "/app/models/saved-search.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare option xdmp:mapping "false";

declare variable $Q := string-join(req:get("q", "", "type=xs:string"), ' ') ;

declare variable $MATCHES as xs:string := req:get("matches", "any", "type=xs:string") ;
declare variable $MATCHES-HREF := (
  'matches='||$MATCHES
  ||'&amp;mature='||xs:string($MATURE)
  ||'&amp;subtab='||xs:string($SUBTAB-ACTIVE)) ;
declare variable $MATURE := req:get('mature', false(), 'type=xs:boolean') ;
declare variable $PAGE := req:get("page", 1, "type=xs:int") ;
declare variable $PAGE-START := ($PAGE - 1) * $cfg:DEFAULT-PAGE-LENGTH + 1 ;
declare variable $SUBTAB-ACTIVE := req:get('subtab', 1, "type=xs:integer") ;
(: We only need results for the results subtab. :)
declare variable $DISPLAY-FACETS :=
  let $cookies := xdmp:get-request-header('Cookie', '')
  let $facets :=
    if ($cookies != '') then
      fn:tokenize($cookies, '; ') !  (if (fn:starts-with(., "facets=")) then fn:tokenize(fn:substring-after(., "facets="), "%20") else ())
    else
      ()
  return if ($facets) then
      $facets
    else
      (
        xdmp:add-response-header("Set-Cookie", "facets=" || fn:string-join($cfg:DEFAULT-FACETS, " ")),
        $cfg:DEFAULT-FACETS
      )
;

declare variable $SEARCH-OPTIONS := cfg:search-options(
  $MATURE, ($SUBTAB-ACTIVE eq 2)) ;
declare variable $OPTIONS :=
  c:update-search-options($SEARCH-OPTIONS)
;
declare variable $QUERY as element() := (
  let $query := search:parse($Q, $OPTIONS)
  (: If needed for notes pseudo-facet, rewrite the query. :)
  return (
    if ($MATCHES eq 'any') then $query
    else if ($MATCHES eq 'structured') then c:matches-structured-query($query)
    else c:matches-unstructured-query($query))) ;
declare variable $CTS-QUERY := if (not($Q)) then () else cts:query($QUERY) ;

declare variable $SUBTABS :=
<tabset xmlns="http://marklogic.com/roxy/config">
  <tab href="/?subtab=1">Summary</tab>
  <tab href="/appbuilder/detail.html?subtab=2">Results</tab>
  <tab href="/?subtab=3">Map</tab>
</tabset> ;

declare variable $_user := xdmp:get-current-user();

declare function c:update-search-options($n as node()+) as node()
{
  $n ! (
    typeswitch(.)
      case element(search:options) return <search:options>{c:update-search-options(./node())}</search:options>
      case element(search:constraint)
        return
        if (fn:not(node()/@facet)) then
            .
        else
          let $child := node()
          let $name := @name
          return
          if ($name = ($DISPLAY-FACETS, $cfg:SYSTEM-FACETS)) then .
          else
            <constraint name="{$name}">{functx:update-attributes($child, xs:QName("facet"), "false")}</constraint>
      default return .
  )
};

(: Co-recursion helper.
 : For this and the other c:matches-*-query functions
 : it would be nice to enforce schema-element(cts:query)
 : on inputs and outputs. But the schema cts.xsd
 : omits some important elements from the base type.
 : cf SUPPORT-12797
 :)
declare private function c:matches-structured-query2(
  $q as element())
as element()
{
  element { node-name($q) } {
    $q/@*,
    $q/node()/c:matches-structured-query(.) }
};

declare function c:matches-structured-query(
  $queries as element()+)
as element()*
{
  $queries ! (
    typeswitch(.)

    (: Limit to structured text elements only. :)
    case element(cts:word-query) return document {
      cts:and-not-query(
        cts:query(.),
        cts:element-word-query(
          xs:QName("va:content"), cts:text,
          (cts:option, cts:text/@lang ! ('lang='||.)),
          @weight)) }/*

    (: Recurse as needed. :)
    case element(cts:and-query) return c:matches-structured-query2(.)
    case element(cts:and-not-query) return c:matches-structured-query2(.)
    case element(cts:near-query) return c:matches-structured-query2(.)
    case element(cts:not-query) return c:matches-structured-query2(.)
    case element(cts:not-in-query) return c:matches-structured-query2(.)
    case element(cts:properties-query) return c:matches-structured-query2(.)
    case element(cts:or-query) return c:matches-structured-query2(.)

    (: Pass others through.
     : This includes geospatial, range, element-word, etc.
     : because they cannot match structured text.
     :)
    case element(cts:text) return .
    case element() return .
    default return .)
};

(: Co-recursion helper. :)
declare private function c:matches-unstructured-query2(
  $q as element())
as element()
{
  element { node-name($q) } {
    $q/@*,
    $q/node()/c:matches-unstructured-query(.) }
};

declare function c:matches-unstructured-query(
  $queries as element()+)
as element()*
{
  $queries ! (
    typeswitch(.)
    (: Limit to unstructured text elements only.
     : There will be no query annotations on this term.
     :)
    case element(cts:word-query) return document {
      cts:element-word-query(xs:QName("va:content"), cts:text) }/*

    (: Recurse as needed. :)
    case element(cts:and-query) return c:matches-unstructured-query2(.)
    case element(cts:and-not-query) return c:matches-unstructured-query2(.)
    case element(cts:near-query) return c:matches-unstructured-query2(.)
    case element(cts:not-query) return c:matches-unstructured-query2(.)
    case element(cts:not-in-query) return c:matches-unstructured-query2(.)
    case element(cts:properties-query) return c:matches-unstructured-query2(.)
    case element(cts:or-query) return c:matches-unstructured-query2(.)

    (: Pass others through. :)
    case element() return .
    default return .)
};

declare function c:matches-structured(
  $matches as xs:string,
  $query as schema-element(cts:query)?,
  $options as element(search:options))
as xs:integer?
{
  if (not($matches = 'any')) then ()
  else if (empty($query)) then ()
  else c:matches-structured-query($query) ! xdmp:estimate(
    cts:search(
      collection(),
      cts:and-query(($options/search:additional-query/* ! cts:query(.), cts:query(.)))))
};

declare function c:matches-unstructured(
  $matches as xs:string,
  $query as schema-element(cts:query)?,
  $options as element(search:options))
as xs:integer?
{
  if (not($matches = 'any')) then ()
  else if (empty($query)) then ()
  else c:matches-unstructured-query($query) ! xdmp:estimate(
    cts:search(
      collection(),
      cts:and-query(($options/search:additional-query/* ! cts:query(.), cts:query(.)))))
};

(:
 : Usage Notes:
 :
 : use the ch library to pass variables to the view
 :
 : use the request (req) library to get access to request parameters easily
 :
 :)
declare function c:autocomplete() as item()*
{
  (: Limit to ontology items that have data associated with them :)
  let $label-matches := cts:element-attribute-value-match(
    xs:QName("on:concept"), xs:QName("label"),
    "*"||$Q||"*", ("map"),
    vpr:site-query())
  return ch:set-value("results", $label-matches)
};

declare function c:timeline() as item()* {
  let $uri := req:get("uri", "", "type=xs:string")
  let $paths := (
    <series><name>Vitals</name><path>//va:vitals/va:vital</path><date-path>va:entered</date-path></series>,
    <series><name>Procedures</name><path>//va:procedures/va:procedure</path><date-path>va:dateTime</date-path></series>,
    <series><name>Labs</name><path>//va:labs/va:lab</path><date-path>va:collected</date-path></series>,
    <series><name>Appointments</name><path>//va:appointments/va:appointment</path><date-path>va:dateTime</date-path></series>
  )
  let $data :=
    <json xmlns="http://marklogic.com/xdmp/json/basic" type="array">
      {
        for $series at $i in $paths
        let $sections := xdmp:unpath(fn:concat("fn:doc('", $uri, "')", fn:string($series/*:path)))
        return
          <json type="object">
            <name type="string">{$series/*:name}</name>
            <color type="string">rgba(223, 83, 83, .5)</color>
            <data type="array">
              {
                for $section in $sections
                return
                  <data type="array">
                    <item type="number">{xdmp:unpath(fn:concat(xdmp:path($section, fn:true()), "/", fn:string($series/*:date-path)))}</item>
                    <item type="number">{$i}</item>
                  </data>
              }
            </data>
          </json>
      }
    </json>
  return ch:set-value("timeline-series-data", $data)
};

declare function c:patient() as item()*
{

  let $id := req:get("id", "", "type=xs:string")
  let $site := req:get("site", "", "type=xs:string")

  let $doc-uri :=  '/vpr/' || $site || '/' || $id
  let $patient := fn:doc($doc-uri)/va:vpr

  return (
    ch:set-value("doc-uri", $doc-uri),
    ch:set-value("patient", $patient),
    ch:set-value("site", $site),
    ch:set-value('title', 'VistA Analytics'),
    ch:use-layout("full-page", "html")
  )
};

declare function c:patient-category() as item()*
{
  let $id := req:get("id", "", "type=xs:string")
  let $site := req:get("site", "", "type=xs:string")
  let $doc-uri :=  '/vpr/' || $site || '/' || $id
  let $patient := fn:doc($doc-uri)/va:vpr
  let $category := req:get('cat')
  return (
    ch:set-value("doc-uri", $doc-uri),
    ch:set-value("patient", $patient),
    ch:set-value('cat', $category),
    ch:use-layout((), "html"),
    ch:use-layout((), "json")
  )
};

declare function c:raw() as item()*
{
  let $path := req:get("path", "", "type=xs:string")
  let $node := xdmp:unpath($path)
  let $patient := fn:substring-after($node/base-uri(), '/')
  let $patient-str := fn:string-join(fn:tokenize($patient, '/'), '_')
  let $filename :=
    if (fn:ends-with($path, '.')) then
      fn:concat($patient-str, '.xml')
    else
      fn:concat($patient-str, '_', fn:local-name($node), '.xml')
  return (
    ch:set-value("path", $path),
    ch:set-value("filename", $filename),
    ch:use-layout("", "xml")
  )
};

declare function c:render-xml() as item()*
{
  let $path := req:get("path", "", "type=xs:string")
  return (
    ch:set-value("path", $path),
    ch:use-layout("", "html")
  )
};

declare function c:pseudo-facets(
  $response as element(search:response))
as element(facet:pseudo-facet)*
{
  (: Create Source pseudo-facet. :)
  if (not($Q)) then ()
  else element facet:pseudo-facet {
    attribute name { 'source' },
    if (not($MATCHES eq "any")) then (
      attribute selected { $MATCHES },
      (: This href will remove the constraint. :)
      attribute href {
        facet:query-string(
          ('matches=any',
            'mature='||xs:string($MATURE)),
          $Q) })
    else (
      let $count := c:matches-structured($MATCHES, $QUERY, $OPTIONS)
      return (
        element facet:value {
          attribute name { 'unstructured' },
          (: This href will add the constraint. :)
          attribute href {
            facet:query-string(
              ('matches=unstructured',
                'mature='||xs:string($MATURE)),
              $Q) },
          attribute count { $response/@total - $count } },
        element facet:value {
          attribute name { 'structured' },
          (: This href will add the constraint. :)
          attribute href {
            facet:query-string(
              ('matches=structured',
                'mature='||xs:string($MATURE)),
              $Q) },
          attribute count { $count } })) }
};

(: literal/Google-like search results :)
declare function c:detail() as item()*
{
  ch:set-value('matches', $MATCHES),
  ch:set-value("mature", $MATURE),
  ch:set-value("page", $PAGE),
  ch:set-value("q", $Q),
  ch:set-value("query", $QUERY),
  (: Must $search-lib:HIGHLIGHT-QUERY so we have highlighting. :)
  search-lib:highlight-query-set($QUERY),
  ch:set-value(
    "response",
    search:resolve(
      $QUERY, $OPTIONS,
      $PAGE-START,
      $cfg:DEFAULT-PAGE-LENGTH)),
  ch:set-value('search-options', $OPTIONS),
  ch:set-value('subtabs', $SUBTABS),
  ch:set-value('subtab-active', 2),
  ch:set-value('tab-active', 1),
  ch:set-value('title', 'VistA Analytics'),
  ch:set-value("wide-form", true()),
  (: Requires earlier values. :)
  ch:set-value("pseudo-facets", c:pseudo-facets(ch:get('response'))),
  ch:add-value('additional-js', <script src="/js/date-facet.js">&nbsp;</script>),
  ch:use-layout("two-column", "html")
};

declare function c:main() as item()*
{
  ch:set-value('matches-href', $MATCHES-HREF),
  ch:set-value('matches', $MATCHES),
  ch:set-value("mature", $MATURE),
  ch:set-value("q", $Q),
  ch:set-value("query", $QUERY),
  ch:set-value(
    "response",
    search:resolve($QUERY, $OPTIONS, $PAGE-START, $cfg:DEFAULT-PAGE-LENGTH)),
  ch:set-value("search-options", $OPTIONS),
  ch:set-value('subtabs', $SUBTABS),
  ch:set-value('subtab-active', $SUBTAB-ACTIVE),
  ch:set-value('tab-active', 1),
  ch:set-value('title', 'VistA Analytics'),
  ch:set-value("wide-form", true()),
  (: Requires earlier values. :)
  ch:set-value("pseudo-facets", c:pseudo-facets(ch:get('response'))),
  ch:add-value('additional-js', <script src="/js/date-facet.js">&nbsp;</script>),
  ch:use-layout("two-column", "html")
};

(: Support ajax requests for heatmap, via views/map.json.xqy :)
declare function c:map() as item()*
{
  (: Omit results and all non-map facets.
   : Supports request params that describe the current map viewport.
   : These become attributes for the heatmap option.
   : Pagination should not matter.
   : Separate options needed, so we can supply map bounds.
   :)
  ch:set-value('matches-href', $MATCHES-HREF),
  ch:set-value("q", $Q),
  ch:set-value("query", $QUERY),
  let $options := cfg:search-options(
    $MATURE, false(),
    req:get("sidebar", false(), "type=xs:boolean"),
    req:get("facet", "facility-loc", "type=xs:string"),
    (req:get("n", 90, "type=xs:double"),
      req:get("s", -90, "type=xs:double"),
      req:get("e", 180, "type=xs:double"),
      req:get("w", -180, "type=xs:double")))
  let $_ := ch:set-value("search-options", $options)
  return ch:set-value("response",
    search:resolve($QUERY, $options, $PAGE-START, $cfg:DEFAULT-PAGE-LENGTH))
  ,
  (: Requires earlier values. :)
  ch:set-value("pseudo-facets", c:pseudo-facets(ch:get('response')))
};

declare function c:aggregate-timeline() as item()*
{
  let $base-paths := $patient-lib:PATIENT-EXTRACTS
  let $start-date := req:get("start", xs:dateTime("1960-01-01T00:00:00"), "type=xs:dateTime")
  let $end-date := req:get("end", xs:dateTime("2013-01-01T00:00:00"), "type=xs:dateTime")
  let $duration := xs:int(fn:days-from-duration($end-date - $start-date) div 20)
  let $duration := xs:dayTimeDuration(fn:concat("P", fn:string(req:get("duration", $duration, "xs:int")), "D"))
  let $granularity := "day"
  let $counts := map:map()
  let $build-map :=
    for $field in $base-paths//fields[descendant::type = 'date']
    let $base-path := $field/@path
    let $path := fn:concat('/va:vpr', $base-path)
    let $date-path := fn:concat($path, fn:string(($field/field[type = 'date']/path)[1]))
    let $name := fn:string($field/@name)
    let $log := xdmp:log(text{$name, $date-path})
    return map:put($counts, $name, util:count-events($CTS-QUERY, $start-date, $end-date, $granularity, $date-path))
  return (
    ch:set-value("counts", $counts),
    ch:use-layout((), "json")
  )
};

declare function c:results-diag-table() as item()*
{
  let $input-query := $QUERY
  let $start := req:get("iDisplayStart", 0, "type=xs:integer") + 1
  let $end := $start + req:get("iDisplayLength", 10, "type=xs:integer") - 1
  let $sortcol := req:get("iSortCol_0", 0, "type=xs:integer") + 1
  let $sortdir := req:get("sSortDir_0", "asc", "type=xs:string")
  let $echo := req:get("sEcho", 1, "type=xs:integer")
  let $search := req:get("sSearch", "", "type=xs:string")

  let $table-map := patient-lib:build-result-table(cts:element-reference(xs:QName("va:reason-code")), $input-query)
  let $table :=
    for $key in map:keys($table-map)
    let $rowmap := map:get($table-map, $key)
    let $fix_rowmap :=
      for $key in ($patient-lib:GENDERS, $patient-lib:RACES, $patient-lib:AGES)
      return if (map:contains($rowmap, $key)) then () else map:put($rowmap, $key, 0)

    (: look up the description for this code, and display the description instead of the code :)
    let $description :=  cts:element-attribute-values(xs:QName("on:concept"),
      xs:QName("description"), (), (), cts:element-attribute-range-query(xs:QName("on:concept"), xs:QName("code"), "=", $key))[1]
    let $_ := map:put($rowmap, 'key', $description)
    let $orders := ($key, $patient-lib:GENDERS ! (map:get($rowmap, .)), $patient-lib:RACES ! (map:get($rowmap, .)), $patient-lib:AGES ! (map:get($rowmap, .)))
    order by if ($sortdir eq "asc") then $orders[$sortcol] else () ascending, if ($sortdir eq "asc") then () else $orders[$sortcol] descending
    return if (fn:matches($key, $search, ("i"))) then $rowmap else ()
  return (
    ch:set-value("table", $table[$start to $end]),
    ch:set-value("total", map:count($table-map)),
    ch:set-value("total-display", fn:count($table)),
    ch:set-value("echo", $echo),
    ch:use-view("appbuilder/results-table"),
    ch:use-layout(())
  )
};

declare function c:results-rx-table() as item()*
{
  let $input-query := $QUERY
  let $start := req:get("iDisplayStart", 0, "type=xs:integer") + 1
  let $end := $start + req:get("iDisplayLength", 10, "type=xs:integer") - 1
  let $sortcol := req:get("iSortCol_0", 0, "type=xs:integer") + 1
  let $sortdir := req:get("sSortDir_0", "asc", "type=xs:string")
  let $echo := req:get("sEcho", 1, "type=xs:integer")
  let $search := req:get("sSearch", "", "type=xs:string")

  let $table-map := patient-lib:build-result-table(cts:element-reference(xs:QName("va:med-name")), $input-query)
  let $table :=
    for $key in map:keys($table-map)
    let $rowmap := map:get($table-map, $key)
    let $fix_rowmap :=
      for $key in ($patient-lib:GENDERS, $patient-lib:RACES, $patient-lib:AGES)
      return if (map:contains($rowmap, $key)) then () else map:put($rowmap, $key, 0)
    let $orders := ($key, $patient-lib:GENDERS ! (map:get($rowmap, .)), $patient-lib:RACES ! (map:get($rowmap, .)), $patient-lib:AGES ! (map:get($rowmap, .)))
    order by if ($sortdir eq "asc") then $orders[$sortcol] else () ascending, if ($sortdir eq "asc") then () else $orders[$sortcol] descending
    return if (fn:matches($key, $search, ("i"))) then $rowmap else ()
  return (
    ch:set-value("table", $table[$start to $end]),
    ch:set-value("total", map:count($table-map)),
    ch:set-value("total-display", fn:count($table)),
    ch:set-value("echo", $echo),
    ch:use-view("appbuilder/results-table"),
    ch:use-layout(())
  )
};

declare function c:results-facility-table() as item()*
{
  let $input-query := $QUERY
  let $start := req:get("iDisplayStart", 0, "type=xs:integer") + 1
  let $end := $start + req:get("iDisplayLength", 10, "type=xs:integer") - 1
  let $sortcol := req:get("iSortCol_0", 0, "type=xs:integer") + 1
  let $sortdir := req:get("sSortDir_0", "asc", "type=xs:string")
  let $echo := req:get("sEcho", 1, "type=xs:integer")
  let $search := req:get("sSearch", "", "type=xs:string")

  let $table-map := patient-lib:build-result-table(cts:path-reference("/va:vpr/va:results/va:visits/va:visit/va:facility/va:facility-name"), $input-query)
  let $table :=
    for $key in map:keys($table-map)
    let $rowmap := map:get($table-map, $key)
    let $fix_rowmap :=
      for $key in ($patient-lib:GENDERS, $patient-lib:RACES, $patient-lib:AGES)
      return if (map:contains($rowmap, $key)) then () else map:put($rowmap, $key, 0)
    let $orders := ($key, $patient-lib:GENDERS ! (map:get($rowmap, .)), $patient-lib:RACES ! (map:get($rowmap, .)), $patient-lib:AGES ! (map:get($rowmap, .)))
    order by if ($sortdir eq "asc") then $orders[$sortcol] else () ascending, if ($sortdir eq "asc") then () else $orders[$sortcol] descending
    return if (fn:matches($key, $search, ("i"))) then $rowmap else ()
  return (
    ch:set-value("table", $table[$start to $end]),
    ch:set-value("total", map:count($table-map)),
    ch:set-value("total-display", fn:count($table)),
    ch:set-value("echo", $echo),
    ch:use-view("appbuilder/results-table"),
    ch:use-layout(())
  )
};

declare function c:results-procedure-table() as item()*
{
  let $input-query := $QUERY
  let $start := req:get("iDisplayStart", 0, "type=xs:integer") + 1
  let $end := $start + req:get("iDisplayLength", 10, "type=xs:integer") - 1
  let $sortcol := req:get("iSortCol_0", 0, "type=xs:integer") + 1
  let $sortdir := req:get("sSortDir_0", "asc", "type=xs:string")
  let $echo := req:get("sEcho", 1, "type=xs:integer")
  let $search := req:get("sSearch", "", "type=xs:string")

  let $table-map := patient-lib:build-result-table(cts:path-reference("/va:vpr/va:results/va:procedures/va:procedure/va:type/va:type-name"), $input-query)
  let $table :=
    for $key in map:keys($table-map)
    let $rowmap := map:get($table-map, $key)
    let $fix_rowmap :=
      for $key in ($patient-lib:GENDERS, $patient-lib:RACES, $patient-lib:AGES)
      return if (map:contains($rowmap, $key)) then () else map:put($rowmap, $key, 0)
    let $orders := ($key, $patient-lib:GENDERS ! (map:get($rowmap, .)), $patient-lib:RACES ! (map:get($rowmap, .)), $patient-lib:AGES ! (map:get($rowmap, .)))
    order by if ($sortdir eq "asc") then $orders[$sortcol] else () ascending, if ($sortdir eq "asc") then () else $orders[$sortcol] descending
    return if (fn:matches($key, $search, ("i"))) then $rowmap else ()
  return (
    ch:set-value("table", $table[$start to $end]),
    ch:set-value("total", map:count($table-map)),
    ch:set-value("total-display", fn:count($table)),
    ch:set-value("echo", $echo),
    ch:use-view("appbuilder/results-table"),
    ch:use-layout(())
  )
};

declare function c:icd-code-lookup() as item()*
{
  let $codes := req:get('icd9code', (), "type=xs:string")
  let $codemap := map:map()
  let $_buildmap :=
    for $code in $codes
    let $description := cts:element-attribute-values(xs:QName("on:concept"), xs:QName("description"), (), (), cts:element-attribute-range-query(xs:QName("on:concept"), xs:QName("code"), "=", $code))[1]
    return map:put($codemap, $code, $description)
  return (
    ch:use-view(()),
    xdmp:to-json($codemap)
  )
};

declare function c:execute-saved() as item()*
{
  ch:set-value('matches', $MATCHES),
  ch:set-value("mature", $MATURE),
  ch:set-value("q", $Q),
  ch:set-value("query", $QUERY),
  ch:set-value("matches-href", $MATCHES-HREF),

  let $id := req:get("id", "", "type=xs:string")
  let $q := saved-search:get-results-as-query($_user, $id)
  let $parsed := search:parse(element huh{$q})

  return(
      ch:set-value(
        "response",
        search:resolve($parsed, $OPTIONS, $PAGE-START, $cfg:DEFAULT-PAGE-LENGTH)),
      ch:set-value("search-options", $OPTIONS),
      ch:set-value('subtabs', $SUBTABS),
      ch:set-value('subtab-active', $SUBTAB-ACTIVE),
      if (false()) then ch:set-value('tab-active', 1) else (),
      ch:set-value('title', 'VistA Analytics'),
      (: Requires earlier values. :)
      ch:set-value("pseudo-facets", c:pseudo-facets(ch:get('response'))),
      ch:use-view("appbuilder/main"),
      ch:add-value('additional-js', <script src="/js/date-facet.js">&nbsp;</script>),
      ch:use-layout("two-column", "html")
   )
};

(: controllers/appbuilder.xqy :)
