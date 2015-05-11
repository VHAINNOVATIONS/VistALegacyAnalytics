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

(: code must either be XXX.X or XXX.XX whole numbers come in as XXX. :)
declare function local:validateDiagnosisFormat($diagnosis)
{
  let $decimalPosition := functx:index-of-string($diagnosis, ".")
  let $diagnosisLength := string-length($diagnosis)
  return
    if( ($decimalPosition = 4) and ( ($diagnosisLength = 5) or ($diagnosisLength = 6) ) ) then
      true()
    else
      false()
};

declare function local:reformatDiagnosis($diagnosis)
{
  let $decimalPosition := functx:index-of-string($diagnosis, ".")
    return
    if ($decimalPosition) then
      let $firstHalf := (
        let $str := substring-before($diagnosis, '.')
        let $strLen := string-length($str)
        return
          if($strLen = 3) then
            $str
          else if($strLen = 2) then
            "0" || $str
          else if($strLen = 1) then
            "00" || $str
          else ()
      )
      let $secondHalf := (
        let $str := substring-after($diagnosis, '.')
        let $strLen := string-length($str)
        return
          if(($strLen = 1) or ($strLen = 2)) then
            $str
          else
            "0"
      )
      return $firstHalf || "." || $secondHalf
    else
      let $strLen := string-length($diagnosis)
      return
        if($strLen = 1) then
          "00" || $diagnosis || ".0"
        else if($strLen = 2) then
          "0" || $diagnosis || ".0"
        else if($strLen = 3) then
          $diagnosis || ".0"
        else
          ()
};

declare function local:getValidDiagnosisCode($diagnosis)
{
  if(local:validateDiagnosisFormat($diagnosis)) then
    $diagnosis
  else
    local:reformatDiagnosis($diagnosis)
};

declare function local:getDiagnosisDescriptionByCode($diagnosisCode)
{
  let $validDiagnosisCode := local:getValidDiagnosisCode($diagnosisCode)
  return
    if ($validDiagnosisCode) then
      let $description := on:get-concept-by-code($validDiagnosisCode)/on:concept/@description/string(.)
      return
        if ($description) then
          upper-case($description)
        else ()
    else ()
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
  else
    ()
};

declare function local:getDiagnosisFromContent($content, $diagnoses)
{
  let $foundDiagnoses := (
    for $diagnosisName in $diagnoses
      return
      if (contains(lower-case($content/string(.)), $diagnosisName)) then
        upper-case($diagnosisName)
      else ()
  )
  return $foundDiagnoses
};

declare function local:getDiagnosesFromCode($code, $diagnoses)
{
    try
    {
        if(functx:contains-any-of($code, $diagnoses)) then
          for $diagnosis in $diagnoses
            return
            if(contains($code, $diagnosis)) then
              local:getDiagnosisDescriptionByCode($diagnosis)
            else ()
        else ()
    }
    catch($exception) { () }
};

declare function local:getUnstructuredDiagnosisElement($content, $foundDiagnosis, $type, $sourceType, $sourceFieldName)
{
  let $contentNodeDate := local:getDateFromContent($content)
  return
    if ($foundDiagnosis and ($contentNodeDate instance of xs:date )) then
       for $diagnosis in $foundDiagnosis
        return
        element enr:diagnosis {
          attribute group { "Diagnoses" },
          attribute type { $type },
          attribute name { $diagnosis },
          attribute referenceDate { $contentNodeDate },
          attribute sourceType { $sourceType },
          attribute sourceFieldName { $sourceFieldName },
          $diagnosis }
    else ()
};

declare function local:createStructuredDiagnosisElement($foundDiagnosis, $type, $sourceType, $sourceFieldName, $contentNodeDate)
{
  if ($foundDiagnosis and ($contentNodeDate instance of xs:date )) then
   for $diagnosis in $foundDiagnosis
    return
    element enr:diagnosis {
      attribute group { "Diagnoses" },
      attribute type { $type },
      attribute name { $diagnosis },
      attribute referenceDate { $contentNodeDate },
      attribute sourceType { $sourceType },
      attribute sourceFieldName { $sourceFieldName },
      $diagnosis }
  else ()
};

declare function local:getDiagnosesFromPatientTreatment($patientTreatment, $diagnoses)
{
  let $masterDiagnoses := ()
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis1, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis2, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis3, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis4, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis5, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis6, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis7, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis8, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis9, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis10, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis11, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis12, $diagnoses))
  let $masterDiagnoses := insert-before($masterDiagnoses, 0, local:getDiagnosesFromCode($patientTreatment/va:principalDiagnosis13, $diagnoses))
  return $masterDiagnoses
};

declare function local:createDiagnosisElements($vpr)
{
  let $contentElements := $vpr/va:results//va:document/va:content
  let $unstructuredHDElements :=
  (
    let $heartDiseaseTextList := ( 'acute myocardial infarction', 'angina', 'arrhythmia', 'atherosclerosis', 'cardiomegaly',
        'cardiomyopathy', 'carotid artery disease', 'congenital heart disease', 'congestive heart failure',
        'coronary artery disease', 'endocarditis', 'fluid around the heart', 'hypertension', 'infective endocarditis',
        'mitral valve prolapse', 'peripheral artery disease', 'stroke', 'valvular heart disease' )
    for $content in $contentElements
      let $foundHeartDisease := local:getDiagnosisFromContent($content, $heartDiseaseTextList)
      return local:getUnstructuredDiagnosisElement($content, $foundHeartDisease, "HeartDisease", "unstructured", "content")
  )
  let $heartDiseaseCodes := ('390','391','391.1','391.2','391.8','391.9','392','392.9','393','394','394.1','394.2','394.9','395','395.1','395.2','395.9','396','396.1',
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
  let $structuredPatientTreatmentHDElements :=
  (
    let $patientTreatments := $vpr/va:results/va:patientTreatments/va:patientTreatment
    for $patientTreatment in $patientTreatments
      let $contentNodeDate := local:getDateFromPatientTreatmentNode($patientTreatment/va:admissionDate)
      let $foundHeartDiseases := local:getDiagnosesFromPatientTreatment($patientTreatment, $heartDiseaseCodes)
      return local:createStructuredDiagnosisElement($foundHeartDiseases, "HeartDisease", "structured", "patientTreatment", $contentNodeDate)
  )
  let $structuredVisitsHDElements :=
  (
    let $visits := $vpr/va:results/va:visits/va:visit
    for $visit in $visits
      let $reasonCode := $visit/va:reason/va:reason-code
      let $foundHeartDiseases := local:getDiagnosesFromCode($visit/va:reason/va:reason-code, $heartDiseaseCodes)
      let $contentNodeDate := local:getDateFromVprDateString($visit/va:dateTime)
      return local:createStructuredDiagnosisElement($foundHeartDiseases, "HeartDisease", "structured", "visit", $contentNodeDate)
  )
  let $structuredProblemsHDElements :=
  (
    let $problems := $vpr/va:results/va:problems/va:problem
    for $problem in $problems
      let $icd := $problem/va:icd
      let $foundHeartDiseases := local:getDiagnosesFromCode($problem/va:icd, $heartDiseaseCodes)
      let $contentNodeDate := local:getDateFromVprDateString($problem/va:entered)
      return local:createStructuredDiagnosisElement($foundHeartDiseases, "HeartDisease", "structured", "problem", $contentNodeDate)
  )
  return
    if ( $unstructuredHDElements or $structuredPatientTreatmentHDElements or
         $structuredVisitsHDElements or $structuredProblemsHDElements) then
      for $el in ($unstructuredHDElements, $structuredPatientTreatmentHDElements, $structuredVisitsHDElements, $structuredProblemsHDElements)
      order by $el/@referenceDate
      return $el
    else ()
};

let $vpr := doc($URI)/va:vpr
let $diagnosisElements := local:createDiagnosisElements($vpr)
(: let $_ := local:addDiagnosesToPatient($vpr, $diagnosisElements) :)
let $_ := enrich:add-replace-events($vpr, $diagnosisElements )
return $URI;

(: 2nd transaction:)
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
let $_ := util:add-enrichment-indicator($vpr, xs:QName('enr:patient-Event-Diagnoses-List-Enrichment'))
return $URI