xquery version "1.0-ml";
(:
 : Copyright (c) 2013 Information Innovators Inc. All Rights Reserved.
 :
 : lib/vpr.xqy
 :
 : @author Michael Blakeley
 :
 : This library module implements virtual patient record routines
 : for general query functionality.
 :
 :)
module namespace vpr = "ns://va.gov/2012/ip401/vpr";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $ROOT-URI := '/vpr/' ;

declare variable $ID-REFERENCE := cts:path-reference(
  '/va:vpr/va:meta/va:id',
  'collation=http://marklogic.com/collation/codepoint') ;

declare variable $NAMESPACE := namespace-uri(<va:vpr/>) ;

declare function vpr:id-query(
  $id-list as xs:string*)
as cts:query
{
  cts:element-value-query(xs:QName('va:id'), $id-list, 'exact')
};

declare function vpr:site-query(
  $site-list as xs:string*)
as cts:query
{
  cts:directory-query(
    if (empty($site-list)) then $ROOT-URI
    else $site-list ! vpr:uri(.),
    'infinity')
};

declare function vpr:site-query()
as cts:query
{
  vpr:site-query(())
};

declare function vpr:uri(
  $site as xs:string)
as xs:string
{
  $ROOT-URI||$site||'/'
};

declare function vpr:uri(
  $site as xs:string,
  $id as xs:anyAtomicType)
as xs:string
{
  vpr:uri($site)||$id
};

(: lib/vpr.xqy :)