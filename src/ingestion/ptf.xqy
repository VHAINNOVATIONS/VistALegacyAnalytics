xquery version "1.0-ml";
(:
 : Copyright (c) 2012-2013 Information Innovators Inc. All Rights Reserved.
 :
 : ingestion/ptf.xqy
 :
 : @author Michael Blakeley
 :
 : This main module is used by RecordLoader.
 :
 :)

declare namespace va="ns://va.gov/2012/ip401" ;

import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";

declare option xdmp:mapping "false";

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

declare variable $PTF as element(va:PTF) := xdmp:unquote(
  $XML-STRING,
  $NAMESPACE,
  if (not($LANGUAGE)) then ()
  else concat('default-language=', $LANGUAGE))/* ;

in:assert-namespace($NAMESPACE),
(: SKIP-EXISTING will not work here :)
if ($SKIP-EXISTING) then error((), 'UNIMPLEMENTED')
else in:ptf-merge(in:ptf-map($PTF))

(: ptf.xqy :)
