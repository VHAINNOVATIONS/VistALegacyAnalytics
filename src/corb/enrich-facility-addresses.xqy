xquery version "1.0-ml";

declare namespace va = "ns://va.gov/2012/ip401";

import module namespace cfg="http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";
import module namespace util="ns://va.gov/2012/ip401/util"
  at "/lib/util.xqy";

declare variable $URI as xs:string external;

declare function local:facility-node-has-name($facility as element() ) as xs:boolean
{
 if ($facility[not(@name)])
   then false()
   else true()
};

let $vpr := doc($URI)/va:vpr
let $facility-nodes := $vpr/va:results//va:facility
let $site := $vpr/va:meta/va:site/fn:string()
let $_ := (
 for $node in $facility-nodes
   (: found 10 facilities without names.  Current geo mapping for facility requires a facility name lookup. :)
   return if(local:facility-node-has-name($node))
     then
       let $_ := xdmp:node-delete($node/va:facility-location)
       let $_ := xdmp:node-insert-child($node,
         (cfg:site-location-geo($site, $node/va:facility-name/fn:string())
           treat as element())/element va:facility-location { @* })
         return ()
     else ()
)
let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:facilityAddressEnrichment'))
return $URI
