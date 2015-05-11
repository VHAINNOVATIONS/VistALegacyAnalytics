xquery version "1.0-ml";

declare namespace va = "ns://va.gov/2012/ip401";
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;

import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util"
  at "/lib/util.xqy";

declare variable $URI as xs:string external;

declare variable $IGNORE-LIST as xs:string* := (
  'Allergy',
  'BASIS',
  'Complete',
  'Control',
  'DATE',
  'ISOLATE',
  'PURPOSE',
  'Perform',
  'Prompt',
  'RID',
  'Supply',
  'SUPPLY',
  'Support',
  'UNIT',
  'Serum',
  'Blood',
  'Active',
  'COPD',
  'Acute Disease',
  'Level',
  ()
) ;

declare function local:clean(
  $n as node())
as node()?
{
  typeswitch ($n)
  (: Clean old rx:class elements too.
   : After 2013-06-24 or so, these should always be empty elements.
   : But the text step carries forward any legacy text, for migration.
   : These empty elements will return () hence node()? in the signature.
   :)
  case element(rx:class) return $n/text()
  case element(rx:concept) return $n/text()
  case element() return element { node-name($n) } {
    $n/@*,
    local:clean($n/node()) }
  default return $n
};

declare function local:dedup(
  $list as element(rx:concept)+)
{
  let $m := map:map()
  let $_ := $list ! (
    if (map:contains($m, @code)) then ()
    else map:put($m, @code, .))
  return map:get($m, map:keys($m))
};

declare function local:concept(
  $c as element(rx:concept))
as element(rx:concept)
{
  element rx:concept {
    on:enrichment-nodes(($c/@rxcui, $c/@str)),
    (: Decorate with DEA schedule, if available. :)
    $c/@dea-schedule,
    (: Decorate with VA drug classification, if available. :)
    $c/@vadc-code ! (
      .,
      attribute vadc-label { ., $c/@str }) }
};

declare function local:rxnorm(
  $results as element(va:results),
  $clean as element(va:results),
  $concepts as element(rx:concept)+)
as empty-sequence()
{
  let $concept-map := map:map()
  let $_ := $concepts ! map:put(
    $concept-map, on:query-key(cts:query(rx:query/*)), .)
  let $match-map := map:map()
  let $_ := cts:walk(
    $clean, cts:or-query(cts:query($concepts/rx:query/*)),
    (: Smooth out the mismatch between $results and $clean,
     : saving the result so we can find the right node again.
     :)
    (xdmp:path($results/.., true())
      ||xdmp:path($cts:node/..)) ! map:put(
     $match-map, .,
     (map:get($match-map, .),
      local:concept(map:get($concept-map, on:query-key($cts:queries))))))
  (: There may be duplicates in any match map entry. :)
  let $_ := xdmp:log(
    text {
      '[enrich-text]', xdmp:describe($results), 'matched',
      count($concepts), xdmp:describe(map:keys($match-map), 3, 128) },
    'debug')
  for $k in map:keys($match-map)
  let $old as element() := xdmp:unpath($k)
  let $new as element(rx:concept)+ := local:dedup(map:get($match-map, $k))
  return xdmp:node-insert-child($old, $new)
};

declare function local:rxnorm(
  $results as element(va:results))
as empty-sequence()
{
  (: Clean up any old enrichment, including legacy rx:class elements.
   : The rx:class code can go away once all databases are clean.
   :)
  xdmp:node-delete($results//rx:class),
  xdmp:node-delete($results//rx:concept),
  (: Add new enrichment. :)
  let $clean := local:clean($results)
  let $concepts as element(rx:concept)* := cts:search(
    collection(),
      cts:and-not-query(
        cts:and-query((on:query-rx(), cts:reverse-query($clean))),
        cts:word-query($IGNORE-LIST)))/*
  let $_ := xdmp:log(
    text {
      '[enrich-text]', xdmp:describe($results), 'matched',
      count($concepts), xdmp:describe($concepts/@str/string()) },
    'debug')
  where $concepts
  return local:rxnorm($results, $clean, $concepts)
};

let $vpr as element() := doc($URI)/va:vpr
let $results as element() := $vpr/va:results
let $_ := local:rxnorm($results)
let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:textEnrichment'))

return $URI

(: enrich-text.xqy :)