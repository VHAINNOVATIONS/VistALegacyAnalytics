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

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $patient := vh:get("patient");
declare variable $doc-uri := vh:get("doc-uri");
declare variable $category := vh:get("cat");

declare function local:build-category-content($name as xs:string, $root as node(), $items as node()*, $fields) {
	let $id := fn:replace($name, "[ /]", "_")
	return
	(
		<ul data-id="{$id}">
			<li><a href="#{$id}_table_view">Table</a></li>
			<li><a href="#{$id}_raw_view">Full</a></li>
			<button class="export_button" data-docuri="fn:doc(&quot;{$doc-uri}&quot;)/." data-path="{xdmp:path($root, fn:true())}">Export to XML</button>
		</ul>,
		<div id="{$id}_table_view">
		{
			util:create-data-table($name, $items, $fields)
		}
		</div>,
		<div id="{$id}_raw_view">{util:render-xml($items)}</div>
	)
};

if ($category = "1") then
	local:build-category-content("Allergies/Reactions", $patient/va:results/va:reactions, $patient/va:results/va:reactions/va:allergy,
		<fields xmlns="">
			<field><name>Type</name><path>/va:type/@name</path><type>string</type></field>
			<field><name>Class</name><path>/va:drugClasses/va:drugClass/@name</path><type>string</type></field>
			<field><name>Reactions</name><path>/va:reactions/va:reaction/@name</path><type>string</type></field>
			<field><name>Ingredients</name><path>/va:drugIngredients/va:drugIngredient/@name</path><type>string</type></field>
			<field><name>Entered</name><path>/va:entered</path><type>date</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
		</fields>
	)
else if ($category = "2") then
	local:build-category-content("Appointments", $patient/va:results/va:appointments, $patient/va:results/va:appointments/va:appointment,
		<fields xmlns="">
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Status</name><path>/va:apptStatus</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
			<field><name>Provider</name><path>/va:provider/@name</path><type>string</type></field>
			<field><name>Category</name><path>/va:serviceCategory/@name</path><type>string</type></field>
		</fields>
	)
else if ($category = "3") then
	local:build-category-content("Consults", $patient/va:results/va:consults, $patient/va:results/va:consults/va:consult,
		<fields xmlns="">
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Procedure</name><path>/va:procedure</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Status</name><path>/va:apptStatus</path><type>string</type></field>
			<field><name>Requested</name><path>/va:requested</path><type>date</type></field>
		</fields>
	)
else if ($category = "4") then
	local:build-category-content("Documents", $patient/va:results/va:documents, $patient/va:results/va:documents/va:document,
		<fields xmlns="">
			<field><name>Title</name><path>/va:localTitle</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:referenceDateTime</path><type>date</type></field>
			<field><name>Clinicians</name><path>/va:clinicians/va:clinician/va:clinician-name</path><type>string</type></field>
			<field><name>Content</name><path>/va:content</path><type>text</type></field>
		</fields>
	)
else if ($category = "5") then
	local:build-category-content("Education Topics", $patient/va:results/va:educationTopics, $patient/va:results/va:educationTopics/va:educationTopic,
		<fields xmlns="">
			<field><name>Name</name><path>/va:educationTopic-name</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
	)
else if ($category = "6") then
	local:build-category-content("Exams", $patient/va:results/va:exams, $patient/va:results/va:exams/va:exam,
		<fields xmlns="">
			<field><name>Name</name><path>/va:exam-name</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
	)
else if ($category = "7") then
	local:build-category-content("Health Factors", $patient/va:results/va:healthFactors, $patient/va:results/va:healthFactors/va:factor,
		<fields xmlns="">
			<field><name>Name</name><path>/va:factor-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Recorded</name><path>/va:recorded</path><type>date</type></field>
			<field><name>Comment</name><path>/va:comment</path><type>string</type></field>
		</fields>
	)
else if ($category = "8") then
	local:build-category-content("Flags", $patient/va:results/va:flags, $patient/va:results/va:flags/va:flag,
		<fields xmlns="">
			<field><name>Name</name><path>/va:flag-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
	)
else if ($category = "9") then
	local:build-category-content("Immunizations", $patient/va:results/va:immunizations, $patient/va:results/va:immunizations/va:immunization,
		<fields xmlns="">
			<field><name>Name</name><path>/va:immunization-name</path><type>string</type></field>
			<field><name>Contraindicated</name><path>/va:contraindicated</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Administered</name><path>/va:administered</path><type>date</type></field>
		</fields>
	)
else if ($category = "10") then
	local:build-category-content("Insurance Policies", $patient/va:results/va:insurancePolicies, $patient/va:results/va:insurancePolicies/va:insurancePolicy,
		<fields xmlns="">
			<field><name>Company</name><path>/va:company/va:company-name</path><type>string</type></field>
			<field><name>Type</name><path>/va:insuraceType/va:insuranceType-name</path><type>string</type></field>
			<field><name>Subscriber</name><path>/va:subscriber/va:subscriber-name</path><type>string</type></field>
			<field><name>Relationship</name><path>/va:relationship</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Effective Date</name><path>/va:effectiveDate</path><type>date</type></field>
		</fields>
	)
else if ($category = "11") then
	local:build-category-content("Labs", $patient/va:results/va:labs, $patient/va:results/va:labs/va:lab,
		<fields xmlns="">
			<field><name>Name</name><path>/va:localName</path><type>string</type></field>
			<field><name>Status</name><path>/va:status</path><type>string</type></field>
			<field><name>Date</name><path>/va:collected</path><type>date</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Comment</name><path>/va:comment</path><type>text</type></field>
		</fields>
	)
else if ($category = "12") then
	local:build-category-content("Medicines", $patient/va:results/va:meds, $patient/va:results/va:meds/va:med,
		<fields xmlns="">
			<field><name>Name</name><path>/va:med-name</path><type>string</type></field>
			<field><name>Provider</name><path>/va:currentProvider/@name</path><type>string</type></field>
			<field><name>Days Supply</name><path>/va:daysSupply</path><type>string</type></field>
			<field><name>Directions</name><path>/va:sig</path><type>string</type></field>
			<field><name>Start</name><path>/va:start</path><type>date</type></field>
			<field><name>Last Filled</name><path>/va:lastFilled</path><type>date</type></field>
		</fields>
	)
else if ($category = "13") then
	local:build-category-content("Observations", $patient/va:results/va:observations, $patient/va:results/va:observations/va:observations,
		<fields xmlns="">
			<field><name>Name</name><path>/va:observation-name</path><type>string</type></field>
			<!--Placeholder for observations. No test data currently available. -->
		</fields>
	)
else if ($category = "14") then
	local:build-category-content("Problems", $patient/va:results/va:problems, $patient/va:results/va:problems/va:problem,
		<fields xmlns="">
			<field><name>Name</name><path>/va:problem-name</path><type>string</type></field>
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Onset</name><path>/va:onset</path><type>date</type></field>
			<field><name>Provider</name><path>/va:provider/va:provider-name</path><type>string</type></field>
		</fields>
	)
else if ($category = "15") then
	local:build-category-content("Procedures", $patient/va:results/va:procedures, $patient/va:results/va:procedures/va:procedure,
		<fields xmlns="">
			<field><name>Name</name><path>/va:procedure-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
			<field><name>Location</name><path>/va:location/va:location-name</path><type>string</type></field>
			<field><name>Provider</name><path>/va:provider/va:provider-name</path><type>string</type></field>
		</fields>
	)
else if ($category = "16") then
	local:build-category-content("Skin Tests", $patient/va:results/va:skinTests, $patient/va:results/va:skinTests/va:skinTest,
		<fields xmlns="">
			<field><name>Name</name><path>/va:skinTest-name</path><type>string</type></field>
			<field><name>Result</name><path>/va:result</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
	)
else if ($category = "17") then
	local:build-category-content("Visits", $patient/va:results/va:visits, $patient/va:results/va:visits/va:visit,
		<fields xmlns="">
			<field><name>Type</name><path>/va:type/va:type-name</path><type>string</type></field>
			<field><name>Reason</name><path>/va:reason/va:narrative</path><type>string</type></field>
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Arrival</name><path>/va:arrivalDateTime</path><type>date</type></field>
			<field><name>Location</name><path>/va:location</path><type>string</type></field>
			<field><name>Documents</name><path>/va:documents/va:document/va:content</path><type>text</type><join> </join></field>
		</fields>
	)
else
	local:build-category-content("Vitals", $patient/va:results/va:vitals, $patient/va:results/va:vitals/va:vital,
		<fields xmlns="">
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:taken</path><type>date</type></field>
			<field><name>Measurements</name><path>/va:measurements/va:measurement</path><type>template</type><join>&lt;br/&gt;</join></field>
			<template for="Measurements">
				<value path="/va:measurement-name" type="string"/>: <value path="/va:value" type="string"/><value path="/va:units" type="string"/>
			</template>
		</fields>
	)