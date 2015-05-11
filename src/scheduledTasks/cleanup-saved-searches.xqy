(:
This module should be called as a scheduled task to delete saved searches which are 30 days old
:)

declare function local:getStartDate() as xs:dateTime {
  let $now := current-dateTime()
  let $month :=  xs:dayTimeDuration("P30D")
  (: let $month :=  xs:dayTimeDuration("PT1M") :)
  let $month_ago := $now - $month
  return $month_ago
};

declare function local:deleteSavedSearches($startDate as xs:dateTime) {
  let $savedSearchesToCleanup := xdmp:directory("/users/", "infinity")/savedSearch[date < $startDate]
  return
    if (count($savedSearchesToCleanup) > 0) then
      xdmp:node-delete(xdmp:directory("/users/", "infinity")/savedSearch[date < $startDate])
    else
      xdmp:log("Completed saved search cleanup")
};

let $startDate := local:getStartDate()
let $_ := xdmp:log("Running saved search cleanup with a start time of: " || $startDate || " and an end time of: " || current-dateTime())
let $_ := local:deleteSavedSearches($startDate)
return ()