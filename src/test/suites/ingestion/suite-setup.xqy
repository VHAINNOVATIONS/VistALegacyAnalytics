(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : suites/prm/suite-setup.xqy
 :
 : @author Michael Blakeley
 :
 : Suite setup for prm test modules.
 :
 :)
xquery version "1.0-ml";

declare namespace va="ns://va.gov/2012/ip401" ;

import module namespace test="http://marklogic.com/roxy/test-helper"
  at "/test/test-helper.xqy";
import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";

declare variable $URI := "/vpr/A/vpr-0" ;
declare variable $RESULTS as element(va:results) := xdmp:unquote(
  xdmp:quote(test:get-test-file("vpr-0.xml")),
  $in:NAMESPACE)/* ;

xdmp:document-insert(
  $URI,
  (: no enrichment :)
  in:wrap($URI, in:map($RESULTS, false(), false()))),

(: ontology data :)
xdmp:document-insert(
  on:uri-icd9('024.'),
  on:concept-icd9('024.', "Glanders", "Glanders")),
xdmp:document-insert(
  on:uri-icd9('786.2'),
  on:concept-icd9('786.2', "Cough", "Cough")),

(: end :)
()

(: suites/prm/suite-setup.xqy :)
