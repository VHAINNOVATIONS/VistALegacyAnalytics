xquery version "1.0-ml";
(:
 : If ingestion missed any known facility locations for the input site,
 : enrich them.
 :)

declare namespace geo="http://marklogic.com/geocode";
declare namespace va = "ns://va.gov/2012/ip401" ;

import module namespace cfg = "http://marklogic.com/roxy/config"
  at "/app/config/config.xqy";

declare variable $SITE as xs:string external ;

text {
  "Spawned",
  count(
    for $uri in cts:uris(
      (), (),
      cts:and-not-query(
        cts:and-query(
          (cts:directory-query('/vpr/', 'infinity'),
            cts:element-query(
              xs:QName('va:facility-name'), cts:and-query(())))),
        cts:element-query(
          xs:QName('va:facility-location'), cts:and-query(()))))
    let $_ := xdmp:spawn(
      'facility-location-task.xqy',
      (xs:QName('SITE'), $SITE,
        xs:QName('URI'), $uri))
    return $uri),
  "tasks" }

(: fixup/facility-location.xqy :)