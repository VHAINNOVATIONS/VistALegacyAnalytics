xquery version "1.0-ml";

declare default element namespace "http://www.w3.org/1999/xhtml" ;
declare namespace enr = "ns://va.gov/2012/ip401/enrichment";

import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";
import module namespace m = "ns://va.gov/2012/ip401/patient" at "/app/models/patient-lib.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology" at "/lib/ontology.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

declare variable $patient := vh:get("patient");

declare function local:getPatientAddressLineOne()
{
    let $address := $patient/va:results/va:demographics/va:patient/va:address
    let $street := (
      if(empty($address/va:streetLine1)) then
        '<not recorded>'
      else
        $address/va:streetLine1
    )
    return $street
};

declare function local:getAddressLineTwo($addressParent)
{
    let $address := ($addressParent/va:address)[1]
    let $stateProvince := (
      if(empty($address/va:stateProvince)) then
        '<not recorded>'
      else
        $address/va:stateProvince
    )
    let $postalCode := (
      if(empty($address/va:postalCode)) then
        '<not recorded>'
      else
        $address/va:postalCode
    )
    let $city := (
      if(empty($address/va:city)) then
        '<not recorded>'
      else
        $address/va:city
    )
    let $patientAddress := concat($city,', ',$stateProvince,'  ',$postalCode)
    return $patientAddress
};


declare function local:getPatientSex()
{
    let $gender := $patient/va:results/va:demographics/va:patient/va:gender
    return
        if ( $gender ) then
            if ( $gender = 'M' or $gender = 'm' ) then
                "MALE"
            else
                "FEMALE"
        else
            '<not recorded>'
};

declare function local:getPatientReligion()
{
  let $patientReligion := $patient/va:results/va:demographics/va:patient/va:religion
  return
    if(not($patientReligion)) then
      '<not recorded>'
    else
      let $religions := map:map()
      (: mapped based on https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=4&ved=0CDkQFjAD&url=http%3A%2F%2Fwww.va.gov%2FVDL%2Fdocuments%2FClinical%2FPatient_Record_Flags%2Fprfhl7is.doc&ei=uTQ7UuG2COHl4AOf6YD4AQ&usg=AFQjCNFPW_b_1vJt8Bc_liV7w-5kVC4zwQ&bvm=bv.52288139,d.dmg  :)
      let $_ :=
      (
        map:put($religions, "0", "CATHOLIC"),
        map:put($religions, "1", "JEWISH"),
        map:put($religions, "2", "EASTERN ORTHODOX"),
        map:put($religions, "3", "BAPTIST"),
        map:put($religions, "4", "METHODIST"),
        map:put($religions, "5", "LUTHERAN"),
        map:put($religions, "6", "PRESBYTERIAN"),
        map:put($religions, "7", "UNITED CHURCH OF CHRIST"),
        map:put($religions, "8", "EPISCOPALIAN"),
        map:put($religions, "9", "ADVENTIST"),
        map:put($religions, "10", "ASSEMBLY OF GOD"),
        map:put($religions, "11", "BRETHREN"),
        map:put($religions, "12", "CHRISTIAN SCIENTIST"),
        map:put($religions, "13", "CHURCH OF CHRIST"),
        map:put($religions, "14", "CHURCH OF GOD"),
        map:put($religions, "15", "DISCIPLES OF CHRIST"),
        map:put($religions, "16", "EVANGELICAL COVENANT"),
        map:put($religions, "17", "FRIENDS"),
        map:put($religions, "18", "JEHOVAH'S WITNESS"),
        map:put($religions, "19", "LATTER-DAY SAINTS"),
        map:put($religions, "20", "ISLAM"),
        map:put($religions, "21", "NAZARENE"),
        map:put($religions, "22", "OTHER"),
        map:put($religions, "23", "PENTECOSTAL"),
        map:put($religions, "24", "PROTESTANT, OTHER"),
        map:put($religions, "25", "PROTESTANT, NO DENOMINATION"),
        map:put($religions, "26", "REFORMED"),
        map:put($religions, "27", "SALVATION ARMY"),
        map:put($religions, "28", "UNITARIAN; UNIVERSALIST"),
        map:put($religions, "29", "UNKNOWN/NO PREFERENCE"),
        map:put($religions, "30", "NATIVE AMERICAN"),
        map:put($religions, "31", "BUDDHIST")
      )
      let $resolvedReligion := map:get($religions, $patientReligion)
      return
        if($resolvedReligion) then
          $resolvedReligion
        else
          concat('Did not resolve to text description, the religion code was: ', $patientReligion)
};

declare function local:getMaritalStatus()
{
    let $maritalStatus := $patient/va:results/va:demographics/va:patient/va:maritalStatus
    return
        (:mappings per: http://livevista.caregraf.info/schema#!11 :)
        if ( $maritalStatus ) then
            if ( $maritalStatus = 'D' or $maritalStatus = 'd' ) then
                "DIVORCED"
            else if ( $maritalStatus = 'M' or $maritalStatus = 'm' ) then
                "MARRIED"
            else if ( $maritalStatus = 'N' or $maritalStatus = 'n' ) then
                "NEVER MARRIED"
            else if ( $maritalStatus = 'S' or $maritalStatus = 's' ) then
                "SEPERATED"
            else if ( $maritalStatus = 'U' or $maritalStatus = 'u' ) then
                "UNKNOWN"
            else if ( $maritalStatus = 'W' or $maritalStatus = 'w' ) then
                "WIDOW/WIDOWER"
            else
                $maritalStatus
        else
            '<not recorded>'
};

declare function local:getPatientAge()
{
  let $dob := $patient/va:results/va:demographics/va:patient/va:dob
  return
    if($dob) then
      let $currentDateTime := current-dateTime()
      let $dob :=  util:convert-vpr-date($dob)
      let $age := util:get-approx-age-at-date($currentDateTime, $dob)
      return concat($age)
    else
        '<not recorded>'
};

declare function local:bulidDisabilitiesTable()
{
  let $disabilities := $patient/va:results/va:demographics/va:patient/va:disabilities/va:disability
  let $tablecontent := (
    for $disability in $disabilities
      let $disabilityRow :=
        <tr>
          <td>
            <span class="fieldText">{$disability/va:printName}</span>
          </td>
          <td>
            <div>&nbsp;&nbsp;&nbsp;</div>
          </td>
          <td>
              {local:getDisability-sc-div($disability)}
          </td>
        </tr>
      return $disabilityRow
  )
  return
    if( $disabilities ) then
       <table>{$tablecontent}</table>
    else
      <table><tr><td>No data available</td></tr></table>
};

declare function local:getDisability-sc-div($disability)
{
    if ($disability/va:scPercent) then
        <div>
            <span class="fieldText">{concat($disability/va:scPercent,'%')}</span>
            <span>&nbsp;&nbsp;&nbsp;</span>
            <span class="fieldText">S/C</span>
        </div>
    else
        '<not recorded>'
};


declare function local:convertToDisplayDate($date)
{
  if($date) then
    let $position := functx:index-of-string($date, "T")
    let $convertedDate := (
      if ( $position ) then
        xs:date(substring($date, 0, $position))
      else
        xs:date($date)
     )
     let $tokens := tokenize(xs:string($convertedDate), '-')
     return concat($tokens[2],'/',$tokens[3],'/',$tokens[1])
  else
    '<not recorded>'
};

declare function local:discharge-admission-report($patientTreatments)
{
    if ($patientTreatments) then
      for $patientTreatment in $patientTreatments
      order by $patientTreatment/va:admissionDate descending
      return
        let $convertedAdmissionDate := local:convertToDisplayDate($patientTreatment/va:admissionDate/text() )
        let $convertedDischargeDate := local:convertToDisplayDate($patientTreatment/va:dischargeDate/text() )
        let $dates :=
            <tr>
                <td style='colspan=2; padding-bottom: 0.5em;'>
                    <div><span class="fieldText">{$convertedAdmissionDate} - {$convertedDischargeDate}</span></div>
                </td>
            </tr>
        let $lastTrSpecialty :=
            <tr>
                <td>
                    <span class="ad-fieldLabel">Last Tr Specialty:</span>
                </td>
                <td>
                    <span class="fieldText">{local:getNonFormattedPatientValue($patientTreatment/va:dischargeSpecialty)}</span>
                </td>
            </tr>
        let $lastProv :=
            <tr>
                <td>
                    <span class="ad-fieldLabel">Last Prov:</span>
                </td>
                <td>
                    <span class="ad-fieldText">{local:getNonFormattedPatientValue($patientTreatment/va:provider)}</span>
                </td>
            </tr>
        let $dxls :=
            <tr>
                <td>
                    <span class="ad-fieldLabel">DXLS:</span>
                </td>
                <td>
                    <table>
                        <tr>
                            <td style='text-align: left; width:350px;'>
                                <span class="ad-fieldText">{ local:getNonFormattedPatientValue(on:get-concept-by-code($patientTreatment/va:principalDiagnosis)/on:concept/@short-description/string())}</span>
                             </td>
                             <td style='text-align: left; padding: 0px 0px 0px 9px;'>
                                <span class="ad-fieldText">{local:getNonFormattedPatientValue($patientTreatment/va:principalDiagnosis)}</span>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>
        let $icdList := $patientTreatment/va:fld501/va:movementRecord/(va:icd | va:icd1 | va:icd2 | va:icd3 | va:icd4 | va:icd5 | va:icd6 | va:icd7 | va:icd8 | va:icd9 | va:icd10)
        let $icdDistinctList := distinct-values($icdList)
        let $icd-table := local:build-icd-table($icdDistinctList)
        let $returnLine := <table><tr><td><div>&nbsp;</div></td></tr></table>
        return <table id="admissionsDischargeData">{$dates} {$lastTrSpecialty } {$lastProv} {$dxls} {$icd-table} {$returnLine}</table>
    else
        <table><tr><td>No data available</td></tr></table>
};

declare function local:discharge-diagnosis-report($patientTreatments)
{
  if ($patientTreatments) then
      for $patientTreatment in $patientTreatments
      order by $patientTreatment/va:admissionDate descending
      return
        let $convertedAdmissionDate := local:convertToDisplayDate($patientTreatment/va:admissionDate/text() )
        let $convertedDischargeDate := local:convertToDisplayDate($patientTreatment/va:dischargeDate/text() )
        let $dates :=
            <tr>
                <td style='colspan=2; padding-bottom: 0.5em;'>
                    <div><span class="fieldText">{$convertedAdmissionDate} - {$convertedDischargeDate}</span></div>
                </td>
            </tr>
        let $dxls :=
            <tr>
                <td>
                    <span class="ad-fieldLabel">DXLS:</span>
                </td>
                <td>
                    <table>
                        <tr>
                            <td style='text-align: left; width:350px;'>
                                <span class="ad-fieldText">{ local:getNonFormattedPatientValue(on:get-concept-by-code($patientTreatment/va:principalDiagnosis)/on:concept/@short-description/string())}</span>
                             </td>
                             <td style='text-align: left; padding: 0px 0px 0px 9px;'>
                                <span class="ad-fieldText">{local:getNonFormattedPatientValue($patientTreatment/va:principalDiagnosis)}</span>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>
        let $icdList := $patientTreatment/va:fld501/va:movementRecord/(va:icd | va:icd1 | va:icd2 | va:icd3 | va:icd4 | va:icd5 | va:icd6 | va:icd7 | va:icd8 | va:icd9 | va:icd10)
        let $icdDistinctList := distinct-values($icdList)
        let $icd-table := local:build-icd-table($icdDistinctList)
        let $returnLine := <table><tr><td><div>&nbsp;</div></td></tr></table>
        return <table id="admissionsDischargeData">{$dates} {$dxls} {$icd-table} {$returnLine}</table>
    else
       <table><tr><td>No data available</td></tr></table>

};

declare function local:build-icd-table($icdList)
{
    if ($icdList) then
        <tr>
           <td>
                <div><span class="ad-fieldLabel">ICD DX:</span></div>
                {
                    let $iterationList := remove($icdList, 1)
                    for $icd in $iterationList
                        return
                            if($icd = "" ) then ()
                            else
                                <div>&nbsp;</div>
                }
            </td>
            <td>
                { local:build-icd-table-inner($icdList) }
           </td>
        </tr>
    else ()
};

declare function local:build-icd-table-inner($icdList)
{
    let $rows := (
        for $icd in $icdList
          return
            if($icd = "") then ()
            else
                <tr>
                    <td style='text-align: left;  width:350px;'>
                        <span >{ on:get-concept-by-code($icd)/on:concept/@short-description/string() }</span>
                    </td>
                    <td style='text-align: left; padding: 0px 0px 0px 9px;'>
                        <span>{ $icd }</span>
                    </td>
                </tr>
    )
    return <table> {$rows} </table>
};

declare function local:getNonFormattedPatientValue($value)
{
    if ( $value ) then
        $value
    else
        '<not recorded>'
};

let $placeholder := ""
return
(
<link rel="stylesheet" type="text/css" href="/css/patient.css"/>,
<div style="width:100%;">
    <div style="margin-left:auto; margin-right:auto;width:70%;border: 1px solid black;">
        <p style="padding: 0px 5px 0px 5px;">
            Note: This page is under development and has been implemented using
            information recently provided.  Four sections from the CPRS Health
            Summary report are represented on this page.  Not every field found on the
            CPRS Health Summary report is currently represented here.
        </p>
    </div>
</div>,
<div>&nbsp;</div>,
<div id="table">
    <div class="row">
        <span class="cell" >
            <div id="demographics_container">
                <table>
                    <tr>
                        <td>
                            <span class="reportHeader">DEM - Demographics</span>
                        </td>
                    </tr>
                    <tr>
                        <table id="demographics_data">
                            <tr>
                                <td><div>&nbsp;</div></td>
                            </tr>
                            <tr>
                                <td>
                                    <div><span class="demographicsFieldLabel">Address:</span></div>
                                    <div>&nbsp;</div>
                                </td>
                                <td>
                                    <div><span class="fieldText">{local:getPatientAddressLineOne()}</span></div>
                                    <div><span class="fieldText">
                                        {local:getAddressLineTwo($patient/va:results/va:demographics/va:patient)}
                                   </span></div>
                                </td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">Phone:</span></td>
                                <td><span class="fieldText">
                                    { local:getNonFormattedPatientValue(($patient/va:results/va:demographics/va:patient/va:telecomList[1]/va:telecom)[1]/va:value) }
                                 </span></td>
                            </tr>
                            <tr>
                                <td><div>&nbsp;</div></td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">Age:</span></td>
                                <td><span class="fieldText">{local:getPatientAge()}</span></td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">Sex:</span></td>
                                <td><span class="fieldText">{ local:getPatientSex() } </span></td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">Marital Status:</span></td>
                                <td><span class="fieldText">{local:getMaritalStatus()}</span></td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">Religion:</span></td>
                                <td><span class="fieldText">{local:getPatientReligion()}</span></td>
                            </tr>
                            <tr>
                                <td><span class="demographicsFieldLabel">S/C%:</span></td>
                                <td><span class="fieldText">
                                    {local:getNonFormattedPatientValue($patient/va:results/va:demographics/va:patient/va:scPercent)}
                                </span></td>
                            </tr>
                            <tr>
                                <td><div>&nbsp;</div></td>
                            </tr>
                            <tr>
                                <td>
                                    <div><span class="demographicsFieldLabel">Primary NOK:</span></div>
                                    <div>&nbsp;</div>
                                    <div>&nbsp;</div>
                                </td>
                                <td>
                                    <div><span class="fieldText">
                                        {local:getNonFormattedPatientValue(($patient/va:results/va:demographics/va:patient/va:supports/va:support[@contactType='NOK'])[1]/va:support-name)}
                                    </span></div>
                                    <div><span class="fieldText">
                                        {local:getNonFormattedPatientValue(($patient/va:results/va:demographics/va:patient/va:supports/va:support[@contactType='NOK'])[1]/va:address/va:streetLine1)}
                                    </span></div>
                                    <div><span class="fieldText">
                                        {local:getAddressLineTwo(($patient/va:results/va:demographics/va:patient/va:supports/va:support[@contactType='NOK'])[1])}
                                    </span></div>
                                </td>
                                <td>
                                    <div><span class="demographicsFieldLabel">Relation:</span></div>
                                    <div><span class="demographicsFieldLabel">Phone:</span></div>
                                    <div>&nbsp;</div>
                                </td>
                                <td>
                                    <div><span class="fieldText">
                                        {local:getNonFormattedPatientValue(($patient/va:results/va:demographics/va:patient/va:supports/va:support[@contactType='NOK'])[1]/va:relationship)}
                                    </span></div>
                                    <div><span class="fieldText">
                                    {local:getNonFormattedPatientValue(($patient/va:results/va:demographics/va:patient/va:supports/va:support[@contactType='NOK'])[1]/va:telecomList/va:telecom[1]/va:value)}
                                    </span></div>
                                    <div>&nbsp;</div>
                                </td>
                            </tr>

                        </table>
                    </tr>
                </table>
            </div>
        </span>
    </div>

    <div class="row">
        <span class="cell" >
            <div id="disabilities_container">
                <table>
                    <tr>
                        <td>
                            <span class="reportHeader">DS - Disabilities</span>
                        </td>
                    </tr>
                    <tr>
                        <table id="disabilities_data">
                            <tr>
                                <td><div>&nbsp;</div></td>
                            </tr>
                            <tr>
                                <td>
                                    <span class="fieldLabel">Total S/C %:</span>
                                </td>
                                <td><div>&nbsp;</div></td>
                                <td>
                                    <div><span class="fieldText">
                                        {local:getNonFormattedPatientValue($patient/va:results/va:demographics/va:patient/va:scPercent)}
                                    </span></div>
                                </td>
                            </tr>
                        </table>
                    </tr>
                    <tr>
                        <td>
                            <div>&nbsp;</div>
                        </td>
                    </tr>
                    <tr>
                        { local:bulidDisabilitiesTable() }
                    </tr>
                </table>
            </div>
        </span>
    </div>

    <div class="row">
        <span class="cell" >
            <div id="adc_admission_discharge_container">
                <table>
                    <tr>
                        <td>
                            <span class="reportHeader">ADC - Admission/Discharge</span>
                        </td>
                    </tr>
                    <tr>
                        <td><div>&nbsp;</div></td>
                    </tr>
                    <tr>
                        <td>
                        {
                            local:discharge-admission-report($patient/va:results/va:patientTreatments/va:patientTreatment)
                        }
                        </td>
                    </tr>
                </table>
            </div>
        </span>
    </div>

    <div class="row">
        <span class="cell" >
            <div id="dd_discharge_diagnosis_container">
                <table>
                    <tr>
                        <td>
                            <span class="reportHeader">DD - Discharge Diagnosis</span>
                        </td>
                    </tr>
                    <tr>
                        <td>
                        {
                            local:discharge-diagnosis-report($patient/va:results/va:patientTreatments/va:patientTreatment)
                        }
                        </td>
                    </tr>
                </table>
            </div>
        </span>
    </div>
</div>
)

