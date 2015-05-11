(: Shared step called by CORB once before it runs any transformation steps :)

xquery version "1.0-ml";
let $uris := cts:uris("/vpr/")
return (fn:count($uris), $uris)