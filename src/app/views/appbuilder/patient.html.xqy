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

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace m = "ns://va.gov/2012/ip401/patient" at "/app/models/patient-lib.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";

declare namespace va = "ns://va.gov/2012/ip401";
declare namespace none = "";

declare variable $patient := vh:get("patient");
declare variable $doc-uri := vh:get("doc-uri");
declare variable $site := vh:get("site");

<script type="text/javascript" src="/js/lib/highcharts.js">&nbsp;</script>,
<script type="text/javascript" src="/js/patient.js">&nbsp;</script>,
<link rel="stylesheet" type="text/css" href="/css/patient.css"/>,
<div id="patient_container">
	<div id="patient_infobar">
		<table id="demos_table">
			<tbody>
				<tr>
				{
				    let $demos := $patient/va:results/va:demographics/va:patient
                    let $bid := <td><span>BID:</span> {$demos/va:bid}</td>
                    let $fn := <td><span>Name:</span> {replace($demos/va:fullName, ",", ", ")}</td>
                    let $dob := <td><span>DOB:</span> {util:convert-vpr-date($demos/va:dob)}</td>
                    let $gender := <td><span>Sex:</span> {$demos/va:gender}</td>
                    let $ssn := <td><span>SSN:</span> {$demos/va:ssn}</td>
                    return ($bid, $fn, $dob, $gender, $ssn)
				}
				</tr>
			</tbody>
		</table>
	</div>
	<div id="patient_tabdiv">
	{
		let $tabs :=
			<div id="data_selector">
				<ul>
				{
					for $view at $x in ("Allergies/Reactions", "Appointments", "Consults", "Documents", "Education Topics", "Exams", "Health Factors", "Flags", "Immunizations", "Insurance Policies", "Labs", "Medicines", "Observations", "Problems", "Procedures", "Skin Tests", "Visits", "Vitals", "Timeline")
					let $id := fn:replace($view, "[ /]", "_")
					return
						if ($x = 1) then <li class="active"><a href="#{$id}_tab">{$view}</a></li> else <li><a href="#{$id}_tab">{$view}</a></li>
				}
				</ul>
			</div>
		return (
			<div id="content_wrapper">
				<div id="content_panel">
				{
					for $tab in $tabs//*:li
					let $id := fn:replace($tab/*:a/@href, '#', '')
					let $name := fn:string($tab/*:a)
					let $fields := $m:PATIENT-EXTRACTS/*:fields[@name=$name]
					let $item-path := fn:concat(xdmp:path($patient, fn:true()), $fields/@path)
					let $root-path := fn:string-join(fn:tokenize($item-path, "/")[1 to (fn:last() - 1)], "/")
					return
						<div id="{$id}" class="horz_tab" data-name="{$name}">
							<ul data-id="{$id}">
								<li><a href="#{$id}_table_view">Table</a></li>
								<li><a href="#{$id}_raw_view">Full</a></li>
							</ul>
							<button class="export_button" data-docuri="fn:doc(&quot;{$doc-uri}&quot;)/." data-path="{$root-path}">Export to XML</button>
							<div id="{$id}_table_view">
							{
								util:create-data-table($fields)
							}
							</div>
							<div id="{$id}_raw_view">{util:render-xml(xdmp:unpath($item-path)[1 to 10])}</div>
                        </div>
				}
				</div>
			</div>,
			$tabs
		)

	}	
	</div>
	<div id="export_dialog" title="Export to XML">
		<p><span class="ui-icon ui-icon-help" style="float: left; margin: 0 7px 20px 0;"></span>Would you like to export the entire patient record or just this subset?</p>
	</div>
	<div id="content_dialog" title="Document Content">&nbsp;</div>
	<script>
	    patient_id = {fn:string($patient/va:meta/va:id)};
	    var site =  {xdmp:to-json( fn:string($site) )};
	</script>
</div>