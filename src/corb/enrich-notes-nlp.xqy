xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
declare variable $MAX_ATTEMPTS := 2;
declare variable $URI as xs:string external;

declare function local:getLoincComponent($note, $start, $length)
{
  let $raw := functx:trim(substring($note, $start, $length))
  return 
    if ( ends-with($raw, ":") ) 
	then substring($raw, 1, string-length($raw)-1) 
	else $raw
};

declare function local:processLoincFacets($response, $contentNode)
{
  
  let $existingMatchTags := $contentNode/enr:loinc  
  let $loincFacets := $response/Document/Metadata/Facets/Facet[(Path="dictloincdocumentcode" or Path="dictloincdocumenttype")]
    
  for $lf in $loincFacets
  let $code := $lf/Keyword/string()
  let $start := $lf/@Begin
  let $length := $lf/@End - $start + 1
  let $note := normalize-space($contentNode/string())
  let $component :=  functx:capitalize-first( fn:lower-case( local:getLoincComponent($note, $start, $length) ) )
	
  let $new := element enr:loinc { 
      attribute code { $code }, 
      attribute component { $component }, 
      attribute label {$code || " " || $component }}
  
  let $_ := xdmp:log($new, "debug")
  let $_ := if (functx:is-node-in-sequence-deep-equal($new, $existingMatchTags)) then true() else xdmp:node-insert-child($contentNode, $new)
  
  return ()
};

declare function local:processFields($response, $contentNode, $fieldName, $matchTagName as xs:QName)
{
  
  let $existingMatchTags := $contentNode/*[fn:node-name(.) eq $matchTagName]  (: e.g., <enr:suicideIndicator>depression</enr:suicideIndicator> :)
  let $fields := $response/Document/Metadata/Fields/Field[@Name=$fieldName]   (: e.g., <Field @Name="suicide_indicator">depression</Field> :)

  for $field in $fields
  let $value := $field/string()
  let $new := element { $matchTagName } { $value }
  let $found := if (functx:is-node-in-sequence-deep-equal($new, $existingMatchTags)) then true() else xdmp:node-insert-child($contentNode, $new)
  
  return $contentNode
};

declare function local:incrementAttemptsCount($vpr)
{
  let $attemptsNode := $vpr/va:meta/va:enrichment/enr:nlpAttempts
  return 
    if ($attemptsNode/text() >= 1)
       then xdmp:node-replace($attemptsNode, element enr:nlpAttempts { $attemptsNode/text() + 1})
       else xdmp:node-insert-child($vpr/va:meta/va:enrichment, element enr:nlpAttempts {1})
};


(:let $URI := "/tmp/1.xml":)
let $vpr := doc($URI)/va:vpr
let $attemptsNode := $vpr/va:meta/va:enrichment/enr:nlpAttempts
return
  if ($attemptsNode/text() >= $MAX_ATTEMPTS)
    then $URI (: exit :)
  else 
    let $_ := local:incrementAttemptsCount($vpr)
  
    let $_ := 
      
        try
        {
          for $contentNode in $vpr/va:results//(va:content|va:comment)
            let $note := fn:normalize-space($contentNode/string())
            let $url := fn:concat("http://10.71.38.172:8393/api/v10/analysis/text?collection=fth_test&amp;text=",
                fn:encode-for-uri($note))
          
            (:let $_ := xdmp:log("NLP service call start", "debug"):)
            let $response := xdmp:http-get($url, <options xmlns="xdmp:http"><timeout>480</timeout></options>)
            (:let $_ := xdmp:log("NLP service call end", "debug"):)
        
            let $_ := local:processLoincFacets($response, $contentNode)
            
            let $_ := local:processFields($response, $contentNode, "suicide_indicator", xs:QName("enr:suicideIndicator"))
            let $_ := local:processFields($response, $contentNode, "suicide_illicit_substance", xs:QName("enr:suicideIllicitDrug"))
            let $_ := local:processFields($response, $contentNode, "suicide_medication", xs:QName("enr:suicideMedication"))
            let $_ := local:processFields($response, $contentNode, "normalized_problem", xs:QName("enr:normalizedProblem"))
            let $_ := local:processFields($response, $contentNode, "drinkingpositiveind", xs:QName("enr:drinkingIndicator"))
          
           return ()
        } 
        catch($exception)
        {
            (:xdmp:log("Error calling NLP service.  Continuing \n" || $exception, "error"):)
	    xdmp:log($exception, "error"), 
	    xdmp:sleep(5000)
        }
          
      
    let $_ := util:add-enrichment-indicator($vpr, xs:QName("va:nlpEnrichment"))
    return $URI
