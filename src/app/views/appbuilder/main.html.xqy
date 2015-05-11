xquery version "1.0-ml";

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace facet = "http://marklogic.com/roxy/facet-lib" at "/app/views/helpers/facet-lib.xqy";
import module namespace patient-lib = "ns://va.gov/2012/ip401/patient" at "/app/models/patient-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $MATCHES-HREF as xs:string := vh:get("matches-href");
declare variable $MATURE as xs:boolean := vh:get("mature");
declare variable $PSEUDO-FACETS as element()? := vh:get("pseudo-facets");
declare variable $Q as xs:string? := vh:get("q");
declare variable $QUERY as element()? := vh:get("query");
declare variable $RESPONSE as element(search:response)? := vh:get("response");
declare variable $SUBTAB as xs:integer := vh:get("subtab-active");

vh:add-value(
  "sidebar",
  <div id="sidebar" class="sidebar" arcsize="5 5 0 0">
  {
    facet:facets(
      $RESPONSE/search:facet, $PSEUDO-FACETS, $Q, $QUERY,
      $MATCHES-HREF, vh:get('search-options'), $c:LABELS)
  }
  </div>),

(: Main view body, with subtab handling. :)
if (vh:get('subtab-active') eq 1) then (
  vh:add-value('additional-js',
    (<script src="/js/lib/highcharts.js">&nbsp;</script>,
    <script src="/js/summary.js">&nbsp;</script>,
     <script src="/js/analyze.js">&nbsp;</script>
     )),
<link rel="stylesheet" href="/css/analyze.css"/>,
<div id="analyze_container">
  <div id="query_stats">
  Your query matches
  {
    $RESPONSE/@total/string()
  }
  total patients.
  </div>

  <table id="summaryTables" style="width: 100%" >
    <tr>
      <td class="top-left-corner">
          <div id="table_1" class="quad_div" data-facet="diag-code">
            <div class="margin_container">
              <h3>Diagnoses</h3>
              <div class="container">
                <table class="quad_table">
                  <thead>
                    <tr>
                        <th>Diagnosis</th>
                        <th><img src="/images/male.png" style="float:left;"/></th>
                        <th><img src="/images/female.png" style="float:left;"/></th>
                        <th><img src="/images/nativeAmerican.png" style="float:left;"/></th>
                        <th><img src="/images/asian.png" style="float:left;"/></th>
                        <th><img src="/images/black.png" style="float:left;"/></th>
                        <th><img src="/images/pacificIslander.png" style="float:left;"/></th>
                        <th><img src="/images/white.png" style="float:left;"/></th>
                        <th><img src="/images/other.png" style="float:left;"/></th>
                        <th><img src="/images/latino.png" style="float:left;"/></th>
                        <th><img src="/images/20to30.png" style="float:left;"/></th>
                        <th><img src="/images/31to40.png" style="float:left;"/></th>
                        <th><img src="/images/41to50.png" style="float:left;"/></th>
                        <th><img src="/images/51to70.png" style="float:left;"/></th>
                        <th><img src="/images/71to90.png" style="float:left;"/></th>
                     </tr>
                  </thead>
                  <tbody><tr><td colspan="15">Loading Data</td></tr></tbody>
                </table>
              </div>
            </div>
          </div>
      </td>
      <td class="top-left-corner">
          <div id="table_2" class="quad_div" data-facet="med-name">
            <div class="margin_container">
              <h3>Prescriptions</h3>
              <div class="container">
                <table class="quad_table">
                  <thead>
                    <tr>
                        <th>Medicine</th>
                        <th><img src="/images/male.png" style="float:left;"/></th>
                        <th><img src="/images/female.png" style="float:left;"/></th>
                        <th><img src="/images/nativeAmerican.png" style="float:left;"/></th>
                        <th><img src="/images/asian.png" style="float:left;"/></th>
                        <th><img src="/images/black.png" style="float:left;"/></th>
                        <th><img src="/images/pacificIslander.png" style="float:left;"/></th>
                        <th><img src="/images/white.png" style="float:left;"/></th>
                        <th><img src="/images/other.png" style="float:left;"/></th>
                        <th><img src="/images/latino.png" style="float:left;"/></th>
                        <th><img src="/images/20to30.png" style="float:left;"/></th>
                        <th><img src="/images/31to40.png" style="float:left;"/></th>
                        <th><img src="/images/41to50.png" style="float:left;"/></th>
                        <th><img src="/images/51to70.png" style="float:left;"/></th>
                        <th><img src="/images/71to90.png" style="float:left;"/></th>
                     </tr>
                  </thead>
                  <tbody><tr><td colspan="15">Loading Data</td></tr></tbody>
                </table>
              </div>
            </div>
          </div>
      </td>
    </tr>
    <tr>
      <td class="top-left-corner">
          <div id="table_3" class="quad_div" data-facet="facility" >
            <div class="margin_container">
              <h3>Facilities (Visits)</h3>
              <div class="container">
                <table class="quad_table">
                  <thead>
                    <tr>
                        <th>Facility</th>
                        <th><img src="/images/male.png" style="float:left;"/></th>
                        <th><img src="/images/female.png" style="float:left;"/></th>
                        <th><img src="/images/nativeAmerican.png" style="float:left;"/></th>
                        <th><img src="/images/asian.png" style="float:left;"/></th>
                        <th><img src="/images/black.png" style="float:left;"/></th>
                        <th><img src="/images/pacificIslander.png" style="float:left;"/></th>
                        <th><img src="/images/white.png" style="float:left;"/></th>
                        <th><img src="/images/other.png" style="float:left;"/></th>
                        <th><img src="/images/latino.png" style="float:left;"/></th>
                        <th><img src="/images/20to30.png" style="float:left;"/></th>
                        <th><img src="/images/31to40.png" style="float:left;"/></th>
                        <th><img src="/images/41to50.png" style="float:left;"/></th>
                        <th><img src="/images/51to70.png" style="float:left;"/></th>
                        <th><img src="/images/71to90.png" style="float:left;"/></th>
                    </tr>
                  </thead>
                  <tbody><tr><td colspan="15">Loading Data</td></tr></tbody>
                </table>
              </div>
            </div>
          </div>
      </td>
      <td class="top-left-corner">
          <div id="table_4" class="quad_div" data-facet="procedure">
            <div class="margin_container">
              <h3>Procedures</h3>
              <div class="container">
                <table class="quad_table">
                  <thead>
                    <tr>
                        <th>Procedure</th>
                        <th><img src="/images/male.png" style="float:left;"/></th>
                        <th><img src="/images/female.png" style="float:left;"/></th>
                        <th><img src="/images/nativeAmerican.png" style="float:left;"/></th>
                        <th><img src="/images/asian.png" style="float:left;"/></th>
                        <th><img src="/images/black.png" style="float:left;"/></th>
                        <th><img src="/images/pacificIslander.png" style="float:left;"/></th>
                        <th><img src="/images/white.png" style="float:left;"/></th>
                        <th><img src="/images/other.png" style="float:left;"/></th>
                        <th><img src="/images/latino.png" style="float:left;"/></th>
                        <th><img src="/images/20to30.png" style="float:left;"/></th>
                        <th><img src="/images/31to40.png" style="float:left;"/></th>
                        <th><img src="/images/41to50.png" style="float:left;"/></th>
                        <th><img src="/images/51to70.png" style="float:left;"/></th>
                        <th><img src="/images/71to90.png" style="float:left;"/></th>
                    </tr>
                  </thead>
                  <tbody><tr><td colspan="15">Loading Data</td></tr></tbody>
                </table>
              </div>
            </div>
          </div>
      </td>
    </tr>
  </table>
</div>,
<div id="outer_div">
  <button id="reset_zoom_button">Reset Zoom</button>
  <div id="timeline_div">
  </div>
</div>,
<div id="timeline_view_div">
</div>)

(: Results subtab is not here, so this should never happen.
 : cf detail.html.xqy
 :)
else if (vh:get('subtab-active') eq 2) then error(
  (), 'BADTAB', vh:get('subtab-active'))

(: Map subtab.
 : If the map is at min-height, something in its ancestry has indeterminate height.
 : For full height everything in its ancestry must have height 100% too.
 :)
else if (vh:get('subtab-active') eq 3) then (
  <script src="https://maps.googleapis.com/maps/api/js?libraries=visualization,drawing&amp;sensor=false">&nbsp;</script>,
  <script src="/js/map.js">&nbsp;</script>,
  <script src="/js/analyze.js">&nbsp;</script>,
  <div id="heatmap" style="display:block; width:100%; height:95%;">
    <div id="mapCanvas" style="display:block; width:100%; height:95%; min-height:128px;">
  Loading...
    </div>
  </div>)

else error(
    (), 'SUBTAB',
    text { 'No selected subtab or subtab not found:', vh:get('subtab-active') })

(: views/appbuilder/main.html.xqy :)