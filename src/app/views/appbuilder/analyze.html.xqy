xquery version "1.0-ml";

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace facet = "http://marklogic.com/roxy/facet-lib" at "/app/views/helpers/facet-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $MATURE as xs:boolean := vh:get("mature");
declare variable $QUERY as xs:string? := vh:get("q");
declare variable $RESPONSE as element(search:response)? := vh:get("response");

vh:add-value(
  "sidebar",
  <div class="sidebar" arcsize="5 5 0 0">
  {
    facet:facets(
      $RESPONSE/search:facet, $QUERY, 'mature='||xs:string($MATURE),
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

<script src="/js/lib/highcharts.js">&nbsp;</script>,
<script src="/js/analyze.js">&nbsp;</script>,
<link rel="stylesheet" href="/css/analyze.css"/>,
<div id="analyze_container">
	<div id="table_1" class="quad_div">
		<div class="margin_container">
			<h3>Patients By Birthdate</h3>
			<div class="container">

			</div>
		</div>
	</div>
	<div id="table_2" class="quad_div">
		<div class="margin_container">
			<h3>Patients By Diagnosis</h3>
			<div class="container">

			</div>
		</div>
	</div>
	<div id="table_3" class="quad_div">
		<div class="margin_container">
			<h3>Patients By Prescription</h3>
			<div class="container">

			</div>
		</div>
	</div>
	<div id="table_4" class="quad_div">
		<div class="margin_container">
			<h3>Patients By Facility</h3>
			<div class="container">

			</div>
		</div>
	</div>
</div>,
<div id="timeline_div">

</div>