(: Shared step called by CORB once before it runs any transformation steps :)

xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";

let $q := cts:and-not-query(
  cts:directory-query("/vpr/", "infinity"),
  cts:element-query(
    xs:QName("enr:exposureEnrichment"),
    cts:and-query(())))
let $uris := cts:uris((), (), $q)
return (fn:count($uris), $uris)
