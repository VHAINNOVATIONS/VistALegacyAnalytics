xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare variable $URI as xs:string external;

declare function local:add-concept-label($e as element())
    as element()
{
  element { in:node-name($e) }  {
    attribute label {
      $e/@value
      || ' '
      || on:get-concept-by-code($e/@value)/on:concept/@short-description },
    $e/@value,
    $e/@value/string() }
};

declare function local:add-facet-label-to-icd9($results)
{
  let $conceptNodes := $results//(va:icd | va:icd1 | va:icd2 | va:icd3 | va:icd4 | va:icd5 | va:icd6 |
    va:icd7 | va:icd8 | va:icd9 | va:principalDiagnosis | va:secondaryDiagnosis1 |
    va:secondaryDiagnosis2 | va:secondaryDiagnosis3 | va:secondaryDiagnosis4 | va:secondaryDiagnosis5 |
    va:secondaryDiagnosis6 | va:secondaryDiagnosis7 | va:secondaryDiagnosis8 | va:secondaryDiagnosis9 |
    va:secondaryDiagnosis10 | va:secondaryDiagnosis11 | va:secondaryDiagnosis12 | va:secondaryDiagnosis13)
  for $conceptNode in $conceptNodes
    let $cleanedNode := functx:remove-attributes($conceptNode, ('label'))
    let $enrichedNode := local:add-concept-label($cleanedNode)
    let $_ := xdmp:node-replace($conceptNode, $enrichedNode)
    return $enrichedNode
};

let $results := doc($URI)/va:vpr/va:results
let $_ := local:add-facet-label-to-icd9($results)
let $vpr := doc($URI)/va:vpr
let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:conceptEnrichment'))
return $URI



