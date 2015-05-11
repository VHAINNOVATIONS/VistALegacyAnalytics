xquery version "1.0-ml";

(:
 : Copyright 2012 MarkLogic Corporation
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :    http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
:)

declare default element namespace "http://www.w3.org/1999/xhtml" ;
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

let $sources := vh:get("sources")
let $options :=
	for $index-name in map:keys($sources)
	let $value-path := map:get($sources, $index-name)
	let $type-path := $value-path || "/@type"
	let $types := cts:values(cts:path-reference($type-path))
	for $type in $types
	return <option value="{$value-path || '[@type=&quot;' || $type || '&quot;]' || '/@name'}">{$index-name || ": " || $type}</option>
return
(
	<script type="text/javascript" src="/js/analytics.js">&nbsp;</script>,
	<script type="text/javascript" src="/js/lib/highcharts.js">&nbsp;</script>,
	<div id="analytics_view">
		<div id="above_table">
			<select id="xvals"><option value="null">--Select a Concept--</option>{$options}</select> x <select id="yvals"><option value="null">--Select a Concept--</option>{$options}</select>
		</div>

        <div id="table_message">Select 2 concepts to show co-occurrence frequencies for patient records.</div>

        <div id="table">
            <div class="row">
                 <span class="cell" >
                    <div style="width: 700px;" >
                        <div id="theSummaryChart">&nbsp;</div>
                    </div>
                </span>
            </div>
            <div class="row">
                 <span class="cell" >
                    <div id="analyze_co_occurence" >
                        <table id="analysis_co_occurence" >&nbsp;</table>
                    </div>
                </span>
            </div>
            <div class="row">
                <span class="cell">
                    <div style="width: 500px;" >
                        <div id="timechart">&nbsp;</div>
                    </div>
                </span>
            </div>
        </div>
	</div>
)

(: analytics/main.html.xqy :)