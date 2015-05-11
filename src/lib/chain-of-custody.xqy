xquery version "1.0-ml";
(:
 : Copyright (c) 2013 Information Innovators Inc. All Rights Reserved.
 :
 : lib/chain-of-custody.xqy
 :
 : @author Michael Blakeley
 :
 : This library module implements chain of custody (CoC) routines
 : for auditing imported records.
 :
 :)
module namespace coc = "ns://va.gov/2012/ip401/chain-of-custody";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace mu = "ns://va.gov/2012/ip401/map-utils"
  at "/lib/map-utils.xqy";
import module namespace vpr = "ns://va.gov/2012/ip401/vpr"
  at "/lib/vpr.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $NAMESPACE := namespace-uri(<coc:x/>) ;

(: Given a site and a sequence of ids,
 : return any that do not exist in the database.
 :)
declare function coc:ids-drop(
  $site as xs:string,
  $id-list as xs:string*)
as xs:string*
{
  mu:get(
    mu:map($id-list) ! (
      . - cts:values(
        $vpr:ID-REFERENCE,
        (), ('map'),
        cts:and-query(
          (vpr:site-query($site),
            vpr:id-query($id-list))))))
};

declare function coc:values-to-elements(
  $field-names as xs:string+,
  $values as xs:string+)
as element()*
{
  for $x in (1 to count($field-names))
  return element {
    QName($NAMESPACE, $field-names[$x]) } {
    $values[$x] }
};

(: Check values against database. :)
declare function coc:audit(
  $vpr as element(va:vpr)?,
  $id as xs:string,
  $field-names as xs:string+,
  $values as xs:string+)
as element()*
{
  if (empty($vpr)) then element coc:missing {
    attribute id { $id },
    coc:values-to-elements($field-names, $values) }
  (: Check fields one by one :)
  else element coc:diff {
    attribute id { $id },
    let $actual := xdmp:with-namespaces(
      ('', $vpr:NAMESPACE),
      xdmp:unpath(
        '$vpr/('||string-join($field-names ! ('descendant::'||.), '|')||')'))
    for $f at $x in $field-names
    let $v := $values[$x]
    let $a := $actual[local-name(.) = $f]/@value/data(.)
    where empty($a) or not($a = $v)
    return element coc:field {
      attribute name { $f },
      attribute expected { $v },
      attribute actual { $a } } }[coc:field]
};

(: Map keys are ids,
 : values are sequences of field values
 : in the same order as field-name.
 :)
declare function coc:map-audit(
  $site as xs:string,
  $field-names as xs:string+,
  $map as map:map)
as element()*
{
  (: Assert that the first field is id. :)
  if ($field-names[1] eq 'id') then () else error(
    (), 'COC-BADFIELD',
    text { 'First field must be "id" not', xdmp:describe($field-names[1]) }),
  (: Assert that the first field is id. :)
  if (map:keys($map)) then () else error(
    (), 'COC-EMPTYMAP', text { 'No values to verify' }),
  for $k in map:keys($map)
  return coc:audit(
    doc(vpr:uri($site, $k))/va:vpr, $k, $field-names, map:get($map, $k))
};

declare function coc:csv-split(
  $csv as xs:string)
as xs:string+
{
  (: TODO support quoted values :)
  tokenize($csv, ',')
};

declare function coc:csv-map-put(
  $map as map:map,
  $csv as xs:string+)
as empty-sequence()
{
  (: Put the entire csv, so we also verify the key field. :)
  map:put($map, $csv[1], $csv)
};

(: Recursively populate a map of keys and data. :)
declare function coc:csv-to-map(
  $map as map:map,
  $data as xs:string*)
as map:map
{
  (: Stop recursion when we run out of data. :)
  if (empty($data)) then $map else (
    coc:csv-map-put($map, coc:csv-split($data[1])),
    coc:csv-to-map($map, subsequence($data, 2)))
};

(: Given a csv list, check the site data.
 : Each CSV line must start with an id,
 : and the headings must exactly name the fields to be checked.
 :)
declare function coc:csv-audit(
  $site as xs:string,
  $csv-list as xs:string+)
as element()*
{
  coc:map-audit(
    $site,
    coc:csv-split($csv-list[1]),
    coc:csv-to-map(
      map:map(),
      subsequence($csv-list, 2)))
};

(: lib/chain-of-custody.xqy :)