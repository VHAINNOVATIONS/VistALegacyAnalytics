xquery version "1.0-ml";

declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util="ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace geo = "http://marklogic.com/geocode" at "/lib/geocode.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"  at "/lib/ontology.xqy";

declare variable $URI as xs:string external;

declare function local:enrich-note(
  $note as node())
  as node()+
{
  typeswitch($note)
  case element()
    return element { node-name($note) } {
      $note/@*,
      geo:markup-addresses-in-text($note) }
  default return geo:markup-addresses-in-text($note)
};

declare function local:set-indicator($vpr)
{
  let $totalAddressCount := count(/va:vpr/va:results//(va:content|va:commentText)//geo:address)
  let $addressesResolvedByGoogle := count(/va:vpr/va:results//(va:content|va:commentText)//geo:address[@googleEarthSuccess="true"])
  return
      if ($totalAddressCount = 0) then
        (: set the indicator because this patient doesn't have any addresses :)
        let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:textGeoEnrichment'))
        return ()
      else
        if ($addressesResolvedByGoogle > 0) then
           let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:textGeoEnrichment'))
           return ()
        else ()
};

(: Based on old comment we only care about either adding a icd9 or geo-location enrichment :)
let $vpr := doc($URI)/va:vpr
let $text-nodes :=
(
    let $comments := $vpr/va:results//(va:content|va:commentText)
    for $comment in $comments return
        if (not(exists($comment//on:concept))) then $comment
        else ()
)
let $_ := (
  for $node in $text-nodes
  return xdmp:node-replace($node, local:enrich-note($node))
)
let $_ := local:set-indicator($vpr)
return $URI
