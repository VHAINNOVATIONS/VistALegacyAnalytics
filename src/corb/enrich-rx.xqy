xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare variable $URI as xs:string external;


declare function local:add-age-at-rx($results, $dob)
{
  for $med in $results/va:meds/va:med
  let $_ := xdmp:node-delete($med/va:ageAtRx)
  let $latestDate := if ($med/va:lastFilled) then $med/va:lastFilled else $med/va:ordered
  let $date :=  util:convert-vpr-date($latestDate)
  let $age := util:get-approx-age-at-date($date, $dob)
  let $med-name := $med/va:med-name
  return xdmp:node-insert-after($med-name, element va:ageAtRx { $age })
};


declare function local:add-enrichment-indicator($results)
{
  let $meta := $results/../va:meta
  let $indicator := element va:rxEnrichment {fn:current-date() }
  return
    if ($meta/va:enrichment) then
        if ($meta/va:enrichment/va:rxEnrichment) then
            xdmp:node-replace($meta/va:enrichment/va:rxEnrichment, $indicator)
         else
            xdmp:node-insert-child($meta/va:enrichment, $indicator )
    else xdmp:node-insert-child($meta, element va:enrichment{ $indicator } )
};


let $results := doc($URI)/va:vpr/va:results
let $dob := util:convert-vpr-date($results/va:demographics/va:patient/va:dob)
let $_ := local:add-age-at-rx($results, $dob)
let $_ := local:add-enrichment-indicator($results)

return $URI
