(:-------------------------------------------:)
(: Transaction 1 - delete existing container nodes for this patient :)
(:-------------------------------------------:)
xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";

declare variable $URI as xs:string external;

declare function local:deleteTreatmentEnrichmentContainerNode($vpr)
{
    let $patientTreatments := $vpr/va:results/va:patientTreatments
    let $treatments := $patientTreatments/va:treatments
    return
        if ($treatments) then
            xdmp:node-delete($treatments)
        else ()
};

declare function local:deleteHighLevelPsychClassesEnrichmentContainerNode($vpr)
{
    let $patientTreatments := $vpr/va:results/va:patientTreatments
    let $highLevelPsychClasses := $patientTreatments/va:highLevelPsychClasses
    return
        if ($highLevelPsychClasses) then
            xdmp:node-delete($highLevelPsychClasses)
        else ()
};

let $vpr := doc($URI)/va:vpr
let $_ := local:deleteTreatmentEnrichmentContainerNode($vpr)
let $_ := local:deleteHighLevelPsychClassesEnrichmentContainerNode($vpr)
return $URI;

(:-------------------------------------------:)
(: Transaction 2 - add container nodes  :)
(:-------------------------------------------:)
xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";

declare variable $URI as xs:string external;

declare function local:prepareTreatmentEnrichmentContainerNode($vpr)
{
    let $patientTreatments := $vpr/va:results/va:patientTreatments
    let $treatments := $patientTreatments/va:treatments
    return
        if ($treatments) then ()
        else xdmp:node-insert-child($patientTreatments, element va:treatments { })
};

declare function local:prepareHighLevelPsychClassesEnrichmentContainerNode($vpr)
{
    let $patientTreatments := $vpr/va:results/va:patientTreatments
    let $highLevelPsychClasses := $patientTreatments/va:highLevelPsychClasses
    return
        if ($highLevelPsychClasses) then ()
        else xdmp:node-insert-child($patientTreatments, element va:highLevelPsychClasses { })
};

let $vpr := doc($URI)/va:vpr
let $_ := local:prepareTreatmentEnrichmentContainerNode($vpr)
let $_ := local:prepareHighLevelPsychClassesEnrichmentContainerNode($vpr)
return $URI;

(:-----------------------------------------------------------------------------:)
(: Transaction 3 - add elements to the container nodes that were added in transaction 2 :)
(:-----------------------------------------------------------------------------:)
xquery version "1.0-ml";
declare namespace va = "ns://va.gov/2012/ip401";
import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare variable $URI as xs:string external;

declare function local:addNewEnrichment($vpr, $targetFacetNode, $facetText, $enrichmentNodeNamespace, $enrichmentNodeName, $enrichmentContainer)
{
  let $targetNodeIsYes := local:isTargetNodeYes($vpr, $targetFacetNode)
  return
    if ($targetNodeIsYes) then
      let $enrichmentContainerStmt := concat('results/patientTreatments/',$enrichmentContainer)
      let $enrichmentContainer := functx:dynamic-path($vpr, $enrichmentContainerStmt)
      let $enrichmentNodeStmt := concat('results/patientTreatments/',$enrichmentContainer,'/',$enrichmentNodeName)
      let $enrichmentNodes := functx:dynamic-path($vpr, $enrichmentNodeStmt)
      let $nodeToBeAdded := element { concat($enrichmentNodeNamespace, ':', $enrichmentNodeName) } { $facetText }
      let $exists := functx:is-node-in-sequence-deep-equal($nodeToBeAdded, $enrichmentNodes)
      return
        if(not($exists)) then
          xdmp:node-insert-child($enrichmentContainer, $nodeToBeAdded )
        else ()
    else ()
};

declare function local:isTargetNodeYes($vpr, $facetNode)
{
    let $statement := concat("results/patientTreatments/patientTreatment/",$facetNode)
    let $nodeResults := functx:dynamic-path($vpr, $statement)
    return
      if($nodeResults) then
        let $yesResults := $nodeResults/upper-case(text()) = 'YES'
        return
          if ($yesResults) then true()
          else false()
      else false()
};

declare function local:getPsychText($patientTreatment, $targetFacetNode)
{
  let $psychClass := $patientTreatment/va:highLevelPsychClass/number(text())
  return
    if ($psychClass) then
      if(($psychClass gt 0) and ($psychClass le 10)) then
        "Persistent danger of severely hurting self or others"
      else if(($psychClass gt 10) and ($psychClass le 20)) then
        "Danger to self or others, fails to maintain minimal hygiene"
      else if(($psychClass gt 20) and ($psychClass le 30)) then
        "Danger to self or others, fails to maintain hygiene"
      else if(($psychClass gt 30) and ($psychClass le 40)) then
        "Major impairment in several areas"
      else if(($psychClass gt 40) and ($psychClass le 50)) then
        "Serious symptoms"
      else if(($psychClass gt 50) and ($psychClass le 60)) then
        "Moderate symptoms"
      else if(($psychClass gt 60) and ($psychClass le 70)) then
        "Mild symptoms"
      else if(($psychClass gt 70) and ($psychClass le 80)) then
        "Transient and expectable reactions to psychosocial stressors"
      else if(($psychClass gt 80) and ($psychClass le 90)) then
        "Absent or minimal symptoms"
      else ()
    else ()
};

declare function local:addPsychClassEnrichment($vpr, $targetFacetNode, $enrichmentNodeNamespace, $enrichmentNodeName, $enrichmentContainer)
{
  let $patientTreatments := $vpr/va:results/va:patientTreatments/va:patientTreatment
  for $patientTreatment in $patientTreatments
  return
    let $enrichmentText := local:getPsychText($patientTreatment, $targetFacetNode)
    return
      if ($enrichmentText) then
        let $enrichmentContainerStmt := concat('results/patientTreatments/',$enrichmentContainer)
        let $enrichmentContainer := functx:dynamic-path($vpr, $enrichmentContainerStmt)
        let $enrichmentNodeStmt := concat('results/patientTreatments/',$enrichmentContainer,'/',$enrichmentNodeName)
        let $enrichmentNodes := functx:dynamic-path($vpr, $enrichmentNodeStmt)
        let $nodeToBeAdded := element { concat($enrichmentNodeNamespace, ':', $enrichmentNodeName) } { $enrichmentText }
        let $exists := functx:is-node-in-sequence-deep-equal($nodeToBeAdded, $enrichmentNodes)
        return
          if(not($exists)) then
            xdmp:node-insert-child($enrichmentContainer, $nodeToBeAdded )
          else ()
      else ()
};

declare function local:addTreatmentEnrichmentNodes($vpr)
{
  let $patientTreatments := $vpr/va:results/va:patientTreatments
  let $treatments := $patientTreatments/va:treatments
  return
  (
    (: http://livevista.caregraf.info/schema#!46 :)
    local:addNewEnrichment($vpr, "treatedForScCondition", "Service Connected Condition", "va", "treatment", "treatments"),
    (: http://livevista.caregraf.info/schema#!46 :)
    local:addNewEnrichment($vpr, "treatedForAoCondition", "Agent Orange Condition", "va", "treatment", "treatments"),
    (: http://livevista.caregraf.info/schema#!46 :)
    local:addNewEnrichment($vpr, "treatedForIrCondition", "Ionizing Radiation Condition", "va", "treatment", "treatments"),
    (: http://livevista.caregraf.info/9_2-1183 :)
    local:addNewEnrichment($vpr, "exposedToSwAsiaConditions", "Exposed To Southwest Asian Conditions", "va", "treatment", "treatments"),
    (: http://livevista.caregraf.info/schema#!46 :)
    local:addNewEnrichment($vpr, "treatmentForMst", "Military Sexual Trauma", "va", "treatment", "treatments"),
    (: http://livevista.caregraf.info/schema#!46 :)
    local:addNewEnrichment($vpr, "treatmentForHeadNeckCa", "Head/Neck Cancer", "va", "treatment", "treatments"),
    local:addNewEnrichment($vpr, "treatmentForShad", "Shipboard Hazard and Defense", "va", "treatment", "treatments"),
    local:addNewEnrichment($vpr, "legionnaire_sDisease", "Legionnaires Disease", "va", "treatment", "treatments")
  )
};


declare function  local:addMentalHealthEnrichmentNodes($vpr)
{
  local:addPsychClassEnrichment($vpr, "highLevelPsychClass", "va", "highLevelPsychClassInd", "highLevelPsychClasses")
};

let $vpr := doc($URI)/va:vpr
let $_ := local:addMentalHealthEnrichmentNodes($vpr)
let $_ := local:addTreatmentEnrichmentNodes($vpr)
let $_ := util:add-enrichment-indicator($vpr, xs:QName('va:patientIndicatorsEnrichment'))
return $URI