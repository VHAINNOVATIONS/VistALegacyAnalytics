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

declare default element namespace "http://www.w3.org/1999/xhtml" ;

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace facet = "http://marklogic.com/roxy/facet-lib" at "/app/views/helpers/facet-lib.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $PAGINATION-FIRST := "&laquo;" ;
declare variable $PAGINATION-PREV := "&lt;" ;
declare variable $PAGINATION-NEXT := "&gt;" ;
declare variable $PAGINATION-LAST := "&raquo;" ;

declare option xdmp:mapping "false";

declare variable $MATCHES as xs:string := vh:get("matches");
declare variable $MATURE as xs:boolean := vh:get("mature");
declare variable $PSEUDO-FACETS as element()? := vh:get("pseudo-facets");
declare variable $Q as xs:string? := vh:get("q");
declare variable $QUERY as element()? := vh:get("query");
declare variable $RESPONSE as element(search:response)? := vh:get("response");

declare variable $STATS := map:map(
  <map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <map:entry key="reactions">
      <map:value xsi:type="xs:string">Reactions</map:value>
    </map:entry>
    <map:entry key="problems">
      <map:value xsi:type="xs:string">Problems</map:value>
    </map:entry>
    <map:entry key="vitals">
      <map:value xsi:type="xs:string">Vitals</map:value>
    </map:entry>
    <map:entry key="labs">
      <map:value xsi:type="xs:string">Labs</map:value>
    </map:entry>
    <map:entry key="meds">
      <map:value xsi:type="xs:string">Medicines</map:value>
    </map:entry>
    <map:entry key="immunizations">
      <map:value xsi:type="xs:string">Immunizations</map:value>
    </map:entry>
    <map:entry key="observations">
      <map:value xsi:type="xs:string">Observations</map:value>
    </map:entry>
    <map:entry key="visits">
      <map:value xsi:type="xs:string">Visits</map:value>
    </map:entry>
    <map:entry key="appointments">
      <map:value xsi:type="xs:string">Appointments</map:value>
    </map:entry>
    <map:entry key="documents">
      <map:value xsi:type="xs:string">Documents</map:value>
    </map:entry>
    <map:entry key="procedures">
      <map:value xsi:type="xs:string">Procedures</map:value>
    </map:entry>
    <map:entry key="consults">
      <map:value xsi:type="xs:string">Consults</map:value>
    </map:entry>
    <map:entry key="flags">
      <map:value xsi:type="xs:string">Flags</map:value>
    </map:entry>
  </map:map>
);

(: highlighting :)
declare function local:transform-snippet($nodes as node()*)
{
  for $n in $nodes
  return
    typeswitch($n)
      case element(search:highlight) return
        <span class="highlight">{fn:data($n)}</span>
      case element() return
        element div
        {
          attribute class { fn:local-name($n) },
          local:transform-snippet(($n/@*, $n/node()))
        }
      default return $n
};

declare function local:va-date($input as xs:string)
as xs:date?
{
  let $start := fn:string-length($input) - 3
  let $month := fn:substring($input, $start, 2)
  let $day := fn:substring($input, $start + 2, 2)
  let $year := fn:string(fn:number(fn:substring($input, 0, $start)) + 1700)
  return ($year||'-'||$month||'-'||$day)[. castable as xs:date] ! xs:date(.)
};

declare function local:get-psych-class-severity($indicators)
{

   let $highest-severity :=
                    if (not($indicators)) then ()
                    else if (count($indicators) = 1) then
                      if (functx:is-value-in-sequence( $indicators, ("EXTREME", "SEVERE", "CATASTROPHIC")))  then string($indicators)
                      else ()
                    else if (functx:is-value-in-sequence( "CATASTROPHIC", $indicators)) then "CATASTROPHIC"
                    else if (functx:is-value-in-sequence( "EXTREME", $indicators)) then "EXTREME"
                    else if (functx:is-value-in-sequence( "SEVERE", $indicators)) then "SEVERE"
                    else ()

   return $highest-severity

};

declare function local:format-results($result as node()) {
  let $doc := doc($result/@uri)
  let $id := fn:string($doc/va:vpr/va:meta/va:id)
  let $site := fn:string($doc/va:vpr/va:meta/va:site)
  let $results := $doc/va:vpr/va:results
  let $patient := $results/va:demographics/va:patient
  let $dob := local:va-date(fn:string($patient/va:dob))
  let $age := xs:integer(fn:days-from-duration(fn:current-date() - $dob) div 365)
  let $veteran := $patient/va:veteran/xs:boolean(.)
  let $sex := fn:string($patient/va:gender)
  let $psychiatryClassSeverity := local:get-psych-class-severity($results/va:patientTreatments/va:patientTreatment/va:psychiatryClassSeverity)

  return
  (
    <div class="title">
      <a href="/records/?id={$id}&#38;site={$site}">
        {
          fn:string($patient/va:fullName)
        }
        {
          let $saved-searches := xdmp:directory("/users/" || xdmp:get-current-user() || "/saved/", "infinity")/*:savedSearch
          let $matches :=
            for $search in $saved-searches
            let $s := $search/*:search/fn:string()
            let $parsed := search:parse($s, $c:SEARCH-OPTIONS, "cts:query")
            return if (cts:contains($doc, cts:query($parsed))) then
              $search/*:search/fn:string()
            else ()
          return if ($matches) then
            <img src="/images/saved_search.png" title="Matches your saved queries: {fn:string-join($matches, ', ')}"/>
          else ()
        }
      </a>
    </div>,
    if (fn:exists($result/search:snippet//search:highlight)) then
    <div class="snippet">
      {
        local:transform-snippet($result/search:snippet)
      }
    </div>
    else (),
    <div class="stats">
        <span>
            {
                fn:concat(
                  if ($veteran) then "Veteran" else "Non-veteran",
                  ", ",
                  fn:string($age),
                  ", ",
                  if ($sex = "M") then "Male" else "Female"
                  )
            }
             {   element a {
                    attribute class {"hsLink"}, attribute title {"View patient health summary"},
                    attribute href{ "/patient/summary?id=" || $id || "&amp;site=" || $site  }, "Health summary"  } }

            {  if ( $psychiatryClassSeverity )
                    then element div {
                        attribute title {"Psych class severity: " || $psychiatryClassSeverity},
                        attribute class {"psychiatryClassSeverityIndicator"},"&#9888;" }

                    else ()
            }
        </span>
      <table class="stats">
        {
          let $cells :=
            for $key in map:keys($STATS)
            let $total := xdmp:unpath(fn:concat(xdmp:path($results, fn:true()), "/va:", $key, "/@total"))
            let $total := if ($total) then string($total) else "0"
            return
                if ($total ne "0") then <td><div>{fn:concat(map:get($STATS, $key), ":", fn:string($total)) }</div></td>
                else ()

            let $joined := string-join($cells, "  ")
            return
                <tr><div>{$joined}</div></tr>
        }
      </table>
    </div>
  )
};

declare function local:link(
  $label as xs:string,
  $key as xs:string?,
  $page as xs:integer)
as element(a)
{
  element a {
    attribute accesskey { $key },
    attribute href {
      concat(
        (: '/?', :)
        '/appbuilder/detail.html?',
        string-join(
          ('q=' || $Q,
            'matches='||xs:string($MATCHES),
            'mature='||xs:string($MATURE),
            'page='||$page,
            'subtab=2'),
          '&amp;')) },
    $label }
};


(: start rendering page :)

(: facets side-bar :)
vh:add-value(
  "sidebar",
  <div id="sidebar" class="sidebar" arcsize="5 5 0 0">
  {
    facet:facets(
      $RESPONSE/search:facet, $PSEUDO-FACETS,
      $Q, $QUERY,
      ('matches='||xs:string($MATCHES),
        'mature='||xs:string($MATURE),
        'subtab=2'),
      vh:get('search-options'), $c:LABELS)
  }
  </div>),

vh:add-value(
  'sidebar',
  element div {
    attribute id { "constraints" },
    attribute class { 'sidebar' },
    if (true()) then ()
    else element div {
      attribute class { 'sidebar-header' },
      element label { 'Include data from immature sites' },
      element input {
        attribute type { "checkbox" },
        attribute id { "mature" },
        attribute name { "mature" },
        attribute value { 0 },
        attribute onchange { 'this.form.submit()' },
        if (vh:get('mature')) then ()
        else attribute checked { 'checked' } } } } ),

<script src="/js/analyze.js">&nbsp;</script>,
<link rel="stylesheet" href="/css/analyze.css"/>,


let $page := ($RESPONSE/@start - 1) div $c:DEFAULT-PAGE-LENGTH + 1
let $total-pages := fn:ceiling($RESPONSE/@total div $c:DEFAULT-PAGE-LENGTH)
return
  <div id="search">
  {
    if ($RESPONSE/@total lt 1) then
      <div class="results">
        <h2>No Results Found</h2>
      </div>
    else (
      <div class="pagination">
        <span class="status">Showing {fn:string($RESPONSE/@start)} to {fn:string(fn:min(($RESPONSE/@start + $RESPONSE/@page-length - 1, $RESPONSE/@total)))} of <span id="total-results">{fn:string($RESPONSE/@total)}</span> Results </span>
        <span class="nav">
          <span id="first" class="button">
          {
            if ($page lt 2) then $PAGINATION-FIRST
            else local:link($PAGINATION-FIRST, 'f', 1)
          }
          </span>
          <span id="previous" class="button">
          {
            if ($page lt 2) then $PAGINATION-PREV
            else local:link($PAGINATION-PREV, 'p', $page - 1)
          }
          </span>
          <span id="next" class="button">
          {
            if ($page ge $total-pages) then $PAGINATION-NEXT
            else local:link($PAGINATION-NEXT, 'n', $page + 1)
          }
          </span>
          <span id="last" class="button">
          {
            if ($page ge $total-pages) then $PAGINATION-LAST
            else local:link($PAGINATION-LAST, 'l', $total-pages)
          }
          </span>
        </span>
      </div>,
      <div class="results">
      {
        for $result at $i in $RESPONSE/search:result
        let $doc := fn:doc($result/@uri)/*
        return
          <div class="result">
          {
            (
              local:format-results($result), ()
            )
          }
          </div>
      }
      </div>
    )
  }

  </div>
