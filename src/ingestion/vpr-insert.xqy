(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : vpr-insert.xqy
 :
 : @author Michael Blakeley
 :
 : This main module is called by ingest/vpr.xqy
 :
 :)

declare namespace va="ns://va.gov/2012/ip401" ;

import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";

declare option xdmp:mapping "false";

declare variable $URI as xs:string external;
declare variable $NEW as element(va:vpr) external;
declare variable $ROLES-EXECUTE as xs:string external;
declare variable $ROLES-INSERT as xs:string external;
declare variable $ROLES-READ as xs:string external;
declare variable $ROLES-UPDATE as xs:string external;
declare variable $COLLECTIONS as xs:string external;
declare variable $SKIP-EXISTING as xs:boolean external;
declare variable $ERROR-EXISTING as xs:boolean external;
declare variable $FORESTS as xs:string external;

(: This belongs in the update transaction. :)
declare variable $EXISTS as xs:boolean := exists(doc($URI)) ;

xdmp:log(text { $URI, xdmp:describe($NEW), $SKIP-EXISTING, $EXISTS }),
if (not($ERROR-EXISTING and $EXISTS)) then ()
else error((), 'DUPLICATE-URI', $URI)
,
if ($SKIP-EXISTING and $EXISTS) then ()
else in:document-insert(
  $URI,
  (: This last rewrap is for PRM.
   : It has to happen in the update transaction.
   :)
  element { node-name($NEW) } {
    $NEW/@*,
    in:identify(
      $URI,
      (: Avoid any function-mapping ambiguity. Force an error if empty. :)
      $NEW/va:results/va:demographics/va:patient treat as element()),
    $NEW/node() },
  $ROLES-EXECUTE, $ROLES-INSERT,
  $ROLES-READ, $ROLES-UPDATE,
  $COLLECTIONS, (), $FORESTS)

(: vpr-insert.xqy :)
