xquery version "1.0-ml";

module namespace search-lib = "ns://va.gov/2012/ip401/search-lib";

import module namespace search="http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace patient-lib = "ns://va.gov/2012/ip401/patient"
  at "/app/models/patient-lib.xqy";
import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace va = "ns://va.gov/2012/ip401";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $HIGHLIGHT-QUERY as schema-element(cts:query)? := () ;

(: Convert the constraint text into an OR query against "Distance" and "Volume" :)
declare function search-lib:parse-date($constraint-qtext as xs:string,
                                 $right as schema-element(cts:query))
        as schema-element(cts:query)
{
  let $value := xs:decimal($right//cts:text)
  let $comparison :=
    if (fn:ends-with($constraint-qtext, 'LT ')) then
      "<"
    else if (fn:ends-with($constraint-qtext, 'GT ')) then
      ">"
    else if (fn:ends-with($constraint-qtext, 'GE ')) then
      ">="
    else
      "<="
  let $q :=
    <cts:or-query>{
      for $datefield in $patient-lib:PATIENT-EXTRACTS//*:field[*:type eq "date"]
      let $path := fn:concat('/va:vpr', $datefield/../@path, $datefield/*:path)
      return cts:path-range-query($path, $comparison, $value)
    }</cts:or-query>
  let $log := xdmp:log($constraint-qtext)
  return functx:add-attributes($q, xs:QName("qtextconst"), fn:concat($constraint-qtext, $right//cts:text))
};

declare function search-lib:parse-diagnosis-date(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  let $value := xs:float($right/cts:text)
  let $comparison :=
    if (fn:ends-with($constraint-qtext, 'LT ')) then "<"
    else if (fn:ends-with($constraint-qtext, 'GT ')) then ">"
    else if (fn:ends-with($constraint-qtext, 'GE ')) then ">="
    else "<="
  let $q :=
    document {
      if ($comparison = "<" or $comparison = "<=") then
        cts:path-range-query("/va:vpr/va:results/va:visits/va:visit/va:dateTime", $comparison, $value)
      else
        cts:path-range-query("/va:vpr/va:results/va:visits/va:visit/va:dateTime", $comparison, $value)
    }/*
  return functx:add-attributes($q, xs:QName("qtextconst"), fn:concat($constraint-qtext, $right/cts:text))
};

declare function search-lib:parse-diag(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  document {
    cts:element-attribute-word-query(
      xs:QName("va:principalDiagnosis"), xs:QName("label"),
      $right/cts:text) }/*
};

declare function search-lib:highlight-query-rewrite(
  $q as element())
as element()?
{
  typeswitch ($q)
  (: Recurse for grouping terms. :)
  case element(cts:and-query) return element cts:and-query {
    $q/@*,
    search-lib:highlight-query-rewrite($q/node()) }
  case element(cts:or-query) return element cts:or-query {
    $q/@*,
    search-lib:highlight-query-rewrite($q/node()) }
  case element(cts:near-query) return element cts:near-query {
    $q/@*,
    search-lib:highlight-query-rewrite($q/node()) }
  case element(cts:not-query) return element cts:not-query {
      $q/@*,
      search-lib:highlight-query-rewrite($q/node()) }

  (: Pass through user-entered terms. Add more of these as needed. :)
  case element(cts:word-query) return $q
  (: Drop facet terms. Add more of these as needed. :)
  case element(cts:path-range-query) return ()
  case element(cts:element-range-query) return ()
  case element(cts:element-attribute-pair-geospatial-query) return ()
  case element(cts:element-attribute-range-query) return ()
  (: case element(cts:not-query) return () :)
  (: case element(cts:near-query) return () :)
  default return error((), 'SEARCHLIB-BADQUERY', cts:query($q))
};

declare function search-lib:highlight-query-set(
  $q as schema-element(cts:query))
as empty-sequence()
{
  xdmp:set(
    $HIGHLIGHT-QUERY,
    search-lib:highlight-query-rewrite($q))
};

(: Implement the search API snippet interface.
 : This implementation ignores the supplied query,
 : using $HIGHLIGHT-QUERY instead.
 : The caller is responsible for setting $HIGHLIGHT-QUERY
 : before calling this function.
 : If the caller fails to do this, no highlighting will take place.
 : This error cannot be detected because an empty query is legitimate,
 : for example when the user selects facets only and enters no terms.
 :)
declare function search-lib:snippet(
  $result as node(),
  $ctsquery as schema-element(cts:query),
  $options as element(search:transform-results)?)
as element(search:snippet)?
{
  search:snippet(
    $result,
    $HIGHLIGHT-QUERY,
    $options)
};

(: search-lib.xqy :)