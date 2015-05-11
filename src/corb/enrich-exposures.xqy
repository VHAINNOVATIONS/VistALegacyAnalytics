xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace enrich = "ns://va.gov/2012/ip401/enrich-util" at "/lib/enrich.xqy";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
declare variable $URI as xs:string external;


declare function local:format-date($date as xs:string, $option)
{
  if ($option = 1) then
    (: may 24, 1999 :)
      
    let $dates :=
    <dates>
      <d m="jan">01</d><d m="feb">02</d><d m="mar">03</d>
      <d m="apr">04</d><d m="may">05</d><d m="jun">06</d>
      <d m="jul">07</d><d m="aug">08</d><d m="sep">09</d>
      <d m="oct">10</d><d m="nov">11</d><d m="dec">12</d>
    </dates>
     
    let $mon := substring($date, 1, 3)
    let $fixed := replace($date, $mon, $dates/d[@m=$mon])  (: 05, 24, 1999 :)
    let $result := substring($fixed, 8, 4) || "-" || substring($fixed, 1,2)   || "-" || substring($fixed, 4,2) 
    return $result
   else if ($option = 2) then
     substring(string(util:convert-vpr-date($date)), 1, 10)
   else 
     'unsupported'
};

declare function local:get-comment-date($comment as element(va:comment))
{
  if ($comment/@entered) then local:format-date($comment/@entered, 2)
  else if ($comment/../va:collected) then local:format-date($comment/../va:collected, 2)
  else ()
};

declare function local:get-content-date($text as xs:string) 
{
  (: DICT DATE: DEC 03, 1996           ENTRY DATE: DEC 05, 1996 :)
        
  let $dateReportedMatch := string-join(functx:get-matches($text, "(date reported): (\w{3} \d{1,2}, \d{2,4})"), "")  (: 16 date reported: aug 01, 1993 :)
  let $dictDateMatch := string-join(functx:get-matches($text, "(dict date): (\w{3} \d{1,2}, \d{2,4})"), "")
  let $entryDateMatch := string-join(functx:get-matches($text, "(entry date): (\w{3} \d{1,2}, \d{2,4})"), "")
  let $date := if ($dateReportedMatch) then substring($dateReportedMatch, 16, string-length($dateReportedMatch)-16+1)
               else if ($dictDateMatch) then substring($dictDateMatch, 12, string-length($dictDateMatch)-12+1)
               else if ($entryDateMatch) then substring($entryDateMatch, 13, string-length($entryDateMatch)-13+1)
               else ()
   
  return 
    if ($date) then local:format-date($date, 1) else ()
    
};

declare function local:get-value($item)
{
  lower-case(normalize-space($item/string()))
};


declare function local:create-element($qname as xs:string, $type as xs:string, $date as xs:string?, $name as xs:string, 
  $source as xs:string, $singleton as xs:boolean?)
{
   let $rd := if ($date) then attribute referenceDate{$date} else ()
   let $s := if ($singleton) then attribute singleton{"Y"} else ()
   return element {xs:QName($qname)} { 
       attribute type {$type}, $rd, attribute name {$name}, attribute source{$source}, $s, $name
       }
};


declare function local:get-toxins($text as xs:string?, $date as xs:string?, $source as xs:string, $singleton as xs:boolean?)
{  
     
    let $ao := if (functx:get-matches($text, "agent orange|herbicide orange|2,4,5-t|2,4,5-d|agent lnx|ao")) then
                              local:create-element("enr:toxin", "All toxins", $date, "Agent Orange", $source, $singleton) else ()

    let $asb := if (functx:get-matches($text, "asbestos|mesothelioma")) then
                              local:create-element("enr:toxin", "All toxins", $date, "Asbestos", $source, $singleton) else ()
                              
    return ($ao, $asb)
};

declare function local:get-diagnoses($text as xs:string?, $date as xs:string?, $source as xs:string, $singleton as xs:boolean?)
{  
    let $a := if (functx:get-matches($text, "depress|suicid|kill.* himself")) then
                  local:create-element("enr:diagnosis", "depression", $date, "All forms", $source, $singleton) else ()
    
    let $b := if (functx:get-matches($text, "stroke|tia|ischemic attack|cerebrovascular|cva|vertigo|embolism")) then
                  local:create-element("enr:diagnosis", "cvd", $date, "All forms", $source, $singleton) else ()
    
    return ($a, $b)
};


declare function local:get-infectious-diseases($text as xs:string?, $date as xs:string?, $source as xs:string, $singleton as xs:boolean?)
{  
                                                          
    let $a := if (functx:get-matches($text, "hep a|hep-a|hepatitis a|hepatitis-a")) then
                              local:create-element("enr:disease", "infectious", $date, "hepatitis a", $source, $singleton) else ()
           
    let $b := if (functx:get-matches($text, "hep b|hep-b|hepatitis b|hepatitis-b")) then 
                              local:create-element("enr:disease", "infectious", $date, "hepatitis b", $source, $singleton) else ()

    let $c := if (functx:get-matches($text, "hep c|hep-c|hepatitis c|hepatitis-c")) then 
                              local:create-element("enr:disease", "infectious", $date, "hepatitis c", $source, $singleton) else ()
      
    return ($a, $b, $c)
};


(:let $URI := "/vpr/per/16482" :)
(:let $URI := "/vpr/fth/22909" :) (: has lab comment :)
(:let $URI := "/vpr/fth/22900" :) (: has AO exposure :)
(:let $URI := "/vpr/tus/57494" :) (: hep c :)
(:let $URI := "/vpr/tus/66981":)
let $vpr := doc($URI)/va:vpr


let $a := for $item in $vpr/va:results//va:content
          let $value := local:get-value($item)
          let $date := local:get-content-date($value)
          let $t := local:get-toxins($value, $date, "unstructured", false())
          let $i := local:get-infectious-diseases($value, $date, "unstructured", false())
          let $d := local:get-diagnoses($value, $date, "unstructured", false())
          return ($t, $d, $i)

let $b := for $item in $vpr/va:results//va:comment
          let $value :=  local:get-value($item) 
          let $date := local:get-comment-date($item) 
          let $t := local:get-toxins($value, $date, "unstructured", false())
          let $i := local:get-infectious-diseases($value, $date, "unstructured", false())
          let $d := local:get-diagnoses($value, $date, "unstructured", false())
          return ($t, $d, $i)
          
let $c := for $item in $vpr/va:results//va:exposure
          let $value := local:get-value($item)
          let $t := local:get-toxins($value, (), "structured", true())
          return ($t)


let $_ := enrich:add-replace-events($vpr, ($a, $b, $c))

let $_ := util:add-enrichment-indicator($vpr, xs:QName("enr:exposureEnrichment"))

return $URI




           
