xquery version "1.0-ml";
(:
 : Copyright (c) 2013 Information Innovators Inc. All Rights Reserved.
 :
 : lib/map-utils.xqy
 :
 : @author Michael Blakeley
 :
 : This library module implements map utility routines.
 :
 :)
module namespace mu = "ns://va.gov/2012/ip401/map-utils";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function mu:map(
  $m as map:map,
  $seq as item()*)
as map:map
{
  (: Map keys must be strings. :)
  $seq ! map:put($m, xs:string(.), .)
  ,
  (: Final result. :)
  $m
};

(: Given a sequence of items, return an identity map. :)
declare function mu:map(
  $seq as item()*)
as map:map
{
  mu:map(map:map(), $seq)
};

(: Given a map, return all values. :)
declare function mu:get(
  $m as map:map)
as item()*
{
  map:get($m, map:keys($m))
};

(: Given a map, count all values. :)
declare function mu:count-all(
  $m as map:map)
as item()*
{
  count(mu:get($m))
};

(: lib/map-utils.xqy :)