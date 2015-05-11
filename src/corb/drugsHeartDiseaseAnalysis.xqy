xquery version "1.0-ml";
declare namespace rx = "ns://va.gov/2012/ip401/ontology/rxnorm" ;
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace in = "ns://va.gov/2012/ip401/ingest" at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare variable $URI as xs:string external;

(:---------------------------------------------------------------------------:)
(: STRUCTURED SEARCH METHODS :)
(:---------------------------------------------------------------------------:)

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

declare function local:getAntiDepressantDrugCodeList()
{
  let $drugClassList := ('995','Abilify','Adapin','Adderall','Anafranil','Asendin','Aurorix','Axiomin','Bolvidon','Buspar','Celexa','Cipralex','Concerta',
    'Cymbalta','Desoxyn','Desyrel','Dexedrine','Edronax','Effexor','Elavil','Eldepryl','Emsam','Endep','Eskalith','Etonin','Evadene','Feprapax','Focalin',
    'Gamanil','Insidon','Insidon','Ixel','Lamictal','Lexapro','Lithane','Lithobid','Lomont','Ludiomil','Lustral','Luvox','Manerix','Marplan','Melixeran',
    'Nardil','Nefadar','Norpramin','Norval','Pamelor','Parnate','Paxil','Pertofrane','Pirazidol','Pramolan','Pristiq','Prondol','Prothiaden','Prozac',
    'Remeron','Ritalin','Saphris','Savella','Sediel','Seroquel XR','Seroxat','Serzone','Sinequan','Solian','Strattera','Surmontil','Sycrest','SymbyaxDepakote',
    'TCAs','Tegretol','Tianeptine','Tofranil','Tolvon','Valdoxan','Viibryd','Vivactil','Vivalan','Vyvanse','Wellbutrin','YM-35','YM-992','Zelapar','Zoloft','Zyban')
  return local:getDrugCodesForList($drugClassList)
};


declare function local:getAtypicalAntipsychoticDrugCodeList()
{
  let $drugClassList := ('Abilify','Clofekton','Clozaril','Cremin','Fanapt','Geodon','Invega','Latuda','Lonasen','Lullan','Nipolept','Prazinil',
    'Risperdal','Roxiam','Saphris','Serdolect','Seroquel','Solian','Sulpirid','Zyprexa')
  return local:getDrugCodesForList($drugClassList)
};

declare function local:getTypicalAntipsychoticDrugCodeList()
{
  let $drugClassList := ('Buccastem','Clopixol','Compazine','Dridol','Droleptan','Haldol','Inapsine','Largactil','Levoprome','Loxapac','Loxitane',
    'Melleril','Mesoridazine','Moban','Navane','Nosinan','Novoridazine','Nozinan','Phenotil','Prolixin','Serentil','Stelazine','Stemetil','Stemzine',
    'Thioril','Thorazine','Trilafon','Xomolix','Zuclopenthixol')
  return local:getDrugCodesForList($drugClassList)
};

declare function local:getHeartDiseaseCodeList()
{
  (: TODO: refactor to dynamically grab these from icd9 390 - 459.9  :)
  let $heartDiseaseCodeList := ('390','391','391.1','391.2','391.8','391.9','392','392.9','393','394','394.1','394.2','394.9','395','395.1','395.2','395.9','396','396.1',
    '396.2','396.3','396.8','396.9','397','397.1','397.9','398','398.9','398.91','398.99','401','401.1','401.9','402','402.01','402.1','402.11','402.9','402.91','403','403.01',
    '403.1','403.11','403.9','403.91','404','404.01','404.02','404.03','404.1','404.11','404.12','404.13','404.9','404.91','404.92','404.93','405.01','405.09','405.11','405.19',
    '405.91','405.99','410','410.01','410.02','410.1','410.11','410.12','410.2','410.21','410.22','410.3','410.31','410.32','410.4','410.41','410.42','410.5','410.51','410.52',
    '410.6','410.61','410.62','410.7','410.71','410.72','410.8','410.81','410.82','410.9','410.91','410.92','411','411.1','411.81','411.89','412','413','413.1','413.9','414',
    '414.01','414.02','414.03','414.04','414.05','414.06','414.07','414.1','414.11','414.12','414.19','414.2','414.3','414.4','414.8','414.9','415','415.11','415.12','415.13',
    '415.19','416','416.1','416.2','416.8','416.9','417','417.1','417.8','417.9','420','420.9','420.91','420.99','421','421.1','421.9','422','422.9','422.91','422.92','422.93',
    '422.99','423','423.1','423.2','423.3','423.8','423.9','424','424.1','424.2','424.3','424.9','424.91','424.99','425','425.11','425.18','425.2','425.3','425.4','425.5','425.7',
    '425.8','425.9','426','426.1','426.11','426.12','426.13','426.2','426.3','426.4','426.5','426.51','426.52','426.53','426.54','426.6','426.7','426.81','426.82','426.89','426.9',
    '427','427.1','427.2','427.31','427.32','427.41','427.42','427.5','427.6','427.61','427.69','427.81','427.89','427.9','428','428.1','428.2','428.21','428.22','428.23','428.3',
    '428.31','428.32','428.33','428.4','428.41','428.42','428.43','428.9','429','429.1','429.2','429.3','429.4','429.5','429.6','429.71','429.79','429.81','429.82','429.83','429.89',
    '429.9','430','431','432','432.1','432.9','433','433.01','433.1','433.11','433.2','433.21','433.3','433.31','433.8','433.81','433.9','433.91','434','434.01','434.1','434.11',
    '434.9','434.91','435','435.1','435.2','435.3','435.8','435.9','436','437','437.1','437.2','437.3','437.4','437.5','437.6','437.7','437.8','437.9','438','438.1','438.11','438.12',
    '438.13','438.14','438.19','438.2','438.21','438.22','438.3','438.31','438.32','438.4','438.41','438.42','438.5','438.51','438.52','438.53','438.6','438.7','438.81','438.82',
    '438.83','438.84','438.85','438.89','438.9','440','440.1','440.2','440.21','440.22','440.23','440.24','440.29','440.3','440.31','440.32','440.4','440.8','440.9','441','441.01',
    '441.02','441.03','441.1','441.2','441.3','441.4','441.5','441.6','441.7','441.9','442','442.1','442.2','442.3','442.81','442.82','442.83','442.84','442.89','442.9','443','443.1',
    '443.21','443.22','443.23','443.24','443.29','443.81','443.82','443.89','443.9','444.01','444.09','444.1','444.21','444.22','444.81','444.89','444.9','445.01','445.02','445.81',
    '445.89','446','446.1','446.2','446.21','446.29','446.3','446.4','446.5','446.6','446.7','447','447.1','447.2','447.3','447.4','447.5','447.6','447.7','447.71','447.72','447.73',
    '447.8','447.9','448','448.1','448.9','449','451','451.11','451.19','451.2','451.81','451.82','451.83','451.84','451.89','451.9','452','453','453.1','453.2','453.3','453.4',
    '453.41','453.42','453.5','453.51','453.52','453.6','453.71','453.72','453.73','453.74','453.75','453.76','453.77','453.79','453.81','453.82','453.83','453.84','453.85','453.86',
    '453.87','453.89','453.9','454','454.1','454.2','454.8','454.9','455','455.1','455.2','455.3','455.4','455.5','455.6','455.7','455.8','455.9','456','456.1','456.2','456.21',
    '456.3','456.4','456.5','456.6','456.8','457','457.1','457.2','457.8','457.9','458','458.1','458.21','458.29','458.8','458.9','459','459.1','459.11','459.12','459.13','459.19',
    '459.2','459.3','459.31','459.32','459.33','459.39','459.81','459.89','459.9')
  return $heartDiseaseCodeList
};

declare function local:doesPatientTreatmentContainStructuredHD($patientTreatment, $heartDiseaseList)
{
    try
    {
        if
        (
          functx:contains-any-of($patientTreatment/va:principalDiagnosis, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis1, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis2, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis3, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis4, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis5, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis6, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis7, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis8, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis9, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis10, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis11, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis12, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosis13, $heartDiseaseList) or
          functx:contains-any-of($patientTreatment/va:principalDiagnosisPre1986, $heartDiseaseList)
        )
        then
          true()
        else
          false()
    }
    catch($exception)
    {
      false()
    }
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

declare function local:getDateFromPatientTreatmentNode($admissionDateNode)
{
    if(not(empty($admissionDateNode/text()))) then
      let $admissionString := string($admissionDateNode)
      let $position := functx:index-of-string($admissionString, "T")
      return
        if ( $position ) then
          xs:date(substring($admissionString, 0, $position))
        else
          xs:date($admissionString)
    else
      ()
};

declare function local:getEarliestStructuredHDReference($vpr, $heartDiseaseList)
{
  let $earliestStructuredHD := ()
  let $patientTreatments := $vpr/va:results/va:patientTreatments/va:patientTreatment
  let $_ :=  (
    for $patientTreatment in $patientTreatments
      let $containsHd := local:doesPatientTreatmentContainStructuredHD($patientTreatment, $heartDiseaseList)
      let $contentNodeDate := local:getDateFromPatientTreatmentNode($patientTreatment/va:admissionDate)
      return
        if($containsHd and $contentNodeDate instance of xs:date ) then
          if ($earliestStructuredHD) then
            if( $contentNodeDate lt $earliestStructuredHD/@date ) then
              xdmp:set($earliestStructuredHD, element earliestStructuredHDReference { attribute date { xs:date($contentNodeDate) }, $patientTreatment })
            else
              (: the passed in comparison node was older so don't do anything :)
              ()
          else
            xdmp:set($earliestStructuredHD, element earliestStructuredHDReference { attribute date { xs:date($contentNodeDate) }, $patientTreatment })
        else
          ()
  )

  return $earliestStructuredHD
};

(:  $type 1 is for Anti Depressant Drug, 2 is for Atypical Anti Pyschotic Drug, and 3 is for Anti Psychotic Drug :)
declare function local:createStructuredDrugReference($type, $contentNodeDate, $med)
{
  switch ($type)
     case "1" return element earliestStructuredADReference { attribute date { xs:date($contentNodeDate) }, $med }
     case "2" return element earliestStructuredAAPReference { attribute date { xs:date($contentNodeDate) }, $med }
     case "3" return element earliestStructuredAPReference { attribute date { xs:date($contentNodeDate) }, $med }
     default return ()
};

declare function local:getEarliestStructuredDrugReference($vpr, $drugList, $type)
{
  let $earliestStructuredDrugReference := ()
  let $productClasses := $vpr/va:results/va:meds/va:med/va:products/va:product/va:class
  let $_ :=  (
    for $class in $productClasses
      let $containsStructuredReference := functx:contains-any-of($class/@vuid, $drugList)
      let $med := $class/../../..
      let $contentNodeDate := local:getDateFromVprDateString($med/va:ordered)
      return
        if($containsStructuredReference and $contentNodeDate instance of xs:date ) then
          if ($earliestStructuredDrugReference) then
            if( $contentNodeDate lt $earliestStructuredDrugReference/@date ) then
              xdmp:set($earliestStructuredDrugReference, local:createStructuredDrugReference($type, $contentNodeDate, $med) )
            else ()
          else
            xdmp:set($earliestStructuredDrugReference, local:createStructuredDrugReference($type, $contentNodeDate, $med) )
        else ()
  )
  return $earliestStructuredDrugReference
};

(:---------------------------------------------------------------------------:)
(: UNSTRUCTURED SEARCH METHODS :)
(:---------------------------------------------------------------------------:)
declare function local:doesContentContainCardiovascularEvent($contentElement)
{
    let $result := functx:contains-any-of(lower-case($contentElement/string(.)),
      ( 'acute myocardial infarction', 'angina', 'arrhythmia', 'atherosclerosis', 'cardiomegaly',
        'cardiomyopathy', 'carotid artery disease', 'congenital heart disease', 'congestive heart failure',
        'coronary artery disease', 'endocarditis', 'fluid around the heart', 'hypertension', 'infective endocarditis',
        'mitral valve prolapse', 'peripheral artery disease', 'stroke', 'valvular heart disease'  )
    )
    return $result
};

declare function local:doesContentContainAntiPsychoticDrug($contentElement)
{
    let $result := functx:contains-any-of(lower-case($contentElement/string(.)),
      ( 'buccastem','chlorpromazine','clopixol','compazine','dridol','droleptan','droperidol','fentanyl','fluphenazine',
        'haldol','haloperidol','inapsine','innovar','largactil','levomepromazine','levoprome','loxapac','loxapine',
        'loxitane','mellaril','melleril','mesoridazine','moban','molindone','navane','nosinan','novoridazine','nozinan',
        'perphenazine','phenotil','prochlorperazine','prolixin','serentil','stelazine','stemetil','stemzine','thioridazine',
        'thioril','thiothixene','thorazine','trifluoperazine','trilafon','xomolix','zuclopenthixol')
    )
    return $result
};

declare function local:doesContentContainAtypicalAntiPsychoticDrug($contentElement)
{
    let $result := functx:contains-any-of(lower-case($contentElement/string(.)),
      ( 'abilify','amisulpride','aripiprazole','asenapine','blonanserin','carpipramine','clocapramine','clofekton',
        'clozapine','clozaril','cremin','fanapt','geodon','iIloperidone','invega','latuda','lonasen','lullan','lurasidone',
        'mosapramine','nipolept','olanzapine','paliperidone','perospirone','prazinil','quetiapine','remoxipride','risperdal',
        'risperidone','roxiam','saphris','serdolect','seroquel','sertindole','solian','sulpirid','sulpiride','ziprasidone',
        'zotepine','zyprexa' )
    )
    return $result
};

declare function local:doesContentContainAntiDepressantDrug($contentElement)
{
    let $result := functx:contains-any-of(lower-case($contentElement/string(.)),
      ( 'abilify','adapin','adderall','agomelatine','amisulpride','amitriptyline','amoxapine','amphetamine','anafranil',
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
    )
    return $result
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
    (: xdmp:parse-dateTime("[M01][D01][Y0001]", $convertedDateString) :)
    functx:mmddyyyy-to-date($convertedDateString)
  else
    ()
};

declare function local:match($text as xs:string) as xs:string
{
  let $match := functx:get-matches($text, "Date Reported: (\w{3} \d{1,2}, \d{2,4})")[2]
  return substring($match, 16, string-length($match)-16+1)
};

declare function local:setAntiDepressantElement($earliestADElement, $contentElement)
{
  let $contentNodeDate := local:getDateFromContent($contentElement)
  let $containsADD := local:doesContentContainAntiDepressantDrug($contentElement)
  return
    if( $containsADD and ($contentNodeDate instance of xs:date) ) then
      if ( $earliestADElement ) then
        if( $contentNodeDate lt $earliestADElement/@date ) then
          element earliestUnstructuredAntiDepressantReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
        else
          (: the passed in comparison node was older so don't do anything :)
          ()
      else
          element earliestUnstructuredAntiDepressantReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
    else
      (: the content node did not have a date or did not contain an anti depressant drug :)
      ()
};

declare function local:setAntiPsychoticElement($earliestAPElement, $contentElement)
{
  let $contentNodeDate := local:getDateFromContent($contentElement)
  let $containsAPD := local:doesContentContainAntiPsychoticDrug($contentElement)
  return
    if( $containsAPD and ($contentNodeDate instance of xs:date) ) then
      if ( $earliestAPElement ) then
        if( $contentNodeDate lt $earliestAPElement/@date ) then
          element earliestUnstructuredAntiPsychoticReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
        else
          (: the passed in comparison node was older so don't do anything :)
          ()
      else
          element earliestUnstructuredAntiPsychoticReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
    else
      (: the content node did not have a date or did not contain an anti psychotic drug :)
      ()
};

declare function local:setAtypicalAntiPsychoticElement($earliestAAPElement, $contentElement)
{
  let $contentNodeDate := local:getDateFromContent($contentElement)
  let $containsAAPD := local:doesContentContainAtypicalAntiPsychoticDrug($contentElement)
  return
    if( $containsAAPD and ($contentNodeDate instance of xs:date) ) then
      if ( $earliestAAPElement ) then
        if( $contentNodeDate lt $earliestAAPElement/@date ) then
          element earliestUnstructuredAtypicalAntiPsychoticReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
        else
          (: the passed in comparison node was older so don't do anything :)
          ()
      else
          element earliestUnstructuredAtypicalAntiPsychoticReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
    else
      (: the content node did not have a date or did not contain an atypical anti psychotic drug :)
      ()
};

(: earliestHeartDiseaseReference :)
declare function local:setHeartDiseaseElement($earliestHDElement, $contentElement)
{
  let $contentNodeDate := local:getDateFromContent($contentElement)
  let $containsHD := local:doesContentContainCardiovascularEvent($contentElement)
  return
    if( $containsHD and ($contentNodeDate instance of xs:date) ) then
      if ( $earliestHDElement ) then
        if( $contentNodeDate lt $earliestHDElement/@date ) then
          element earliestUnstructuredHeartDiseaseReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
        else
          (: the passed in comparison node was older so don't do anything :)
          ()
      else
          element earliestUnstructuredHeartDiseaseReference { attribute date { xs:date($contentNodeDate) }, $contentElement }
    else
      (: the content node did not have a date or did not contain a heart disease reference :)
      ()
};

declare function local:createPatientElement($vpr)
{
  let $contentElements := $vpr/va:results//va:document/va:content
  let $earliestUnstructuredADReference := ()
  let $earliestUnstructuredAPReference := ()
  let $earliestUnstructuredAAPReference := ()
  let $earliestUnstructuredHDReference := ()
  let $_ := (
    for $contentElement in $contentElements
      let $adCompareResult := local:setAntiDepressantElement($earliestUnstructuredADReference, $contentElement)
      let $_ := (
        if( $adCompareResult ) then
          xdmp:set($earliestUnstructuredADReference, $adCompareResult)
        else () )
      let $apCompareResult := local:setAntiPsychoticElement($earliestUnstructuredAPReference, $contentElement)
      let $_ := (
        if( $apCompareResult ) then
          xdmp:set($earliestUnstructuredAPReference, $apCompareResult)
        else () )
      let $aapCompareResult := local:setAtypicalAntiPsychoticElement($earliestUnstructuredAAPReference, $contentElement)
      let $_ := (
        if( $aapCompareResult ) then
          xdmp:set($earliestUnstructuredAAPReference, $aapCompareResult)
        else () )
      let $hdCompareResult := local:setHeartDiseaseElement($earliestUnstructuredHDReference, $contentElement)
      let $_ := (
        if( $hdCompareResult ) then
          xdmp:set($earliestUnstructuredHDReference, $hdCompareResult)
        else () )

      return ()
  )
  let $antiDepressantList := local:getAntiDepressantDrugCodeList()
  let $earliestStructuredADReference := local:getEarliestStructuredDrugReference($vpr, $antiDepressantList, "1")
  let $atypicalAntiPsychoticList := local:getAtypicalAntipsychoticDrugCodeList()
  let $earliestStructuredAAPReference := local:getEarliestStructuredDrugReference($vpr, $atypicalAntiPsychoticList, "2")
  let $typicalAntiPsychoticList := local:getTypicalAntipsychoticDrugCodeList()
  let $earliestStructuredAPReference := local:getEarliestStructuredDrugReference($vpr, $typicalAntiPsychoticList, "3")
  let $heartDiseaseList := local:getHeartDiseaseCodeList()
  let $earliestStructuredHDReference := local:getEarliestStructuredHDReference($vpr, $heartDiseaseList)
  return
    if ($earliestUnstructuredADReference or
        $earliestUnstructuredAPReference or
        $earliestUnstructuredAAPReference or
        $earliestUnstructuredHDReference or
        $earliestStructuredADReference or
        $earliestStructuredAAPReference or
        $earliestStructuredAPReference or
        $earliestStructuredHDReference
    ) then
      element patient
        {
          attribute id { $vpr/va:meta/va:id },
          attribute site { $vpr/va:meta/va:site},
          $earliestUnstructuredADReference,
          $earliestUnstructuredAPReference,
          $earliestUnstructuredAAPReference,
          $earliestUnstructuredHDReference,
          $earliestStructuredADReference,
          $earliestStructuredAAPReference,
          $earliestStructuredAPReference,
          $earliestStructuredHDReference
        }
    else
      ()
};

(: let $vpr := /va:vpr[va:meta/va:id=21]  :)
let $vpr := doc($URI)/va:vpr
let $patientElement := local:createPatientElement($vpr)
(: let $_ := xdmp:log("insert element for:" || $vpr/va:meta/va:site || $vpr/va:meta/va:id || '.xml') :)
let $documentURI := concat("/util/drugsHeartDisease/",$vpr/va:meta/va:site,$vpr/va:meta/va:id,'.xml')
let $_ := (
  if ($patientElement) then
    xdmp:document-insert(
       $documentURI,
       $patientElement,
       xdmp:default-permissions(),
       xdmp:default-collections(),
       10)
  else
    ""
)

return $URI