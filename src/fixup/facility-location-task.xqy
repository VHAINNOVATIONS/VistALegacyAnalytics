xquery version "1.0-ml";
(:
 : Enrich the facility elements in a single document.
 :)

declare namespace geo="http://marklogic.com/geocode";
declare namespace va = "ns://va.gov/2012/ip401" ;

import module namespace cfg = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

declare variable $SITE as xs:string external ;
declare variable $URI as xs:string external ;

for $f in doc($URI)//va:facility[va:facility-name][not(va:facility-location)]
let $id as xs:string := $f/va:facility-name
return xdmp:node-insert-child(
  $f,
  (cfg:site-location-geo($SITE, $id)
     treat as element())/element va:facility-location { @* })

(: fixup/facility-location-task.xqy :)