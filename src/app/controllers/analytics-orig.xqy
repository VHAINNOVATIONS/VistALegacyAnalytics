xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/analytics";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace va = "ns://va.gov/2012/ip401";

import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare namespace db = "http://marklogic.com/xdmp/database";

declare variable $range-indexes as map:map :=
  let $config := admin:get-configuration()
  let $range-indexes := map:map()
  (: Get the full list of element range indexes :)
  let $_ :=
    for $index in admin:database-get-range-element-indexes($config, xdmp:database())
    let $names := $index//*:localname/string()
    for $name in fn:tokenize($names, " ")
    let $index := functx:change-element-ns-deep($index, "http://marklogic.com/xdmp/database", "db")
    let $index := c:replace-element-value($index, "localname", $name)
    return map:put($range-indexes, $name, $index)
  (: Get the full list of attribute range indexes :)
  let $_ :=
    for $index in admin:database-get-range-element-attribute-indexes($config, xdmp:database())
    let $parent-localnames := fn:tokenize($index//*:parent-localname/string(), " ")
    let $localnames := fn:tokenize($index//*:localname/string(), " ")
    for $pl in $parent-localnames
    for $l in $localnames
    let $index := functx:change-element-ns-deep($index, "http://marklogic.com/xdmp/database", "db")
    let $index := c:replace-element-value($index, "localname", $l)
    let $index := c:replace-element-value($index, "parent-localname", $pl)
    return map:put($range-indexes, fn:concat($pl, "-", $l), $index)
  (: Get the full list of path range indexes :)
  let $_ :=
    for $index in admin:database-get-range-path-indexes($config, xdmp:database())
    let $index := functx:change-element-ns-deep($index, "http://marklogic.com/xdmp/database", "db")
    let $name := fn:tokenize($index//*:path-expression/string(), "/")[last()]
    return map:put($range-indexes, $name, $index)
  return $range-indexes
;

declare function c:replace-element-value($n as node(), $element-name, $name) as node() {
  typeswitch($n)
    case $e as element()
      return
        if (local-name($e) = $element-name) then
          functx:replace-element-values($e, $name)
        else
          element {name($e)}
        {$e/@*,
          for $c in $e/(* | text())
          return c:replace-element-value($c, $element-name, $name) }
    default return $n
 };

declare function c:build-query-reference($index) {
  typeswitch($index)
    case element(db:range-element-attribute-index) return
      let $pnamespace := $index//*:parent-namespace-uri/string()
      let $namespace := $index//*:namespace-uri/string()
      let $pname := $index//*:parent-localname/string()
      let $name := $index//*:localname/string()
      return cts:element-attribute-reference(fn:QName($pnamespace, $pname), fn:QName($namespace, $name))
    case element(db:range-element-index) return
      let $namespace := $index//*:namespace-uri/string()
      let $name := $index//*:localname/string()
      return cts:element-reference(fn:QName($namespace, $name))
    case element(db:range-path-index) return
      let $path := $index//*:path-expression/string()
      return cts:path-reference($path, (fn:concat("type=", $index//*:scalar-type)))
    default return ()
};

declare function c:query($ref, $val) {
  if (fn:exists($ref//cts:parent-localname)) then
    cts:element-attribute-value-query(
      fn:QName($ref//cts:parent-namespace-uri/string(), $ref//cts:parent-localname),
      fn:QName($ref//cts:namespace-uri/string(), $ref//cts:localname),
      $val
    )
  else if (fn:exists($ref//cts:path-expression)) then
    let $type := $ref//cts:scalar-type
    let $val := if ($type = "int") then xs:int($val) else $val
    return cts:path-range-query($ref//cts:path-expression/string(), "=", $val)
  else
    cts:element-value-query(fn:QName($ref//cts:namespace-uri/string(), $ref//cts:localname), $val)
};

declare function c:main() as item()*
{
  ch:add-value("title", "VistA Analytics"),
  ch:set-value("range-indexes", $range-indexes),
  ch:use-view((), "xml"),
  ch:use-layout("three-column", "html")
};

declare function c:run() as item()*
{
  let $y as xs:string := req:get("yvals", "", "type=xs:string")
  let $x as xs:string := req:get("xvals", "", "type=xs:string")
  let $xqref := c:build-query-reference(map:get($range-indexes, $x))
  let $yqref := c:build-query-reference(map:get($range-indexes, $y))
  let $cos := cts:value-co-occurrences($xqref, $yqref)
  let $co-occurrences := map:map()
  let $build-map :=
    for $co in $cos
    let $vals := $co/cts:value/string()
    let $xval := $vals[1]
    let $yval := $vals[2]
    let $q := cts:and-query((
      c:query((<x>{$xqref}</x>)/node(), $xval),
      c:query((<y>{$yqref}</y>)/node(), $yval)
    ))
    let $count := xdmp:estimate(cts:search(doc(), $q))
    let $curmap := map:get($co-occurrences, $xval)
    return
      if (fn:exists($curmap)) then
        map:put($curmap, $yval, $count)
      else
        let $newmap := map:map()
        let $_ := map:put($newmap, $yval, $count)
        return map:put($co-occurrences, $xval, $newmap)
  return (
    ch:set-value('co-occurrences', $co-occurrences)
  )
};

(: controllers/analytics.xqy :)
