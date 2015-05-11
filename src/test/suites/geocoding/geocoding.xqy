xquery version "1.0-ml";

import module namespace test="http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace geo = "http://marklogic.com/geocode" at "/lib/geocode.xqy";
declare namespace va = "ns://va.gov/2012/ip401";

let $text := "This is a block of text. It contains several examples of addresses that should be extracted:

The NASA headquarters street address is
300 E Street SW
Washington DC 20024-3210

The Udvar-Hazy Air and Space museum is at 14390 Air and Space Museum Parkway Chantilly, Va 20151 and it is open every day except December 25.

The NYSE is located at
11 Wall St New York, NY 10005
"

let $markup := geo:markup-addresses-in-text($text)
let $addresses := $markup ! (typeswitch (.) case element(geo:address) return . default return ())
return (
  (: syntax = expected, actual :)
  test:assert-equal(3, fn:count($addresses)),
  test:assert-equal("38.8829179", fn:string($addresses[1]/@geo:lat)),
  test:assert-equal("-77.0162720", fn:string($addresses[1]/@geo:lon)),
  test:assert-true($addresses[2]/@geo:lat castable as xs:double),
  test:assert-true($addresses[2]/@geo:lon castable as xs:double),
  test:assert-equal("40.7068599", fn:string($addresses[3]/@geo:lat)),
  test:assert-equal("-74.0111281", fn:string($addresses[3]/@geo:lon))
)
