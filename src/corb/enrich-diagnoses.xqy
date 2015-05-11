(:
 :  Add ageAtDiagnosis child element to every visit and problem node, as well as content nodes containing the "concept" (= diagnosis) element.
 :  Run against documents that have already been given the "va" namespace, either in the database or as part of ingest.
 :  Reentrant -- drops old ageAtDiagnosis nodes and then reinserts them using current document reference nodes.
 :)


xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace on = "ns://va.gov/2012/ip401/ontology";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare variable $URI as xs:string external;

declare function local:add-child($node, $dob, $date-node)
{
  let $date :=  util:convert-vpr-date($date-node)
  let $age := util:get-approx-age-at-date($date, $dob)
  let $_ :=  xdmp:node-insert-child($node, element va:ageAtDiagnosis { $age })
  return ()
};

declare function local:add-node-after($node, $dob, $date-node)
{
  let $date :=  util:convert-vpr-date($date-node)
  let $age := util:get-approx-age-at-date($date, $dob)
  let $_ :=  xdmp:node-insert-after($node, element va:ageAtDiagnosis { $age })
  return ()
};


declare function local:enrich-note-node($content-node, $dob, $date-node)
{
  let $x := 1
  return
    if ($content-node/on:concept)
      then local:add-child($content-node, $dob, $date-node)
      else ()
};


declare function local:enrich-visits($results, $dob)
{
  for $visit in $results/va:visits/va:visit
  let $_ := xdmp:node-delete($visit/va:ageAtDiagnosis)
  let $reason := $visit/va:reason
  return
    if ($reason) then local:add-node-after($reason, $dob, $visit/va:dateTime)
    else ()
};

declare function local:enrich-ptf-diagnoses($results, $dob)
{
  for $node in $results/va:patientTreatments/va:patientTreatment
  let $_ := xdmp:node-delete($node/va:ageAtDiagnosis)
  return
    if ($node/va:principalDiagnosis) then local:add-child($node, $dob, $node/admissionDate )
    else ()
};


declare function local:enrich-problems($results, $dob)
{
  for $node in $results/va:problems/va:problem
  let $_ := xdmp:node-delete($node/va:ageAtDiagnosis)
  return local:add-child($node, $dob, $node/va:entered)
};

declare function local:enrich-order-notes($results, $dob)
{
  for $node in $results/va:orders/va:order
  let $_ := xdmp:node-delete($node/va:content/va:ageAtDiagnosis)
  return local:enrich-note-node($node/va:content, $dob, $node/va:entered)
};

declare function local:enrich-document-notes($results, $dob)
{
  for $node in $results/va:documents/va:document
  let $_ := xdmp:node-delete($node/va:content/va:ageAtDiagnosis)
  return local:enrich-note-node($node/va:content, $dob, $node/va:referenceDateTime)
};

declare function local:enrich-flag-notes($results, $dob)
{
  for $node in $results/va:flags/va:flag
  let $_ := xdmp:node-delete($node/va:content/va:ageAtDiagnosis)
  return local:enrich-note-node($node/va:content, $dob, $node/va:assigned )
};


declare function local:add-enrichment-indicator($results)
{
  let $meta := $results/../va:meta
  let $indicator := element va:diagnoses {fn:current-date() }
  return
    if ($meta/va:enrichment) then
        if ($meta/va:enrichment/va:diagnoses) then
            xdmp:node-replace($meta/va:enrichment/va:diagnoses, $indicator)
         else
            xdmp:node-insert-child($meta/va:enrichment, $indicator )
    else xdmp:node-insert-child($meta, element va:enrichment{ $indicator } )
};


let $results := doc($URI)/va:vpr/va:results
let $dob := util:convert-vpr-date($results/va:demographics/va:patient/va:dob)
let $_ := local:enrich-visits($results, $dob)
let $_ := local:enrich-problems($results, $dob)
let $_ := local:enrich-document-notes($results, $dob)
let $_ := local:enrich-order-notes($results, $dob)
let $_ := local:enrich-flag-notes($results, $dob)
let $_ := local:enrich-ptf-diagnoses($results, $dob)
let $_ := local:add-enrichment-indicator($results)
return $URI



