xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : suites/ingestion/prm.xqy
 :
 : @author Michael Blakeley
 :
 : This test module exercises the patient record matching code.
 :
 :)

declare namespace va = "ns://va.gov/2012/ip401";

import module namespace test="http://marklogic.com/roxy/test-helper"
  at "/test/test-helper.xqy";
import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";

declare function local:get($path as xs:string)
as element(va:patient)
{
  in:map(
    xdmp:unquote(
      xdmp:quote(test:get-test-file($path)),
      $in:NAMESPACE)/*,
    (: no enrichment :)
    false(), false())/
  va:demographics/va:patient
};

test:assert-exists(
  doc('/A/vpr-0')),
test:assert-not-exists(
  in:identify('/A/vpr-0', local:get('vpr-0.xml'))/*),
test:assert-equal(
  1,
  count(in:identify('/B/1', local:get('vpr-1.xml'))/*)),
test:assert-not-exists(
  in:identify('/B/2', local:get('vpr-2.xml'))/*)

(: suites/ingestion/prm.xqy :)
