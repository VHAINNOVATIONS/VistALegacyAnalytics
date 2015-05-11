
xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare variable $URI as xs:string external;


declare function local:add-age-at-procedure($results, $dob)
{
  for $procedure in $results/va:procedures/va:procedure
  let $_ := xdmp:node-delete($procedure/va:ageAtProcedure)

  return
    if ($procedure/va:dateTime) then
      let $date :=  util:convert-vpr-date($procedure/va:dateTime)
      let $age := util:get-approx-age-at-date($date, $dob)
      let $type := $procedure/va:type
      return xdmp:node-insert-after($type, element va:ageAtProcedure { $age })
    else ()

};


declare function local:add-enrichment-indicator($results)
{
  let $meta := $results/../va:meta
  let $indicator := element va:procedureEnrichment {fn:current-date() }
  return
    if ($meta/va:enrichment) then
        if ($meta/va:enrichment/va:procedureEnrichment) then
            xdmp:node-replace($meta/va:enrichment/va:procedureEnrichment, $indicator)
         else
            xdmp:node-insert-child($meta/va:enrichment, $indicator )
    else xdmp:node-insert-child($meta, element va:enrichment{ $indicator } )
};

let $results := doc($URI)/va:vpr/va:results
let $dob := util:convert-vpr-date($results/va:demographics/va:patient/va:dob)
let $_ := local:add-age-at-procedure($results, $dob)
let $_ := local:add-enrichment-indicator($results)

return $URI



