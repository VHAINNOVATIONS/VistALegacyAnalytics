xquery version "1.0-ml";
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace enrich = "ns://va.gov/2012/ip401/enrich-util" at "/lib/enrich.xqy";

declare variable $URI as xs:string external;

declare function local:getDrugNamesFromFoundDrugInList($class, $drugList)
{
  for $drug in $drugList
    let $drugCodeList := local:getCodesForDrugFromRx($drug)
    let $containsDrug := functx:contains-any-of($class/@vuid, $drugCodeList)
    return
      if ($containsDrug) then
        upper-case($drug)
      else
        ()
};

declare function local:getDrugCodesForList($drugClassList)
{
  let $masterDrugCodes := ()
  let $_ := (
     for $drugClass in $drugClassList
     let $currentDrugCodes := local:getCodesForDrugFromRx($drugClass)
     let $joinedList := functx:value-union($masterDrugCodes, $currentDrugCodes)
     let $_ := xdmp:set($masterDrugCodes, $joinedList)
     return ()
  )
  return $masterDrugCodes
};

(: returns a list of uppercase anti pyschotic drugs from the passed in content :)
declare function local:getDrugsFromContent($contentElement, $drugList)
{
  let $foundDrugs := (
    for $drugName in $drugList
      return
      if (contains(lower-case($contentElement/string(.)), $drugName)) then
        upper-case($drugName)
      else ()
  )
  return $foundDrugs
};

(:gets a sequence of all of the unique validated drug codes for the passed in drug class name:)
declare function local:getCodesForDrugFromRx($drugClass)
{
  let $drugClass := concat("[",$drugClass,"]")
  let $codes := distinct-values(/rx:concept[contains(@str,$drugClass)]/rx:atom/rx:code)
  for $code in $codes
    return
    if( functx:is-a-number($code) ) then
      $code
    else
      ()
};

declare function local:getDateFromVprDateString($vprDate)
{
  try
  {
    if(empty($vprDate) or $vprDate = "") then
      ()
    else
      let $dateString := util:convert-vpr-date($vprDate)
      return
        let $dateString := string($dateString)
        let $position := functx:index-of-string($dateString, "T")
        return
          if ( $position ) then
            xs:date(substring($dateString, 0, $position))
          else
            xs:date($dateString)
  }
  catch($exception)
  {
    ()
  }
};

declare function local:convertMonthToNumberForDateString($dateString)
{
  let $month := map:map()
  let $_ :=
  (
      map:put($month, "JAN", "01"),
      map:put($month, "FEB", "02"),
      map:put($month, "MAR", "03"),
      map:put($month, "APR", "04"),
      map:put($month, "MAY", "05"),
      map:put($month, "JUN", "06"),
      map:put($month, "JUL", "07"),
      map:put($month, "AUG", "08"),
      map:put($month, "SEP", "09"),
      map:put($month, "OCT", "10"),
      map:put($month, "NOV", "11"),
      map:put($month, "DEC", "12")
  )
  let $monthAbr := fn:substring($dateString, 1, 3)
  let $numberMonth := map:get($month, fn:upper-case($monthAbr) )
  let $dateLength := fn:string-length($dateString)
  let $secondHalfOfDate := fn:substring($dateString, 4, $dateLength - 3)
  let $formattedDateString := concat($numberMonth, $secondHalfOfDate)
  return $formattedDateString
};

declare function local:match($text as xs:string) as xs:string
{
  let $match := functx:get-matches($text, "Date Reported: (\w{3} \d{1,2}, \d{2,4})")[2]
  return substring($match, 16, string-length($match)-16+1)
};

declare function local:getDateFromContent($contentNode)
{
  let $matchedDateString :=  local:match($contentNode)
  let $matchedDateString := functx:trim($matchedDateString)
  let $convertedDateString := local:convertMonthToNumberForDateString($matchedDateString)
  let $convertedDateString := replace($convertedDateString, ',','')
  let $convertedDateString := replace($convertedDateString, ' ','')
  let $convertedDateString := functx:trim($convertedDateString)
  let $convertedDateStringLen := fn:string-length($convertedDateString)
  return
  if ($convertedDateString and $convertedDateStringLen eq 8) then
    functx:mmddyyyy-to-date($convertedDateString)
  else ()
};

declare function local:getUnstructuredADDrugElement($content, $foundAntiDepressantDrugs)
{
  let $contentNodeDate := local:getDateFromContent($content)
  return
    if ($foundAntiDepressantDrugs and ($contentNodeDate instance of xs:date )) then
       for $antiDepressantDrug in $foundAntiDepressantDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AntiDepressant"},
          attribute name { $antiDepressantDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "unstructured" },
          attribute sourceFieldName { "content" },
          $antiDepressantDrug  }
    else ()
};

declare function local:getUnstructuredAAPDrugElement($content, $foundAtypicalAntiPsychoticDrugs)
{
  let $contentNodeDate := local:getDateFromContent($content)
  return
    if ($foundAtypicalAntiPsychoticDrugs and ($contentNodeDate instance of xs:date )) then
      for $atypicalAntiPsychoticDrug in $foundAtypicalAntiPsychoticDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AtypicalAntiPsychotic"},
          attribute name { $atypicalAntiPsychoticDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "unstructured" },
          attribute sourceFieldName { "content" },
          $atypicalAntiPsychoticDrug }
    else ()
};

declare function local:getUnstructuredAPDrugElement($content, $foundAntiPsychoticDrugs)
{
  let $contentNodeDate := local:getDateFromContent($content)
  return
    if ($foundAntiPsychoticDrugs and ($contentNodeDate instance of xs:date )) then
      for $antiPsychoticDrug in $foundAntiPsychoticDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AntiPsychotic"},
          attribute name { $antiPsychoticDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "unstructured" },
          attribute sourceFieldName { "content" },
          $antiPsychoticDrug }
    else ()
};

declare function local:getStructuredADDrugElement($class, $foundAntiDepressantDrugs)
{
  let $med := $class/../../..
  let $contentNodeDate := local:getDateFromVprDateString($med/va:ordered)
  return
    if ($foundAntiDepressantDrugs and ($contentNodeDate instance of xs:date )) then
       for $antiDepressantDrug in $foundAntiDepressantDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AntiDepressant"},
          attribute name { $antiDepressantDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "structured" },
          attribute sourceFieldName { "class" },
          $antiDepressantDrug }
    else ()
};

declare function local:getStructuredAAPDrugElement($class, $foundAtypicalAntiPsychoticDrugs)
{
  let $med := $class/../../..
  let $contentNodeDate := local:getDateFromVprDateString($med/va:ordered)
  return
    if ($foundAtypicalAntiPsychoticDrugs and ($contentNodeDate instance of xs:date )) then
      for $atypicalAntiPsychoticDrug in $foundAtypicalAntiPsychoticDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AtypicalAntiPsychotic"},
          attribute name { $atypicalAntiPsychoticDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "structured" },
          attribute sourceFieldName { "class" },
          $atypicalAntiPsychoticDrug }
     else ()
};

declare function local:getStructuredAPDrugElement($class, $foundAntiPsychoticDrugs)
{
  let $med := $class/../../..
  let $contentNodeDate := local:getDateFromVprDateString($med/va:ordered)
  return
    if ($foundAntiPsychoticDrugs and ($contentNodeDate instance of xs:date )) then
      for $antiPsychoticDrug in $foundAntiPsychoticDrugs
        return
        element enr:drug {
          attribute group { "Drugs" },
          attribute type { "AntiPsychotic"},
          attribute name { $antiPsychoticDrug },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { "structured" },
          attribute sourceFieldName { "class" },
          $antiPsychoticDrug }
    else ()
};

declare function local:createDrugElements($vpr)
{
  let $contentElements := $vpr/va:results//va:document/va:content
  let $unstructuredADElements := (
    let $antiDepressantTextDrugList := ( 'abilify','adapin','adderall','agomelatine','amisulpride','amitriptyline','amoxapine','amphetamine','anafranil',
        'andospirone','aripiprazole','asenapine','asendin','atomoxetine','aurorix','axiomin','bolvidon','bupropion',
        'buspar','buspirone','butriptyline','carbamazepine','celexa','cipralex','citalopram','clomipramine','concerta',
        'cymbalta','depakote','desipramine','desoxyn','desvenlafaxine','desyrel','dexedrine','dexmethylphenidate','dextroamphetamine',
        'dextromethamphetamine','dosulepin','dothiepin','doxepin','duloxetine','edronax','effexor','elavil','eldepryl','emsam',
        'endep','escitalopram','eskalith','etonin','etoperidone','evadene','feprapax','fluoxetine','fluvoxamine','focalin',
        'gamanil','imipramine','insidon','iprindole','isocarboxazid','ixel','lamictal','lamotrigine','l-deprenyl','lexapro',
        'lisdexamfetamine','lithane','lithium','lithobid','lofepramine','lomont','lubazodone','ludiomil','lustral','luvox',
        'manerix','maprotiline','marplan','melitracen','melixeran','methylphenidate','mianserin','milnacipran','mirtazapine',
        'moclobemide','nardil','nefadar','nefazodone','norpramin','nortriptyline','norvalTolvon','olanzapine','opipramol','pamelor',
        'parnate','paroxetine','paxil','pertofrane','phenelzine','pirazidol','pirlindole','pramolan','pristiq','prondol','prothiaden',
        'protriptyline','prozac','quetiapine xr','reboxetine','remeron','ritalin','saphris','savella','sediel','selegiline','seroquel xr',
        'seroxat','sertraline','serzone','sinequan','solian','sSurmontil','strattera','surmontil','sycrest','symbyax','tegretol',
        'tianeptine','tofranil','tranylcypromine','trazodone','trimipramine','valdoxan','valproic acid','venlafaxine','viibryd',
        'vilazodone','viloxazine','vivactil','vivalan','vyvanse','wellbutrin','ym-35','ym-992','zelapar','zoloft','zyban')
    for $content in $contentElements
      let $foundAntiDepressantDrugs := local:getDrugsFromContent($content, $antiDepressantTextDrugList)
      return local:getUnstructuredADDrugElement($content, $foundAntiDepressantDrugs)
  )
  let $unstructuredAAPElements :=
  (
    let $aypticalAntiPsychoticTextDrugList := ( 'abilify','amisulpride','aripiprazole','asenapine','blonanserin','carpipramine','clocapramine','clofekton',
        'clozapine','clozaril','cremin','fanapt','geodon','iIloperidone','invega','latuda','lonasen','lullan','lurasidone',
        'mosapramine','nipolept','olanzapine','paliperidone','perospirone','prazinil','quetiapine','remoxipride','risperdal',
        'risperidone','roxiam','saphris','serdolect','seroquel','sertindole','solian','sulpirid','sulpiride','ziprasidone',
        'zotepine','zyprexa' )
    for $content in $contentElements
      let $foundAtypicalAntiPsychoticDrugs := local:getDrugsFromContent($content, $aypticalAntiPsychoticTextDrugList)
      return local:getUnstructuredAAPDrugElement($content, $foundAtypicalAntiPsychoticDrugs)
  )
  let $unstructuredAPElements :=
  (
    let $antiPsychoticTextDrugList := ( 'buccastem','chlorpromazine','clopixol','compazine','dridol','droleptan','droperidol','fentanyl','fluphenazine',
        'haldol','haloperidol','inapsine','innovar','largactil','levomepromazine','levoprome','loxapac','loxapine',
        'loxitane','mellaril','melleril','mesoridazine','moban','molindone','navane','nosinan','novoridazine','nozinan',
        'perphenazine','phenotil','prochlorperazine','prolixin','serentil','stelazine','stemetil','stemzine','thioridazine',
        'thioril','thiothixene','thorazine','trifluoperazine','trilafon','xomolix','zuclopenthixol')
    for $content in $contentElements
      let $foundAntiPsychoticDrugs := local:getDrugsFromContent($content, $antiPsychoticTextDrugList)
      return local:getUnstructuredAPDrugElement($content, $foundAntiPsychoticDrugs)
  )
  let $productClasses := $vpr/va:results/va:meds/va:med/va:products/va:product/va:class
  let $structuredADElements :=
  (
    let $antiDepressantDrugList := ('995','Abilify','Adapin','Adderall','Anafranil','Asendin','Aurorix','Axiomin','Bolvidon','Buspar','Celexa','Cipralex','Concerta',
      'Cymbalta','Desoxyn','Desyrel','Dexedrine','Edronax','Effexor','Elavil','Eldepryl','Emsam','Endep','Eskalith','Etonin','Evadene','Feprapax','Focalin',
      'Gamanil','Insidon','Insidon','Ixel','Lamictal','Lexapro','Lithane','Lithobid','Lomont','Ludiomil','Lustral','Luvox','Manerix','Marplan','Melixeran',
      'Nardil','Nefadar','Norpramin','Norval','Pamelor','Parnate','Paxil','Pertofrane','Pirazidol','Pramolan','Pristiq','Prondol','Prothiaden','Prozac',
      'Remeron','Ritalin','Saphris','Savella','Sediel','Seroquel XR','Seroxat','Serzone','Sinequan','Solian','Strattera','Surmontil','Sycrest','SymbyaxDepakote',
      'TCAs','Tegretol','Tianeptine','Tofranil','Tolvon','Valdoxan','Viibryd','Vivactil','Vivalan','Vyvanse','Wellbutrin','YM-35','YM-992','Zelapar','Zoloft','Zyban')
    for $class in $productClasses
      let $foundAntiDepressantDrugs := local:getDrugNamesFromFoundDrugInList($class, $antiDepressantDrugList)
      return local:getStructuredADDrugElement($class, $foundAntiDepressantDrugs)
  )
  let $structuredAAPElements :=
  (
    let $atypicalAntiPsychoticList := ('Abilify','Clofekton','Clozaril','Cremin','Fanapt','Geodon','Invega','Latuda','Lonasen','Lullan','Nipolept','Prazinil',
      'Risperdal','Roxiam','Saphris','Serdolect','Seroquel','Solian','Sulpirid','Zyprexa')
    for $class in $productClasses
      let $foundAtypicalAntiPsychoticDrugs := local:getDrugNamesFromFoundDrugInList($class, $atypicalAntiPsychoticList)
      return local:getStructuredAAPDrugElement($class, $foundAtypicalAntiPsychoticDrugs)
  )
  let $structuredAPElements :=
  (
    let $antiPsychoticList := ('Buccastem','Clopixol','Compazine','Dridol','Droleptan','Haldol','Inapsine','Largactil','Levoprome','Loxapac','Loxitane',
      'Melleril','Mesoridazine','Moban','Navane','Nosinan','Novoridazine','Nozinan','Phenotil','Prolixin','Serentil','Stelazine','Stemetil','Stemzine',
      'Thioril','Thorazine','Trilafon','Xomolix','Zuclopenthixol')
    for $class in $productClasses
      let $foundAntiPsychoticDrugs := local:getDrugNamesFromFoundDrugInList($class, $antiPsychoticList)
      return local:getStructuredAPDrugElement($class, $foundAntiPsychoticDrugs)
  )

  return
    if ( $unstructuredADElements or $unstructuredAAPElements or $unstructuredAPElements or
         $structuredADElements or $structuredAAPElements or $structuredAPElements) then
        for $el in ($unstructuredADElements, $unstructuredAAPElements, $unstructuredAPElements, $structuredADElements, $structuredAAPElements, $structuredAPElements)
        order by $el/@referenceDate
        return $el
    else
      ()
};

(:
declare function local:addDrugsToPatient($vpr, $drugElements)
{
  let $results := $vpr/va:meta/va:enrichment
  let $_ := for $n in $results/enr:events/enr:eventDate/enr:drug return xdmp:node-deletel($n)
  let $events := $results/enr:events
  return
    if (fn:not(fn:exists($events))) then
      let $events :=
        <enr:events>
          {
            let $map := map:map()
            let $_buildmap :=
              for $el in $drugElements
              let $date := $el/@referenceDate
              let $prevval := map:get($map, $date)
              return if ($prevval) then map:put($map, $date, ($prevval, $el)) else map:put($map, $date, $el)
            for $key in map:keys($map)
            return <enr:eventDate referenceDate="{$key}">{map:get($map, $key)}</enr:eventDate>
          }
        </enr:events>
      let $events := if (fn:not(fn:exists($results))) then <va:enrichment>{$events}</va:enrichment> else $events
      let $results := if (fn:not(fn:exists($results))) then $vpr/va:meta else $results
      return xdmp:node-insert-child($results, $events)
    else
      let $_  := (
       if($drugElements) then
          for $drug in $drugElements
          let $date := $drug/@referenceDate
          let $drugevent := <enr:eventDate referenceDate="{$date}">{$drug}</enr:eventDate>
          let $existingDateMatch := $results/enr:events/node()[xs:date(@referenceDate) = xs:date($date)]
          let $prevsibling := ($results/enr:events/node()[xs:date(@referenceDate) < xs:date($date)])[fn:last()]
          let $postsibling := ($results/enr:events/node()[xs:date(@referenceDate) > xs:date($date)])[1]
          let $_ := if (fn:exists($existingDateMatch)) then
            xdmp:node-insert-child($existingDateMatch, $drug)
          else if (fn:exists($prevsibling)) then
            xdmp:node-insert-after($prevsibling, $drugevent)
          else if (fn:exists($postsibling)) then
            xdmp:node-insert-before($postsibling, $drugevent)
          else
            xdmp:node-insert-child($results/enr:events, $drugevent)
          return ()
       else ()  )
       return ()
};
:)

let $vpr := doc($URI)/va:vpr
let $drugElements := local:createDrugElements($vpr)
(: let $_ := local:addDrugsToPatient($vpr, $drugElements) :)
let $_ := enrich:add-replace-events($vpr, $drugElements )
return $URI;

(: 2nd transation :)

xquery version "1.0-ml";
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;
declare namespace va = "ns://va.gov/2012/ip401";
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare variable $URI as xs:string external;

let $vpr := doc($URI)/va:vpr
let $_ := util:add-enrichment-indicator($vpr, xs:QName('enr:patient-Event-Drug-List-Enrichment'))
return $URI
