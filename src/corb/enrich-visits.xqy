
xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare variable $URI as xs:string external;


declare function local:add-age-at-visit($results, $dob)
{
  for $visit in $results/va:visits/va:visit
  let $_ := xdmp:node-delete($visit/va:ageAtVisit)

  return
    if ($visit/va:dateTime) then
      let $date :=  util:convert-vpr-date($visit/va:dateTime)
      let $age := util:get-approx-age-at-date($date, $dob)
      let $facility := $visit/va:facility
      return xdmp:node-insert-after($facility, element va:ageAtVisit { $age })
    else ()

};


declare function local:add-enrichment-indicator($results)
{
  let $meta := $results/../va:meta
  let $indicator := element va:visitEnrichment {fn:current-date() }
  return
    if ($meta/va:enrichment) then
        if ($meta/va:enrichment/va:visitEnrichment) then
            xdmp:node-replace($meta/va:enrichment/va:visitEnrichment, $indicator)
         else
            xdmp:node-insert-child($meta/va:enrichment, $indicator )
    else xdmp:node-insert-child($meta, element va:enrichment{ $indicator } )
};

let $results := doc($URI)/va:vpr/va:results
let $dob := util:convert-vpr-date($results/va:demographics/va:patient/va:dob)
let $_ := local:add-age-at-visit($results, $dob)
let $_ := local:add-enrichment-indicator($results)

return $URI



