xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util"
  at "/lib/util.xqy";

declare variable $URI as xs:string external;

declare function local:clean(
  $n as node())
as node()?
{
  typeswitch ($n)
  case element(on:concept) return $n/text()
  case element() return element { node-name($n) } {
    $n/@*,
    local:clean($n/node()) }
  default return $n
};

declare function local:dedup(
  $list as element(on:concept)+)
{
  let $m := map:map()
  let $_ := $list ! (
    if (map:contains($m, @code)) then ()
    else map:put($m, @code, .))
  return map:get($m, map:keys($m))
};

declare function local:concept(
  $c as element(on:concept))
as element(on:concept)
{
  element on:concept {
    on:enrichment-nodes(($c/@code, $c/@short-description)) }
};

declare function local:enrich(
  $results as element(va:results),
  $clean as element(va:results),
  $concepts as element(on:concept)+)
as empty-sequence()
{
  let $concept-map := map:map()
  let $_ := $concepts ! map:put(
    $concept-map, on:query-key(cts:query(on:query/*)), .)
  let $match-map := map:map()
  let $_ := cts:walk(
    $clean, cts:or-query(cts:query($concepts/on:query/*)),
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
      '[enrich-concepts-text]', xdmp:describe($results), 'matched',
      count($concepts), xdmp:describe(map:keys($match-map), 3, 128) },
    'debug')
  for $k in map:keys($match-map)
  let $old as element() := xdmp:unpath($k)
  let $new as element(on:concept)+ := local:dedup(map:get($match-map, $k))
  return xdmp:node-insert-child($old, $new)
};

declare function local:enrich(
  $results as element(va:results))
as empty-sequence()
{
  (: Clean up any old enrichment. :)
  xdmp:node-delete($results//on:concept),
  (: Add new enrichment. :)
  let $clean := local:clean($results)
  let $concepts as element(on:concept)* := cts:search(
    collection(),
    cts:and-query((on:query-icd9(), cts:reverse-query($clean))))/*
  let $_ := xdmp:log(
    text {
      '[enrich-concepts-text]', xdmp:describe($results), 'matched',
      count($concepts), xdmp:describe($concepts/@short-description/string()) },
    'debug')
  where $concepts
  return local:enrich($results, $clean, $concepts)
};

let $vpr as element() := doc($URI)/va:vpr
let $results as element() := $vpr/va:results
let $_ := local:enrich($results)
let $_ := util:add-enrichment-indicator(
  $vpr, xs:QName('va:textConceptEnrichment'))
return $URI

(: enrich-concepts-text.xqy :)