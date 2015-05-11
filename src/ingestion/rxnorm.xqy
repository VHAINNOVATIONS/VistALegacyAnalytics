xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : ingest-rxnorm.xqy
 :
 : @author Brad Mann
 : @author Michael Blakeley
 :
 : This main module is used by RecordLoader to ingest rxnorm documents.
 : Requires DelimitedDataLoader configuration.
 :
 :)
declare namespace va="ns://va.gov/2012/ip401" ;
declare namespace rx="ns://va.gov/2012/ip401/ontology/rxnorm" ;

import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";

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

declare variable $EXISTS as xs:boolean := exists(doc($URI)) ;

declare variable $RESULTS as element(rx:atom) := xdmp:unquote(
  $XML-STRING,
  $NAMESPACE,
  if (not($LANGUAGE)) then ()
  else concat('default-language=', $LANGUAGE))/* ;

if ($NAMESPACE eq $on:NAMESPACE-RXNORM) then () else error(
  (), 'UNEXPECTED-NS',
  text { $NAMESPACE, 'does not match', $on:NAMESPACE-RXNORM })
,
if ($SKIP-EXISTING and $EXISTS) then ()
else in:rxnorm-insert(
  $URI,
  $RESULTS,
  ('execute', 'insert', 'read', 'update') ! in:permissions(
    xdmp:value('$ROLES-'||upper-case(.)), .),
  in:split($COLLECTIONS),
  0,
  xs:unsignedLong(in:split($FORESTS)))

(: rxnorm.xqy :)