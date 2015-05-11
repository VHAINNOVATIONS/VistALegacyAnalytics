xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/analytics";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace va = "ns://va.gov/2012/ip401";

import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare namespace db = "http://marklogic.com/xdmp/database";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";


declare variable $sources := map:map(
  <map xmlns="http://marklogic.com/xdmp/map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <entry key="Diagnosis">
      <value xsi:type="xs:string">/va:vpr/va:meta/va:enrichment/enr:events/enr:eventDate/enr:diagnosis</value>
    </entry>
    <entry key="Drug">
      <value xsi:type="xs:string">/va:vpr/va:meta/va:enrichment/enr:events/enr:eventDate/enr:drug</value>
    </entry>
    <entry key="Toxin">
      <value xsi:type="xs:string">/va:vpr/va:meta/va:enrichment/enr:events/enr:eventDate/enr:toxin</value>
    </entry>
    <entry key="Disease">
      <value xsi:type="xs:string">/va:vpr/va:meta/va:enrichment/enr:events/enr:eventDate/enr:disease</value>
    </entry>
  </map>
);

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
  ch:set-value("sources", $sources),
  ch:use-view((), "xml"),
  ch:set-value('tab-active', 3),
  ch:use-layout("full-page", "html")
};


declare function c:run() as item()*
{
  let $y as xs:string := req:get("yvals", "", "type=xs:string")
  let $x as xs:string := req:get("xvals", "", "type=xs:string")

  (: let $_ := xdmp:log('$x: ' || $x || ', $y: ' || $y) :)

  let $xqref := cts:path-reference($x)
  let $yqref := cts:path-reference($y)
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
    let $count := cts:frequency($co)
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

(:
declare function c:run-ordering-report() as item()*
{
  let $x as xs:string := fn:substring-before(fn:tokenize(req:get("xvals", "", "type=xs:string"), "/")[fn:last() - 1], "[")
  let $y as xs:string := fn:substring-before(fn:tokenize(req:get("yvals", "", "type=xs:string"), "/")[fn:last() - 1], "[")

  let $xval := req:get("xvalue", "", "type=xs:string")
  let $yval := req:get("yvalue", "", "type=xs:string")

  let $xType := fn:substring-before(fn:substring-after(req:get("xvals", "", "type=xs:string"), '@type="'), '"]/@name')
  let $yType := fn:substring-before(fn:substring-after(req:get("yvals", "", "type=xs:string"), '@type="'), '"]/@name')

  (: let $_ := xdmp:log('$x: ' || $x || ', $y: ' || $y || ', $xval: ' || $xval || ', $yval: ' || $yval || ', $xType: ' || $xType || ', $yType:' || $yType) :)

  let $beforeQuery := cts:near-query(
    ( cts:and-query((
         cts:element-attribute-value-query(xs:QName($x), xs:QName("name"), $xval),
         cts:element-attribute-value-query(xs:QName($x), xs:QName("type"), $xType)
       )),
       cts:and-query((
         cts:element-attribute-value-query(xs:QName($y), xs:QName("name"), $yval),
         cts:element-attribute-value-query(xs:QName($y), xs:QName("type"), $yType)
       ))
    ),
    1000, 'ordered')
  let $afterQuery := cts:near-query(
    ( cts:and-query((
        cts:element-attribute-value-query(xs:QName($y), xs:QName("name"), $yval),
        cts:element-attribute-value-query(xs:QName($y), xs:QName("type"), $yType)
      )),
      cts:and-query((
        cts:element-attribute-value-query(xs:QName($x), xs:QName("name"), $xval),
        cts:element-attribute-value-query(xs:QName($x), xs:QName("type"), $xType)
      ))
    ),
    1000, 'ordered')
  let $sameDateQuery := cts:element-query(xs:QName("enr:eventDate"),
    cts:and-query((
      cts:and-query((
        cts:element-attribute-value-query(xs:QName($x), xs:QName("name"), $xval),
        cts:element-attribute-value-query(xs:QName($x), xs:QName("type"), $xType)
      )),
      cts:and-query((
        cts:element-attribute-value-query(xs:QName($y), xs:QName("name"), $yval),
        cts:element-attribute-value-query(xs:QName($y), xs:QName("type"), $yType)
      ))
    ))
  )
  let $sameDateCount := xdmp:estimate(cts:search(/va:vpr, $sameDateQuery))

  let $beforeCount := xdmp:estimate(cts:search(/va:vpr, $beforeQuery))
  let $adjustedBeforeCount := $beforeCount - $sameDateCount
  let $afterCount := xdmp:estimate(cts:search(/va:vpr, $afterQuery))
  let $adjustedAfterCount := $afterCount - $sameDateCount
  return
      '{"xbefore": ' || $adjustedBeforeCount ||
      ', "xafter": ' || $adjustedAfterCount ||
      ', "same": ' || $sameDateCount || '}'
};
:)

declare function c:run-ordering-report() as item()*
{
  let $xNodeName as xs:string := fn:substring-before(fn:tokenize(req:get("xvals", "", "type=xs:string"), "/")[fn:last() - 1], "[")
  let $yNodeName  as xs:string := fn:substring-before(fn:tokenize(req:get("yvals", "", "type=xs:string"), "/")[fn:last() - 1], "[")

  let $xName := req:get("xvalue", "", "type=xs:string")
  let $yName := req:get("yvalue", "", "type=xs:string")

  let $xType := fn:substring-before(fn:substring-after(req:get("xvals", "", "type=xs:string"), '@type="'), '"]/@name')
  let $yType := fn:substring-before(fn:substring-after(req:get("yvals", "", "type=xs:string"), '@type="'), '"]/@name')

  (:
  let $dec := "declare namespace va='ns://va.gov/2012/ip401'; declare namespace enr = 'ns://va.gov/2012/ip401/enrichment'; "
  let $events := xdmp:eval($dec || concat('/va:vpr/va:meta/va:enrichment/enr:events[enr:eventDate/',$xNodeName,'[@name = "',$xName,'" and @type = "',
    $xType,'"] and enr:eventDate/',$yNodeName,'[@name = "',$yName,'" and @type = "',$yType,'"]]'))
  :)
  let $events := /va:vpr/va:meta/va:enrichment/enr:events[enr:eventDate/*[node-name(.) = xs:QName($xNodeName) and @name = $xName and @type = $xType] and enr:eventDate/*[node-name(.) = xs:QName($yNodeName) and @name = $yName and @type = $yType]]
  let $occurances := (
    for $event in $events
      let $xEvents := $event/enr:eventDate/*[node-name(.) = xs:QName($xNodeName) and @name = $xName and @type = $xType]
      let $yEvents := $event/enr:eventDate/*[node-name(.) = xs:QName($yNodeName) and @name = $yName and @type = $yType]
      let $minXeventDate := min($xEvents/xs:date(@referenceDate))
      let $minYeventDate := min($yEvents/xs:date(@referenceDate))
      return
        if ( $minXeventDate lt $minYeventDate ) then "B"
        else if ( $minXeventDate gt $minYeventDate ) then "A"
        else "S"
  )
  let $x-before-y-count := count(index-of("B",$occurances))
  let $x-after-y-count := count(index-of("A",$occurances))
  let $x-and-y-same-count := count(index-of("S",$occurances))
    return
      '{"xbefore": ' || $x-before-y-count ||
      ', "xafter": ' || $x-after-y-count ||
      ', "same": ' || $x-and-y-same-count || '}'
};


declare function c:getHasNietherCount($firstDataSet, $firstDataSetType, $secondDataSet, $secondDataSetType)
{
  let $fpath := '/va:vpr/va:meta/va:enrichment' || $firstDataSet || '/@type'
  let $spath := '/va:vpr/va:meta/va:enrichment' || $secondDataSet || '/@type'
  let $q := cts:not-query(
    cts:or-query((
      cts:path-range-query($fpath, "=", $firstDataSetType),
      cts:path-range-query($spath, "=", $secondDataSetType)
    ))
  )
  return xdmp:estimate(cts:search(/va:vpr, $q))
};

declare function c:getHasBothCount($firstDataSet, $firstDataSetType, $secondDataSet, $secondDataSetType)
{
  let $fpath := '/va:vpr/va:meta/va:enrichment' || $firstDataSet || '/@type'
  let $spath := '/va:vpr/va:meta/va:enrichment' || $secondDataSet || '/@type'
  let $q := cts:and-query((
    cts:path-range-query($fpath, "=", $firstDataSetType),
    cts:path-range-query($spath, "=", $secondDataSetType)
  ))
  return xdmp:estimate(cts:search(/va:vpr, $q))
};

declare function c:getDataSetCount($dataSet, $dataSetType)
{
  let $path := '/va:vpr/va:meta/va:enrichment' || $dataSet || '/@type'
  let $q := cts:path-range-query($path, "=", $dataSetType)
  return xdmp:estimate(cts:search(/va:vpr, $q))
};

declare function c:runSummaryReport() as item()*
{
  let $y as xs:string := req:get("yval", "", "type=xs:string")
  let $x as xs:string := req:get("xval", "", "type=xs:string")
  let $yWhere as xs:string := req:get("yWhere", "", "type=xs:string")
  let $xWhere as xs:string := req:get("xWhere", "", "type=xs:string")
  let $totalRecords := xdmp:estimate(/va:vpr)
  let $neither := c:getHasNietherCount($x, $xWhere, $y, $yWhere)
  let $both := c:getHasBothCount($x, $xWhere, $y, $yWhere)
  let $firstSetCount := c:getDataSetCount($x, $xWhere)
  let $secondSetCount := c:getDataSetCount($y, $yWhere)
  let $json := concat('{ "totalRecords": "', $totalRecords  ,'",',
                        '"neither": "',$neither,'",',
                        '"both": "',$both,'",',
                        '"onlyFirst": "',$firstSetCount,'",',
                        '"onlySecond": "',$secondSetCount,'"}')
  return $json
};

(: controllers/analytics.xqy :)
