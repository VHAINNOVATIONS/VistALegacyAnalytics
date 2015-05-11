xquery version "1.0-ml";

module namespace enrich = "ns://va.gov/2012/ip401/enrich-util";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";


declare function enrich:add-replace-events($vpr, $data )
{
  if (fn:not($data)) then "no data. returning"
  else
    let $meta := $vpr/va:meta
    let $enrichment := $meta/va:enrichment
    let $events := $enrichment/enr:events
    let $eventDates := $events/enr:eventDate
    let $currentItems := $eventDates/*
    let $eventsExists := exists($events)
    let $map := map:map()

    let $_ := for $new in ($data, $currentItems)   (: diagnosis, drug; toxin -- no date :)
              let $date := $new/@referenceDate
              let $_ := if ($date) then
                          let $curr := map:get($map, $date)
                          let $_:= if (fn:not($curr)) then map:put($map, $date, $new)
                                   else if (fn:not($new/@singleton)) then map:put($map, $date, ($curr, $new))
                                   else if (fn:not( functx:is-node-in-sequence-deep-equal($new, $curr))) then map:put($map, $date, ($curr, $new))
                                   else ()
                          return ()
                        else
                          let $curr := map:get($map, "undated")
                          let $_:= if (fn:not($curr)) then map:put($map, "undated", $new)
                                   else if (fn:not($new/@singleton)) then map:put($map, "undated", ($curr, $new))
                                   else if (fn:not( functx:is-node-in-sequence-deep-equal($new, $curr))) then map:put($map, "undated", ($curr, $new))
                                   else ()
                          return ()
              return()

    let $sorted-eventDates := for $key in map:keys($map)
                              let $rdAttr := if ($key ne "undated") then attribute referenceDate{$key} else ()
                              order by $key
                              return element enr:eventDate{ $rdAttr, map:get($map, $key) }

    return
      if (fn:not($enrichment)) then
        ( xdmp:node-insert-child($meta, element va:enrichment{ element enr:events { $sorted-eventDates } }), "added enrichment on down")
      else if (fn:not($events)) then
        (xdmp:node-insert-child($enrichment, element enr:events { $sorted-eventDates } ), "added events on down")
      else
        (xdmp:node-replace($events, element enr:events { $sorted-eventDates } ), "replaced events")

};
