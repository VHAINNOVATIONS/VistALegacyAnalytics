xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
declare variable $MAX_ATTEMPTS := 2;

declare variable $URI as xs:string external;

declare function local:getDate($text as xs:string)
{
  (: DICT DATE: DEC 03, 1996           ENTRY DATE: DEC 05, 1996 :)
  
  let $dateReportedMatch := functx:get-matches($text, "(Date Reported|DATE REPORTED): (\w{3} \d{1,2}, \d{2,4})")[2]  (: 16 date reported: aug 01, 1993 :)
  let $dictDateMatch := functx:get-matches($text, "(DICT DATE|Dict Date): (\w{3} \d{1,2}, \d{2,4})")[2]
  let $entryDateMatch := functx:get-matches($text, "(ENTRY DATE|Entry Date): (\w{3} \d{1,2}, \d{2,4})")[2]
  return 
    if ($dateReportedMatch) then substring($dateReportedMatch, 16, string-length($dateReportedMatch)-16+1)
    else if ($dictDateMatch) then substring($dictDateMatch, 12, string-length($dictDateMatch)-12+1)
    else if ($entryDateMatch) then substring($entryDateMatch, 13, string-length($entryDateMatch)-13+1)
    else ()
};

declare function local:createDateTime($date as xs:string)
{
  let $dates := 
  <dates>
    <d m="JAN">01</d><d m="FEB">02</d><d m="MAR">03</d>
    <d m="APR">04</d><d m="MAY">05</d><d m="JUN">06</d>
    <d m="JUL">07</d><d m="AUG">08</d><d m="SEP">09</d>
    <d m="OCT">10</d><d m="NOV">11</d><d m="DEC">12</d>
  </dates>
  
  let $picture := "[M01] [D01], [Y0001]"
  let $mon := substring($date, 1, 3)
  let $fixed := replace($date, $mon, $dates/d[@m=$mon]) 
  
  let $dt := xdmp:parse-dateTime($picture, $fixed)
  return string($dt)
};

declare function local:parseNotes($notes)
{
  let $firstCvdNote as element(firstCvdNote)? := ()
  let $lastDepressionNote as element(lastDepressionNote)? := ()
  let $cvdNoteCount := 0
  let $depressionNoteCount := 0
  let $notesCount := 0
  let $_ :=  
    for $note in $notes
    let $note := fn:normalize-space($note/string())
    let $textDate := local:getDate($note)
    return
      if (not($textDate)) then ()
      else
        let $date := local:createDateTime($textDate)
        let $matchesDepression := functx:get-matches($note, "depress|despair|suicid|demoraliz")
        let $_ := if ($matchesDepression) then xdmp:set($depressionNoteCount, $depressionNoteCount+1) else ()
        let $matchesCvd := functx:get-matches($note, "cerebrovascular|stroke|hemorrhage|hypertens|aneurysm")
        let $_ := if ($matchesCvd) then xdmp:set($cvdNoteCount, $cvdNoteCount+1) else ()
        let $_ := xdmp:set($firstCvdNote, local:getFirstCvdNote($firstCvdNote, $note, $date))
        let $_ := xdmp:set($lastDepressionNote, local:getLastDepressionNote($lastDepressionNote, $note, $date))
        let $_ := xdmp:set($notesCount, $notesCount + 1)
        return ()
   return ($firstCvdNote, $lastDepressionNote)
};


declare function local:getFirstCvdNote($current, $note, $newDate) as element(firstCvdNote)?
{
   let $matched := functx:get-matches($note, "cerebrovascular|stroke|hemorrhage|hypertens|aneurysm")
   return
     if (not($matched)) then
      $current
     else if ( $matched and not($current) ) then
       element firstCvdNote { attribute date { $newDate }, $note }
     else if ( $current and (local:earlier($current/@date, $newDate ))) then 
       $current
     else
       element firstCvdNote { attribute date { $newDate }, $note }
};

declare function local:getLastDepressionNote($current, $note, $newDate) as element(lastDepressionNote)?
{
  let $matched := functx:get-matches($note, "depress|despair|suicid|demoraliz")
   return
     if (not($matched)) then
      $current
     else if ( $matched and not($current) ) then
       element lastDepressionNote { attribute date { $newDate }, $note }
     else if ( $current and (local:earlier($newDate, $current/@date ))) then 
       $current
     else
       element lastDepressionNote { attribute date { $newDate }, $note }
};

(: $uri: "/vpr/tus/66981" :)
declare function local:savePatient($uri, $firstCvdNote, $lastDepressionNote)
{
  (:
    /util/cvdDepression/tus1.xml
    <patient>
      <firstCvdNote date="12929292.29">
        blah blah blah cereobrvascular
      </firstCvdNote>
      <lastDepressionNote date="12929292.29">
        blah blah blah depressed blah blah
      </lastDepressionNote>
    </patient>
    :)
   
    if ( not($firstCvdNote) and not($lastDepressionNote)) then
      ()
    else 
    	let $docUri := "/util/cvdDepression/" || replace($uri, "/", "")
    
    	let $insert :=
    		<patient>{
     		 $firstCvdNote,
      		$lastDepressionNote
     		}</patient>
     
     	return xdmp:document-insert($docUri, $insert)
     
};


declare function local:earlier($left as xs:string, $right as xs:string) as xs:boolean
{
   xs:dateTime($left) lt xs:dateTime($right)
};

(:let $URI := "/vpr/fth/22901":)
(:let $URI := "/vpr/tus/66981":)
let $vpr := doc($URI)/va:vpr
return
  let $notes := local:parseNotes($vpr/va:results//(va:content|va:comment))
  let $firstCvdNote := $notes[1]
  let $lastDepressionNote := $notes[2]
  let $_ := local:savePatient($URI, $firstCvdNote, $lastDepressionNote) 
  return $URI


           
