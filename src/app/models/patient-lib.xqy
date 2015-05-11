xquery version "1.0-ml";

module namespace patient-lib = "ns://va.gov/2012/ip401/patient";

import module namespace config = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $RACES := ("American Indian or Alaska Native", "Asian", "Black or African-American", "Native Hawaiian or Other Pacific Islander", "White", "Other Race", "Hispanic or Latino");
declare variable $GENDERS := ("M", "F");
declare variable $AGES :=
	for $range in $config:AGE-RANGES//range
	return fn:concat($range/min, '-', $range/max);

declare variable $PATIENT-EXTRACTS :=
	<fieldset xmlns="">
		<fields name="Allergies/Reactions" path="/va:results/va:reactions/va:allergy">
			<field><name>Type</name><path>/va:type/@name</path><type>string</type></field>
			<field><name>Class</name><path>/va:drugClasses/va:drugClass/@name</path><type>string</type></field>
			<field><name>Reactions</name><path>/va:reactions/va:reaction/@name</path><type>string</type></field>
			<field><name>Ingredients</name><path>/va:drugIngredients/va:drugIngredient/@name</path><type>string</type></field>
			<field><name>Entered</name><path>/va:entered</path><type>date</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
		</fields>
		<fields name="Appointments" path="/va:results/va:appointments/va:appointment">
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Status</name><path>/va:apptStatus</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
			<field><name>Provider</name><path>/va:provider/@name</path><type>string</type></field>
			<field><name>Category</name><path>/va:serviceCategory/@name</path><type>string</type></field>
		</fields>
		<fields name="Consults" path="/va:results/va:consults/va:consult">
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Procedure</name><path>/va:procedure</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Status</name><path>/va:apptStatus</path><type>string</type></field>
			<field><name>Requested</name><path>/va:requested</path><type>date</type></field>
		</fields>
		<fields name="Documents" path="/va:results/va:documents/va:document">
			<field><name>Title</name><path>/va:localTitle</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:referenceDateTime</path><type>date</type></field>
			<field><name>Clinicians</name><path>/va:clinicians/va:clinician/va:clinician-name</path><type>string</type></field>
			<field><name>Content</name><path>/va:content</path><type>text</type></field>
		</fields>
		<fields name="Education Topics" path="/va:results/va:educationTopics/va:educationTopic">
			<field><name>Name</name><path>/va:educationTopic-name</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
		<fields name="Exams" path="/va:results/va:exams/va:exam">
			<field><name>Name</name><path>/va:exam-name</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
		<fields name="Health Factors" path="/va:results/va:healthFactors/va:factor">
			<field><name>Name</name><path>/va:factor-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Recorded</name><path>/va:recorded</path><type>date</type></field>
			<field><name>Comment</name><path>/va:comment</path><type>string</type></field>
		</fields>
		<fields name="Flags" path="/va:results/va:flags/va:flag">
			<field><name>Name</name><path>/va:flag-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
		<fields name="Immunizations" path="/va:results/va:immunizations/va:immunization">
			<field><name>Name</name><path>/va:immunization-name</path><type>string</type></field>
			<field><name>Contraindicated</name><path>/va:contraindicated</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Administered</name><path>/va:administered</path><type>date</type></field>
		</fields>
		<fields name="Insurance Policies" path="/va:results/va:insurancePolicies/va:insurancePolicy">
			<field><name>Company</name><path>/va:company/va:company-name</path><type>string</type></field>
			<field><name>Type</name><path>/va:insuraceType/va:insuranceType-name</path><type>string</type></field>
			<field><name>Subscriber</name><path>/va:subscriber/va:subscriber-name</path><type>string</type></field>
			<field><name>Relationship</name><path>/va:relationship</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Effective Date</name><path>/va:effectiveDate</path><type>date</type></field>
		</fields>
		<fields name="Labs" path="/va:results/va:labs/va:lab">
			<field><name>Name</name><path>/va:localName</path><type>string</type></field>
			<field><name>Status</name><path>/va:status</path><type>string</type></field>
			<field><name>Date</name><path>/va:collected</path><type>date</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Comment</name><path>/va:comment</path><type>text</type></field>
		</fields>
		<fields name="Medicines" path="/va:results/va:meds/va:med">
			<field><name>Name</name><path>/va:med-name</path><type>string</type></field>
			<field><name>Provider</name><path>/va:currentProvider/@name</path><type>string</type></field>
			<field><name>Days Supply</name><path>/va:daysSupply</path><type>string</type></field>
			<field><name>Directions</name><path>/va:sig</path><type>string</type></field>
			<field><name>Start</name><path>/va:start</path><type>date</type></field>
			<field><name>Last Filled</name><path>/va:lastFilled</path><type>date</type></field>
		</fields>
		<fields name="Observations" path="/va:results/va:observations/va:observations">
			<field><name>Name</name><path>/va:observation-name</path><type>string</type></field>
			<!--Placeholder for observations. No test data currently available. -->
		</fields>
		<fields name="Problems" path="/va:results/va:problems/va:problem">
			<field><name>Name</name><path>/va:problem-name</path><type>string</type></field>
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Onset</name><path>/va:onset</path><type>date</type></field>
			<field><name>Provider</name><path>/va:provider/va:provider-name</path><type>string</type></field>
		</fields>
		<fields name="Procedures" path="/va:results/va:procedures/va:procedure">
			<field><name>Name</name><path>/va:procedure-name</path><type>string</type></field>
			<field><name>Category</name><path>/va:category</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
			<field><name>Location</name><path>/va:location/va:location-name</path><type>string</type></field>
			<field><name>Provider</name><path>/va:provider/va:provider-name</path><type>string</type></field>
		</fields>
		<fields name="Skin Tests" path="/va:results/va:skinTests/va:skinTest">
			<field><name>Name</name><path>/va:skinTest-name</path><type>string</type></field>
			<field><name>Result</name><path>/va:result</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
		</fields>
		<fields name="Visits" path="/va:results/va:visits/va:visit">
			<field><name>Type</name><path>/va:type/va:type-name</path><type>string</type></field>
			<field><name>Reason</name><path>/va:reason/va:narrative</path><type>string</type></field>
			<field><name>Service</name><path>/va:service</path><type>string</type></field>
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:dateTime</path><type>date</type></field>
			<field><name>Location</name><path>/va:location</path><type>string</type></field>
			<field><name>Documents</name><path>/va:documents/va:document/va:content</path><type>text</type><join> </join></field>
		</fields>
		<fields name="Vitals" path="/va:results/va:vitals/va:vital">
			<field><name>Facility</name><path>/va:facility/va:facility-name</path><type>string</type></field>
			<field><name>Date</name><path>/va:taken</path><type>date</type></field>
			<field><name>Measurements</name><path>/va:measurements/va:measurement</path><type>template</type><join>&lt;br/&gt;</join></field>
			<template for="Measurements">
				<value path="/va:measurement-name" type="string"/>: <value path="/va:value" type="string"/><value path="/va:units" type="string"/>
			</template>
		</fields>
	</fieldset>;

declare function patient-lib:build-table-map($pairs as element()*) {
  let $table := map:map()
  let $_build-table :=
    for $pair in $pairs
    let $key := $pair/cts:value[1]
    let $subkey := $pair/cts:value[2]
    let $_check := if (map:contains($table, $key)) then () else map:put($table, $key, map:map())
    let $cols := map:get($table, $key)
    return map:put($cols, $subkey, cts:frequency($pair))
   return $table
};

declare function patient-lib:build-age-ranges-map($pivot as cts:reference, $q as element()?) {
	let $pairs :=
		if (<x>{$pivot}</x>//cts:localname/fn:string() = "med-name") then
			cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:ageAtRx")), ("proximity=1", "item-frequency"), cts:query($q))
		else if (<x>{$pivot}</x>//cts:path-expression/fn:string() = "/va:vpr/va:results/va:visits/va:visit/va:facility/va:facility-name") then
			cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:ageAtVisit")), ("proximity=1", "item-frequency"), cts:query($q))
		else if (<x>{$pivot}</x>//cts:path-expression/fn:string() = "/va:vpr/va:results/va:procedures/va:procedure/va:type/va:type-name") then
			cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:ageAtProcedure")), ("proximity=1", "item-frequency"), cts:query($q))
		else
			cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:ageAtDiagnosis")), ("proximity=20", "item-frequency"), cts:query($q))
	let $ranges := $config:AGE-RANGES//range
	let $table := map:map()
	let $_build-table :=
		for $pair in $pairs
		let $key := $pair/cts:value[1]
		let $subkey := $pair/cts:value[2]
		let $subkey := if ($subkey = "") then -1 else xs:integer($subkey)
		let $count := cts:frequency($pair)
		let $range := if ($subkey = -1) then "Unknown Age" else
    		for $range in $ranges return
				if ($subkey ge xs:integer($range/min) and $subkey le xs:integer($range/max)) then
					fn:concat($range/min, "-", $range/max)
				else
					()
  		let $_check := if (map:contains($table, $key)) then () else map:put($table, $key, map:map())
		let $cols := map:get($table, $key)
		let $current-count := if (map:contains($cols, $range)) then map:get($cols, $range) else 0
		return map:put($cols, $range, $current-count + $count)
	return $table
};

declare function patient-lib:build-result-table($pivot as cts:reference, $q as element()?) {
  let $gender-co := cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:gender")), ("item-frequency"), cts:query($q))
  let $race-co := cts:value-co-occurrences($pivot, cts:element-reference(xs:QName("va:primaryRace")), ("item-frequency"), cts:query($q))
  let $gender-table := patient-lib:build-table-map($gender-co)
  let $race-table := patient-lib:build-table-map($race-co)
  let $age-table := patient-lib:build-age-ranges-map($pivot, $q)
  let $joined-table := map:map()
  let $_join := (
    for $key in map:keys($gender-table)
    let $_check := if (map:contains($joined-table, $key)) then () else map:put($joined-table, $key, map:map())
    return map:put($joined-table, $key, map:get($gender-table, $key)),
    for $key in map:keys($race-table)
    let $_check := if (map:contains($joined-table, $key)) then () else map:put($joined-table, $key, map:map())
    let $racerow := map:get($race-table, $key)
    for $key2 in map:keys($racerow)
    let $rowmap := map:get($joined-table, $key)
    return map:put($rowmap, $key2, map:get($racerow, $key2)),
    for $key in map:keys($age-table)
    let $_check := if (map:contains($joined-table, $key)) then () else map:put($joined-table, $key, map:map())
    let $agerow := map:get($age-table, $key)
    for $key2 in map:keys($agerow)
    let $rowmap := map:get($joined-table, $key)
    return map:put($rowmap, $key2, map:get($agerow, $key2)),
    for $key in map:keys($joined-table)
    let $row := map:get($joined-table, $key)
    return map:put($row, "key", $key)
  )
  return $joined-table
};
