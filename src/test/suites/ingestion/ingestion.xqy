xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : suites/ingestion/ingestion.xqy
 :
 : @author Bradley Mann
 : @author Michael Blakeley
 :
 : This test module exercises the ingestion library module.
 :
 :)

import module namespace test="http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace va = "ns://va.gov/2012/ip401";
declare namespace geo = "http://marklogic.com/geocode";

declare function local:paths($node as node()) {
  for $n in $node/(* | @*)
  return (
    xdmp:path($n),
    local:paths($n)
  )
};

let $doc-uri := "/vpr/TEST/999998"
let $doc := doc($doc-uri)
return
  if (fn:not(fn:exists($doc))) then
    test:fail("No test document found.")
  else
    (
      let $paths := local:paths($doc)
      let $paths :=
        for $path in $paths
        return fn:replace($path, "\[[^\]]+\]", "")
      let $attribute-paths :=
        for $path in $paths
        return if (fn:contains($path, "@") and fn:not(fn:contains($path, "@total")) and fn:not(fn:contains($path, "@normalized")) and fn:not(fn:contains($path, "@geo"))) then $path else ()
      (: Take a random sample of attributes to make sure they were properly placed as child elements :)
      let $indexes :=
        for $i in (1 to 100)
        return xdmp:random(fn:count($attribute-paths))
      for $idx in $indexes
        let $path := $attribute-paths[$idx]
        return if ($path) then
          let $node := xdmp:unpath(fn:concat('doc("', $doc-uri, '")', $path))[1]
          let $name := fn:node-name($node)
          let $full-attribute-path := fn:concat('doc("', $doc-uri, '")', xdmp:path($node))
          let $all-attributes-path := fn:replace($full-attribute-path, fn:concat("@", $name), "@*")
          let $full-element-path :=
            if (fn:local-name-from-QName($name) = "value" and fn:count(xdmp:unpath($all-attributes-path)) = 1) then
              fn:replace($full-attribute-path, fn:concat("/@", $name), "")
            else
              fn:replace($full-attribute-path, fn:concat("@", $name), fn:concat("va:", fn:local-name($node)))
          return test:assert-equal(fn:string(xdmp:unpath($full-attribute-path)), fn:string(xdmp:unpath($full-element-path)))
        else (),
        (: Test that geocoding is working. The sample doc should have 3 address elements for the white house :)
        test:assert-equal(fn:count($doc//va:address), 3),
        for $address in $doc//va:address
        return (test:assert-equal(fn:string($address/@geo:lat), "38.8976777"), test:assert-equal(fn:string($address/@geo:lon), "-77.0365170")),
        (: Test the free-text address extraction. The test document has an address for the empire state building in a text field :)
        let $address := $doc//geo:address[@normalized = "350 5th Avenue New York, NY 10118"]
        return (
          test:assert-exists($address),
          test:assert-equal(fn:string($address/@geo:lat), "40.7484395"),
          test:assert-equal(fn:string($address/@geo:lon), "-73.9856709")
        ),
        (: Test that a site tag was added to the metadata section of the document :)
        test:assert-equal(fn:string($doc//va:site), "TEST")
      )
