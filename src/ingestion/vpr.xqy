xquery version "1.0-ml";
(:
 : Copyright (c) 2012-2013 Information Innovators Inc. All Rights Reserved.
 :
 : ingestion/vpr.xqy
 :
 : @author Michael Blakeley
 :
 : This main module is used by RecordLoader.
 :
 :)

declare namespace va="ns://va.gov/2012/ip401" ;

import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";

declare variable $URI as xs:string external;
declare variable $XML-STRING as xs:string external;
declare variable $NAMESPACE as xs:string external;
declare variable $LANGUAGE as xs:string external;
declare variable $ROLES-EXECUTE as xs:string external;
declare variable $ROLES-INSERT as xs:string external;
declare variable $ROLES-READ as xs:string external;
declare variable $ROLES-UPDATE as xs:string external;
declare variable $COLLECTIONS as xs:string external;
declare variable $SKIP-EXISTING as xs:boolean external;
declare variable $ERROR-EXISTING as xs:boolean external;
declare variable $FORESTS as xs:string external;

declare variable $RESULTS as element(va:results) := xdmp:unquote(
  $XML-STRING,
  $NAMESPACE,
  if (not($LANGUAGE)) then ()
  else concat('default-language=', $LANGUAGE))/* ;
declare variable $SITE as xs:string := in:site-from-uri($URI) ;
declare variable $URI-FINAL as xs:string := in:uri(
  $SITE, $RESULTS/va:demographics/va:patient) ;

in:assert-namespace($NAMESPACE),
(: Because of ontology enrichment we want
 : a timestamped outer query and an inner update.
 : This introduces a little extra overhead,
 : but still cheaper than running reverse-query in update mode.
 :)
xdmp:invoke(
  'vpr-insert.xqy',
  (xs:QName('URI'), $URI-FINAL,
    xs:QName('NEW'), in:vpr-wrap(
      $URI-FINAL, in:vpr-map($RESULTS, $SITE)),
    ('execute', 'insert', 'read', 'update')
    ! concat('ROLES-', upper-case(.))
    ! (xs:QName(.), xdmp:value('$'||.)),
    xs:QName('COLLECTIONS'), $COLLECTIONS,
    xs:QName('SKIP-EXISTING'), $SKIP-EXISTING,
    xs:QName('ERROR-EXISTING'), $ERROR-EXISTING,
    xs:QName('FORESTS'), $FORESTS))

(: ingestion/vpr.xqy :)
