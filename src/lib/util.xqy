xquery version "1.0-ml";
module namespace util = "ns://va.gov/2012/ip401/util";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
declare namespace none = "";
declare namespace va = "ns://va.gov/2012/ip401";

declare default element namespace "http://www.w3.org/1999/xhtml";

(: Convert from a vpr date to a real date/dateTime :)
declare function util:convert-vpr-date($dateval as xs:string)
{
  if ($dateval != '') then
    let $year := fn:string(xs:int(fn:substring($dateval, 1, 3)) + 1700)
    let $month := fn:substring($dateval, 4, 2)
    let $day := fn:substring($dateval, 6, 2)
    let $time := fn:substring($dateval, 8)
    return try {
      if ($time) then
        let $seconds := xs:int(xs:double($time) * 86400)
        return xs:dateTime(fn:concat($year, "-", $month, "-", $day, "T00:00:00")) + xs:dayTimeDuration(fn:concat("PT", $seconds, "S"))
      else
        xs:dateTime(fn:concat($year, "-", $month, "-", $day, "T00:00:00"))
      } catch ($e) {
        ()
      }
  else
    ()
};

declare function util:convert-to-vpr-date($dt as xs:dateTime) {
  let $int-part := ((fn:year-from-dateTime($dt) - 1700) * 10000) + (fn:month-from-dateTime($dt) * 100) + fn:day-from-dateTime($dt)
  let $dec-part := math:trunc(((fn:hours-from-dateTime($dt) * 3600) + (fn:minutes-from-dateTime($dt) * 60) + fn:seconds-from-dateTime($dt)) div 86400, 4)
  return $int-part + $dec-part
};

declare function util:count-events($query, $start-date, $end-date, $granularity, $date-path) {
  let $duration := $end-date - $start-date
  let $days := xs:int(functx:total-days-from-duration($duration))
  let $granularity := if ($days le 360) then
      "day"
    else if ($days gt 360 and $days le 3650) then
      "month"
    else
      "year"
  return
    if ($granularity = 'day') then
      for $day in (1 to $days)
      let $counts := map:map()
      let $curr-start := $start-date + xs:dayTimeDuration(fn:concat('P', $day - 1, 'D'))
      let $curr-end := $start-date + xs:dayTimeDuration(fn:concat('P', $day, 'D'))
      let $q := cts:and-query((
        cts:path-range-query($date-path, ">", util:convert-to-vpr-date($curr-start)),
        cts:path-range-query($date-path, "<=", util:convert-to-vpr-date($curr-end)),
        $query
      ))
      let $_ := map:put($counts, "x", $curr-start)
      let $_ := map:put($counts, "y", xdmp:estimate(cts:search(fn:doc(), $q)))
      return $counts
    else if ($granularity = 'month') then
      let $start-date := xs:dateTime(functx:first-day-of-month($start-date))
      let $end-date := xs:dateTime(functx:last-day-of-month($end-date))
      for $month in (1 to xs:int($days div 28))
      let $counts := map:map()
      let $curr-start := xs:dateTime(functx:first-day-of-month($start-date + xs:yearMonthDuration(fn:concat('P', $month - 1, 'M'))))
      let $curr-end := xs:dateTime(functx:first-day-of-month($start-date + xs:yearMonthDuration(fn:concat('P', $month, 'M'))))
      let $q := cts:and-query((
        cts:path-range-query($date-path, ">", util:convert-to-vpr-date($curr-start)),
        cts:path-range-query($date-path, "<=", util:convert-to-vpr-date($curr-end)),
        $query
      ))
      let $_ := map:put($counts, "x", $curr-start)
      let $_ := map:put($counts, "y", xdmp:estimate(cts:search(fn:doc(), $q)))
      return $counts
    else
      let $start-date := xs:dateTime(functx:first-day-of-month($start-date))
      let $end-date := xs:dateTime(functx:last-day-of-month($end-date))
      for $year in (1 to xs:int($days div 365))
      let $counts := map:map()
      let $curr-start := xs:dateTime(functx:first-day-of-month($start-date + xs:yearMonthDuration(fn:concat('P', $year - 1, 'Y'))))
      let $curr-end := xs:dateTime(functx:first-day-of-month($start-date + xs:yearMonthDuration(fn:concat('P', $year, 'Y'))))
      let $q := cts:and-query((
        cts:path-range-query($date-path, ">", util:convert-to-vpr-date($curr-start)),
        cts:path-range-query($date-path, "<=", util:convert-to-vpr-date($curr-end)),
        $query
      ))
      let $_ := map:put($counts, "x", $curr-start)
      let $_ := map:put($counts, "y", xdmp:estimate(cts:search(fn:doc(), $q)))
      return $counts
};

declare function util:millisecond-date($dateval as xs:string) {
  let $date := util:convert-vpr-date($dateval)
  return ($date - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration('PT0.001S')
};


declare function util:get-approx-age-at-date($date as xs:dateTime, $dob as xs:dateTime )
{
  let $duration :=  $date - $dob
  let $days := fn:days-from-duration($duration)
  return xs:integer($days div 365)
};

declare function util:exec-template($root, $template as node()) {
  text {
  typeswitch ($template)
    case element() return
      if (fn:local-name($template) = "template") then
        for $node in $template/node() return util:exec-template($root, $node)
      else if (fn:local-name($template) = "value") then
        let $path := fn:string($template/@path)
        let $type := $template/@type
        return fn:string(xdmp:unpath(fn:concat(xdmp:path($root, fn:true()), $path)))
      else $template
    default return $template
  }
};

(:
declare function util:create-data-table($name as xs:string, $nodes as node()*, $fields as node())
{declare function ev:get-approx-age-at-date($date as xs:dateTime, $dob as xs:dateTime )
{
  let $duration :=  $date - $dob
  let $days := fn:days-from-duration($duration)
  return xs:integer($days div 365)
};
  let $field-nodes := $fields/*:field
  return
    <table class="data_table">
      <thead><tr>{($field-nodes) ! (<th data-type="{./*:type}">{./*:name}</th>)}</tr></thead>
      <tbody>
      {
        for $node in $nodes
        return
          <tr data-category="{$name}">
          {
            for $field in $field-nodes
            let $path := fn:concat(xdmp:path($node, fn:true()), $field/*:path)
            let $vals := xdmp:unpath($path)
            let $date := if ($field/*:type = "date") then util:millisecond-date($vals) else ()
            return
              <td class="tablecell-{$field/*:type}">
                <span data-date="{$date}">
                {
                  let $join := (fn:string($field/*:join), " ")[1]
                  let $return :=
                    for $val in $vals
                    return
                      if (($field/*:type = "date") and ($val != 0)) then
                        fn:format-dateTime(util:convert-vpr-date($val), "[MNn] [D], [Y] [h]:[m01] [PN]", "en", (), ())
                      else if ($field/*:type = "date") then ""
                      else if ($field/*:type = "text") then
                        <a href="/appbuilder/raw.text?path={xdmp:path($val, fn:true())}" class="content_link">Content</a>
                      else if ($field/*:type = "template") then
                        let $template := $fields/*:template[@for = fn:string($field/*:name)]
                        return util:exec-template($val, $template)
                      else
                        fn:string($val)
                  return if ($join) then
                    xdmp:unquote(fn:concat('<x>', fn:string-join($return, $join), '</x>'))/*:x
                    else $return
                }
                </span>
              </td>
          }
          </tr>
      }
      </tbody>
    </table>
}; :)

declare function util:create-data-table($fields as node())
{
  let $field-nodes := $fields/*:field
  return
    <table class="data_table">
      <thead><tr>{($field-nodes) ! (<th data-type="{./*:type}">{./*:name}</th>)}</tr></thead>
      <tbody>
      {
        <tr><td colspan="{fn:count($field-nodes)}" class="dataTables_empty">Loading data from server</td></tr>
      }
      </tbody>
    </table>
};

declare function util:build-timeline-table($root) {
  xdmp:xslt-invoke("resources/timeline.xslt", $root)
};

declare function util:render-xml($node as node()) {
  xdmp:xslt-invoke("resources/xml-render.xslt", $node)
};

declare function util:add-enrichment-indicator(
  $vpr as element(va:vpr),
  $qname as xs:QName)
as empty-sequence()
{
  let $meta := $vpr/va:meta
  let $enrichment := $meta/va:enrichment
  let $indicator-new := element { $qname } { fn:current-date() }
  let $indicator-old := $enrichment/*[ fn:node-name(.) eq $qname ]
  return
    if ($enrichment) then
        if ($indicator-old) then
            xdmp:node-replace($indicator-old, $indicator-new)
         else
            xdmp:node-insert-child($enrichment, $indicator-new )
    else xdmp:node-insert-child(
      $meta, element va:enrichment { $indicator-new } )
};

declare function util:non-enriched-uris($qname as xs:QName)
as xs:anyAtomicType+
{
  let $q := cts:and-not-query(
    cts:directory-query("/vpr/", "infinity"),
    cts:element-query($qname, cts:and-query(())))
  let $uris := cts:uris((), (), $q)
  return (fn:count($uris), $uris)
};