xquery version "1.0-ml";
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace enrich = "ns://va.gov/2012/ip401/enrich-util" at "/lib/enrich.xqy";

declare variable $URI as xs:string external;

let $vpr := doc($URI)/va:vpr

let $events := ($vpr/va:meta/va:enrichment/enr:events/enr:eventDate/node())
for $event in $events
let $name := $event/@name
let $eventText :=  $event/text()
let $_ := (
  if(not($eventText)) then
    let $newEvent := element {node-name($event)}
                             {$event/@*,
                              $name/string()
                             }
    return xdmp:node-replace($event, $newEvent )
  else ()
)
return $URI