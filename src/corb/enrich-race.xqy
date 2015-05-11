(:
 :  Add ageAtDiagnosis child element to every visit and problem node, as well as content nodes containing the "concept" (= diagnosis) element.
 :  Run against documents that have already been given the "va" namespace, either in the database or as part of ingest.
 :  Reentrant -- drops old ageAtDiagnosis nodes and then reinserts them using current document reference nodes.
 :)

xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare variable $URI as xs:string external;

declare function local:enrich-patient($results, $races)
{
    let $patient := $results/va:demographics/va:patient[1]
    let $_ := xdmp:node-delete($patient/va:primaryRace)
    let $race := $patient/va:races/va:race[1]
    let $raceDesc := map:get($races, $race)
    return
      if ($raceDesc) then
          xdmp:node-insert-child($patient, element va:primaryRace { $raceDesc })
      else
        let $raceDesc := map:get($races, data($race/@abbrev) )
        return
          if ($raceDesc) then
              xdmp:node-insert-child($patient, element va:primaryRace { $raceDesc })
          else
              xdmp:node-insert-child($patient, element va:primaryRace { "Unknown" })
};

declare function local:add-marker($results)
{
  let $meta := $results/../va:meta
    let $marker := element va:primaryRaceEnrichment {fn:current-date() }
    return
      if ($meta/va:enrichment) then
          if ($meta/va:enrichment/va:primaryRaceEnrichment) then
              xdmp:node-replace($meta/va:enrichment/va:primaryRaceEnrichment, $marker)
          else
              xdmp:node-insert-child($meta/va:enrichment, $marker )
      else xdmp:node-insert-child($meta, element va:enrichment{ $marker } )
};

let $races := map:map()
let $_ :=
(
    map:put($races, "1002-5", "American Indian or Alaska Native"),
    map:put($races, "3",      "American Indian or Alaska Native"),
    map:put($races, "2028-9", "Asian"),
    map:put($races, "A",      "Asian"),
    map:put($races, "5",      "Asian"),
    map:put($races, "2054-5", "Black or African-American"),
    map:put($races, "B",      "Black or African-American"),
    map:put($races, "4",      "Black or African-American"),
    map:put($races, "2076-8", "Native Hawaiian or Other Pacific Islander"),
    map:put($races, "H",      "Native Hawaiian or Other Pacific Islander"),
    map:put($races, "2106-3", "White"),
    map:put($races, "W",      "White"),
    map:put($races, "6",      "White"),
    map:put($races, "2131-1", "Other Race"),
    map:put($races, "2135-2", "Hispanic or Latino"),
    map:put($races, "1",      "Hispanic or Latino"),
    map:put($races, "2",      "Hispanic or Latino"),
    map:put($races, "D",      "Declined to answer"),
    map:put($races, "7",      "Unknown"),
    map:put($races, "U",      "Unknown")
)

let $results := doc($URI)/va:vpr/va:results
let $_ := local:enrich-patient($results, $races)
let $_ := local:add-marker($results)

return $URI
