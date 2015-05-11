xquery version "1.0-ml";
(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

module namespace c = "http://marklogic.com/roxy/config";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace geo="http://marklogic.com/geocode" ;
declare namespace rest = "http://marklogic.com/appservices/rest";

declare namespace va = "ns://va.gov/2012/ip401" ;
declare namespace site="ns://va.gov/2012/ip401/sites" ;

import module namespace def = "http://marklogic.com/roxy/defaults"
  at "/roxy/config/defaults.xqy";

import module namespace search="http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

import module namespace facet = "http://marklogic.com/roxy/facet-lib"
  at "/app/views/helpers/facet-lib.xqy";

import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";
import module namespace vpr = "ns://va.gov/2012/ip401/vpr"
  at "/lib/vpr.xqy";

(: Pass-through mechanism so roxy can tell us the environment name.
 : Unlike roxy variable substitution, this works in XQuery
 : even when using filesystem modules.
 : Note that this returns empty if run in cq, qconsole, etc.
 :)
declare variable $c:ENVIRONMENT := try {
  substring-after(
    namespace-uri-from-QName(xs:QName('_roxy_environment'||':x')),
    'ns://va.gov/2012/ip401/properties/environment/') }
catch ($ex) {
  if (not($ex/error:code = (
        'XDMP-CAST', 'XDMP-UNBPRFX'))) then xdmp:rethrow()
  (: Either that or we are running in cq or qconsole. :)
  else 'NEEDS-BOOTSTRAP' } ;

declare variable $LOGGED-IN-PRIVILEGE := 'ns://va.gov/2012/ip401/logged-in' ;

(:
 : ***********************************************
 : Overrides for the Default Roxy control options
 :
 : See /roxy/config/defaults.xqy for the complete list of stuff that you can override.
 : Roxy will check this file (config.xqy) first. If no overrides are provided then it will use the defaults.
 :
 : Go to https://github.com/marklogic/roxy/wiki/Overriding-Roxy-Options for more details
 :
 : ***********************************************
 :)
declare variable $ROXY-OPTIONS :=
  <options>
    <layouts>
      <layout format="html">two-column</layout>
    </layouts>
  </options>;

(:
 : ***********************************************
 : Overrides for the Default Roxy scheme
 :
 : See /roxy/config/defaults.xqy for the default routes
 : Roxy will check this file (config.xqy) first. If no overrides are provided then it will use the defaults.
 :
 : Go to https://github.com/marklogic/roxy/wiki/Roxy-URL-Rewriting for more details
 :
 : ***********************************************
 :)
declare variable $ROXY-ROUTES :=
  <routes xmlns="http://marklogic.com/appservices/rest">
    <!-- protect root -->
    <protect uri="^/+$" redirect="/user/login">
      <privilege>{ $LOGGED-IN-PRIVILEGE }</privilege>
      <uri-param name="redirect-to">/</uri-param>
    </protect>
    <!-- protect user profile -->
    <protect uri="^(/user/profile(/.*)?)$" redirect="/user/login">
      <privilege>{ $LOGGED-IN-PRIVILEGE }</privilege>
      <uri-param name="redirect-to">$1</uri-param>
    </protect>
    <!-- protect search-driven views  -->
    <protect uri="^(/(app|map|records|reports|analyze)(/.*)?)$" redirect="/user/login">
      <privilege>{ $LOGGED-IN-PRIVILEGE }</privilege>
      <uri-param name="redirect-to">$1</uri-param>
    </protect>
    <request uri="^/app/views/.*" />
    <request uri="^/analyze.*$" endpoint="/roxy/query-router.xqy">
      <uri-param name="controller">appbuilder</uri-param>
      <uri-param name="func">analyze</uri-param>
      <uri-param name="format">html</uri-param>
      <http method="GET"/>
    </request>
    <request uri="^/records/([a-zA-Z0-9]*)$" endpoint="/roxy/query-router.xqy">
        <uri-param name="controller">appbuilder</uri-param>
        <uri-param name="func">patient</uri-param>
        <uri-param name="format">html</uri-param>
        <uri-param name="id">$1</uri-param>
        <uri-param name="site">$2</uri-param>
        <http method="GET"/>
      </request>
    {
      $def:ROXY-ROUTES/rest:request
    }
  </routes>;

(:
 : ***********************************************
 : A decent place to put your appservices search config
 : and various other search options.
 : The examples below are used by the appbuilder style
 : default application.
 : ***********************************************
 :)
declare variable $DEFAULT-PAGE-LENGTH as xs:int := 10;

(: The initial list of facets displayed to the user :)
declare variable $DEFAULT-FACETS := 
  "addr", "allergies", "birthdecade"
;

(: These facets are used to support features using facets other than the main facet list on the left.  These facets should be included
 with the selected facets on the left :)
declare variable $SYSTEM-FACETS :=
    "diag-date", 'saved-search', 'facility-loc', 'concept'
;

(:
 : As of 6.0-2 the path-index namespaces seem to be very picky
 : about where they are declared.
 :
 : These options may be rewritten by cfg:search-options, defined below.
 :)
declare variable $SEARCH-OPTIONS := (
  <options xmlns="http://marklogic.com/appservices/search">

    <!-- additional-query is added by cfg:search-options -->
    <!-- return-results is added by cfg:search-options -->

    <return-query>true</return-query>
    <search-option>unfiltered</search-option>
    <term>
      <term-option>case-insensitive</term-option>
    </term>

    <grammar>
      <quotation>&quot;</quotation>
      <implicit>
        <cts:and-query strength="20" xmlns:cts="http://marklogic.com/cts"/>
      </implicit>
      <starter strength="30" apply="grouping" delimiter=")">&#40;</starter>
      <starter strength="40" apply="prefix" element="cts:not-query">NOT</starter>
      <joiner strength="10" apply="infix" element="cts:or-query" tokenize="word">OR</joiner>
      <joiner strength="20" apply="infix" element="cts:and-query" tokenize="word">AND</joiner>
      <joiner strength="40" apply="infix" element="cts:near-query" tokenize="word">NEAR</joiner>
      <joiner strength="50" apply="constraint">:</joiner>
      <joiner strength="50" apply="constraint" tokenize="word">GT</joiner>
      <joiner strength="50" apply="constraint" tokenize="word">LT</joiner>
    </grammar>

    <!--
  TODO needs more work
  rough syntax:
  addr:"@100 14.3446,28.7504"
  This matches va:address elements with 100-mi of the lat-lon point.
  addr:"[45, -122, 78, 30]"
  This matches va:address elements within the described lat-lon box.

  The initial heatmap covers the whole planet.
    -->
    <constraint name="addr">
      <geo-attr-pair facet="false">
        <heatmap n="90" s="-90" e="180" w="-180" latdivs="64" londivs="64"/>
        <parent ns="ns://va.gov/2012/ip401" name="address"/>
        <lat ns="http://marklogic.com/geocode" name="lat"/>
        <lon ns="http://marklogic.com/geocode" name="lon"/>
      </geo-attr-pair>
    </constraint>

    <constraint name="allergies" xmlns:va="ns://va.gov/2012/ip401">
      <range type="xs:string" facet="true"
         collation="http://marklogic.com/collation/codepoint">
        <facet-option>limit=10</facet-option>
        <path-index>/va:vpr/va:results/va:reactions/va:allergy/va:drugIngredients/va:drugIngredient/va:drugIngredient-name</path-index>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="birthdecade" xmlns:va="ns://va.gov/2012/ip401">
      <range type="xs:int" facet="true">
        <path-index>/va:vpr/va:results/va:demographics/va:patient/va:dob</path-index>
        <bucket name="1930s" lt="2400000" ge="2300000">1930s</bucket>
        <bucket name="1940s" lt="2500000" ge="2400000">1940s</bucket>
        <bucket name="1950s" lt="2600000" ge="2500000">1950s</bucket>
        <bucket name="1960s" lt="2700000" ge="2600000">1960s</bucket>
        <bucket name="1970s" lt="2800000" ge="2700000">1970s</bucket>
        <bucket name="1980s" lt="2900000" ge="2800000">1980s</bucket>
      </range>
    </constraint>

    <constraint name="concept">
      <custom facet="true">
        <parse apply="facet-concept-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-concept-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="concept-code">
      <range type="xs:string" facet="false">
        <element ns="{$on:NAMESPACE}" name="concept"/>
        <attribute ns="" name="code"/>
      </range>
    </constraint>

    <constraint name="content">
      <word>
        <element ns="ns://va.gov/2012/ip401" name="content"/>
      </word>
    </constraint>

    <constraint name="dateConstraint">
      <custom facet="false">
        <parse apply="parse-date" ns="ns://va.gov/2012/ip401/search-lib" at="/lib/search-lib.xqy"/>
      </custom>
    </constraint>

    <constraint name="diag">
      <custom facet="true">
        <parse apply="facet-diag-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-diag-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="diag-code">
      <range type="xs:string" facet="false">
        <facet-option>limit=10</facet-option>
        <element ns="{$in:NAMESPACE-VPR}" name="icd"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="diag-date">
      <custom facet="false">
        <parse apply="parse-diagnosis-date" ns="ns://va.gov/2012/ip401/search-lib" at="/lib/search-lib.xqy"/>
      </custom>
    </constraint>

    <constraint name="facility">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$in:NAMESPACE-VPR}" name="facility-name"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="facility-loc">
      <geo-attr-pair facet="false">
        <heatmap n="90" s="-90" e="180" w="-180" latdivs="64" londivs="64"/>
        <parent ns="ns://va.gov/2012/ip401" name="facility-location"/>
        <lat ns="http://marklogic.com/geocode" name="lat"/>
        <lon ns="http://marklogic.com/geocode" name="lon"/>
      </geo-attr-pair>
    </constraint>

    <constraint name="id">
      <range type="xs:string" facet="false">
        <path-index>/va:vpr/va:meta/va:id</path-index>
      </range>
    </constraint>

    <!-- structural references are va:class/@code, a VA drug class code.
      - unstructured are rx:class/@code, an rxnorm rxcui.
      - Both have @label which is 'code string'.
      -->
    <constraint name="vadc-code">
      <range type="xs:string" facet="false">
        <element ns="{$on:NAMESPACE-VPR}" name="class"/>
        <attribute ns="" name="code"/>
      </range>
    </constraint>

    <constraint name="vadc">
      <custom facet="true">
        <parse apply="facet-vadc-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-vadc-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="rxnorm-note-code">
      <range type="xs:string" facet="false">
        <element ns="{$on:NAMESPACE-RXNORM}" name="concept"/>
        <attribute ns="" name="code"/>
      </range>
    </constraint>

    <constraint name="rxnorm-note">
      <custom facet="true">
        <parse apply="facet-rxnorm-note-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-rxnorm-note-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="vadc-note-code">
      <range type="xs:string" facet="false">
        <element ns="{$on:NAMESPACE-RXNORM}" name="concept"/>
        <attribute ns="" name="vadc-code"/>
      </range>
    </constraint>

    <constraint name="vadc-note">
      <custom facet="true">
        <parse apply="facet-vadc-note-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-vadc-note-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="dea-schedule">
      <range type="xs:string" facet="true">
        <element ns="{$on:NAMESPACE-RXNORM}" name="concept"/>
        <attribute ns="" name="dea-schedule"/>
      </range>
    </constraint>

    <constraint name="loinc-code">
      <range type="xs:string" facet="false">
        <element ns="{$on:NAMESPACE-ENRICH}" name="concept"/>
        <attribute ns="" name="code"/>
      </range>
    </constraint>

    <constraint name="loinc">
      <custom facet="true">
        <parse apply="facet-loinc-parse" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <start-facet apply="facet-loinc-start" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <finish-facet apply="facet-finish-label" ns="{$on:NAMESPACE}" at="/lib/ontology.xqy" />
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="suicideIndicator">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$on:NAMESPACE-ENRICH}" name="suicideIndicator"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="suicideMedication">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$on:NAMESPACE-ENRICH}" name="suicideMedication"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="suicideIllicitDrug">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$on:NAMESPACE-ENRICH}" name="suicideIllicitDrug"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="normalizedProblem">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$on:NAMESPACE-ENRICH}" name="normalizedProblem"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="drinkingIndicator">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$on:NAMESPACE-ENRICH}" name="drinkingIndicator"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>
    <constraint name="site">
      <range type="xs:string" facet="true">
        <facet-option>limit=10</facet-option>
        <element ns="{$in:NAMESPACE-VPR}" name="site"/>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="treatments" xmlns:va="ns://va.gov/2012/ip401">
      <range type="xs:string" facet="true"
         collation="http://marklogic.com/collation/codepoint">
        <facet-option>limit=10</facet-option>
        <path-index>/va:vpr/va:results/va:patientTreatments/va:treatments/va:treatment</path-index>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="highLevelPsychClass" xmlns:va="ns://va.gov/2012/ip401">
      <range type="xs:string" facet="true"
         collation="http://marklogic.com/collation/codepoint">
        <facet-option>limit=10</facet-option>
        <path-index>/va:vpr/va:results/va:patientTreatments/va:highLevelPsychClasses/va:highLevelPsychClassInd</path-index>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>

    <constraint name="saved-search">
      <custom facet="false">
        <parse apply="search-parse" ns="http://marklogic.com/roxy/models/saved-search" at="/app/models/saved-search.xqy" />
      </custom>
    </constraint>

    <constraint name="psychiatryClassSeverity" xmlns:va="ns://va.gov/2012/ip401">
      <custom facet="true">
        <parse apply="facet-psychiatryClassSeverity-parse" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <start-facet apply="facet-start" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <finish-facet apply="facet-finish" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
          <path-index>/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:psychiatryClassSeverity</path-index>
        </range>
        <facet-start-value>!</facet-start-value>
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="substanceAbuse" xmlns:va="ns://va.gov/2012/ip401">
      <custom facet="true">
        <parse apply="facet-substanceAbuse-parse" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <start-facet apply="facet-start" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <finish-facet apply="facet-finish" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
          <path-index>/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:substanceAbuse</path-index>
        </range>
        <facet-start-value>!</facet-start-value>
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

    <constraint name="suicideSelfInflictIndicator" xmlns:va="ns://va.gov/2012/ip401">
      <custom facet="true">
        <parse apply="facet-suicideSelfInflictIndicator-parse" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <start-facet apply="facet-start" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <finish-facet apply="facet-finish" ns="{$facet:NAMESPACE}" at="/app/views/helpers/facet-lib.xqy" />
        <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
          <path-index>/va:vpr/va:results/va:patientTreatments/va:patientTreatment/va:suicideSelfInflictIndicator</path-index>
        </range>
        <facet-start-value>!</facet-start-value>
        <facet-option>limit=10</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </custom>
    </constraint>

  </options>) ;

(:
 : Labels are used by appbuilder faceting code to provide internationalization
 :)
declare variable $LABELS :=
  <labels xmlns="http://marklogic.com/xqutils/labels">
    <label key="allergies">
      <value xml:lang="en">Allergic Reactions</value>
    </label>
    <label key="psychiatryClassSeverity">
        <value xml:lang="en">Psychiatry Class Severity</value>
    </label>
    <label key="substanceAbuse">
        <value xml:lang="en">Substance Abuse</value>
    </label>
    <label key="suicideSelfInflictIndicator">
        <value xml:lang="en">Suicide Indicator</value>
    </label>
    <label key="treatments">
        <value xml:lang="en">Treatments</value>
    </label>
    <label key="highLevelPsychClass">
        <value xml:lang="en">High Level Psych Class</value>
    </label>
    <label key="birthdecade">
      <value xml:lang="en">Birth Years</value>
    </label>
    <label key="concept">
      <value xml:lang="en">Concepts</value>
    </label>
    <label key="diag">
      <value xml:lang="en">Diagnoses</value>
    </label>
    <label key="facility">
      <value xml:lang="en">Facility</value>
    </label>
    <label key="loinc">
      <value xml:lang="en">LOINC (notes)</value>
    </label>
    <label key="suicideIndicator">
        <value xml:lang="en">Suicide Indicator (notes)</value>
    </label>
    <label key="suicideMedication">
        <value xml:lang="en">Suicide Medication (notes)</value>
    </label>
    <label key="suicideIllicitDrug">
        <value xml:lang="en">Suicide Illicit Drug (notes)</value>
    </label>
    <label key="drinkingIndicator">
        <value xml:lang="en">Drinking Indicator (notes)</value>
    </label>
    <label key="normalizedProblem">
        <value xml:lang="en">Normalized Problem (notes)</value>
    </label>
    <label key="vadc">
      <value xml:lang="en">Prescription Class</value>
    </label>
    <label key="vadc-note">
      <value xml:lang="en">Prescription Class (notes)</value>
    </label>
    <label key="rxnorm-note">
      <value xml:lang="en">Prescription (notes)</value>
    </label>
    <label key="dea-schedule">
      <value xml:lang="en">DEA Schedule (notes)</value>
    </label>
    <label key="site">
      <value xml:lang="en">Sites</value>
    </label>
    <label key="source">
      <value xml:lang="en">Source</value>
    </label>
  </labels>;

declare variable $LABELS-GEO :=
  <labels xmlns="http://marklogic.com/xqutils/labels">
    <label key="addr">
      <value xml:lang="en">Patient Address</value>
    </label>
    <label key="facility-loc">
      <value xml:lang="en">Facility Location</value>
    </label>
  </labels>;

declare variable $REPORTS :=
<reports>
  <report id="coc" href="coc">Chain of Custody</report>
  <report id="vli" href="vli">VLI Counts</report>
  <report id="waaw" href="waaw">Term Context</report>
</reports>;

declare variable $AGE-RANGES :=
<ranges>
  <range>
    <min>20</min>
    <max>30</max>
  </range>
  <range>
    <min>31</min>
    <max>40</max>
  </range>
  <range>
    <min>41</min>
    <max>50</max>
  </range>
  <range>
    <min>51</min>
    <max>70</max>
  </range>
  <range>
    <min>71</min>
    <max>90</max>
  </range>
</ranges>;

(: Restrict search to mature data, for unfuddle #26 :)
declare variable $MATURE-SITES as xs:string* := $SITE-DATA/site:site[
  xs:boolean(@mature)]/@id ;

(: Site data for #26, #43 :)
declare variable $SITE-DATA := doc('/config/sites.xml')/site:site-data ;

declare variable $TABS-TOP :=
<tabset xmlns="http://marklogic.com/roxy/config">
  <tab href="/">Search</tab>
  <tab href="/reports/coc">Reports</tab>
  <tab href="/analytics">Analyze</tab>
</tabset> ;

(: Control which constraints are returned as facets.
 : Note that $c may be any constraint child element.
 :)
declare function c:constraint-rewrite(
  $name as xs:string,
  $c as element(),
  $facet-defaults as xs:boolean,
  $facets-extra as xs:string+,
  $corners-nsew as xs:double*)
as element()
{
  element { node-name($c) } {
    $c/@* ! (
      typeswitch(.)
      case attribute(facet) return ()
      default return .),
    (: Should this facet be included? :)
    attribute facet {
      ($facet-defaults and $c/@facet/xs:boolean(.))
      or $name = $facets-extra },
    if (empty($corners-nsew)
      or not(node-name($c) = (xs:QName('search:geo-attr-pair'))
        and ($c/@facet/xs:boolean(.) or $c/../@name = $facets-extra)))
    then $c/node()
    else (
      (: Rewrite heatmap corners as requested. :)
      $c/node() ! (
        typeswitch (.)
        case element(search:heatmap) return element search:heatmap {
          attribute n { $corners-nsew[1] },
          attribute s { $corners-nsew[2] },
          attribute e { $corners-nsew[3] },
          attribute w { $corners-nsew[4] },
          @*[not(local-name(.) = ('n', 's', 'e', 'w'))],
          node() }
        default return .)) }
};

declare function c:search-options(
  $mature-only as xs:boolean,
  $return-results as xs:boolean,
  $facet-defaults as xs:boolean,
  $facets-extra as xs:string*,
  $corners-nsew as xs:double*)
as element(search:options)
{
  if (empty($corners-nsew) or count($corners-nsew eq 4)) then ()
  else error((), 'UNEXPECTED', xdmp:describe($corners-nsew)),
  element search:options {
    $SEARCH-OPTIONS/@*,
    element search:additional-query {
      (: Restrict search to mature data, for unfuddle #26 :)
      vpr:site-query(
        if (not($mature-only)) then () else $MATURE-SITES) },
    element search:return-results { $return-results },
    if (not($return-results)) then ()
    else element search:transform-results {
      attribute apply { "snippet" },
      attribute ns { "ns://va.gov/2012/ip401/search-lib" },
      attribute at { "/lib/search-lib.xqy" } },
    $SEARCH-OPTIONS/node() ! (
      typeswitch(.)
      case element(search:additional-query) return ()
      case element(search:return-results) return ()
      (: Optionally control which constraints are returned as facets.
       : For all default facets, $facets-default false and $facets-extra ().
       : For defaults plus, $facets-default true and $facets-extra non-empty.
       : For extra only, $facets-default false and $facets-extra non-empty.
       :)
      case element(search:constraint) return (
        if ($facet-defaults and empty($facets-extra)) then .
        else element search:constraint {
          @*,
          namespace::*,
          c:constraint-rewrite(
            @name, *, $facet-defaults, $facets-extra, $corners-nsew) })
      default return .) }
};

declare function c:search-options(
  $mature-only as xs:boolean,
  $return-results as xs:boolean,
  $facet-defaults as xs:boolean,
  $facets-extra as xs:string*)
as element(search:options)
{
  c:search-options(
    $mature-only, $return-results, $facet-defaults, $facets-extra, ())
};

declare function c:search-options(
  $mature-only as xs:boolean,
  $return-results as xs:boolean,
  $facet-defaults as xs:boolean)
as element(search:options)
{
  c:search-options(
    $mature-only, $return-results, $facet-defaults, (), ())
};

declare function c:search-options(
  $mature-only as xs:boolean,
  $return-results as xs:boolean)
as element(search:options)
{
  c:search-options(
    $mature-only, $return-results, true(), (), ())
};

declare function c:site-location-geo(
  $site as xs:string,
  $location as xs:string)
as element(site:location)
{
  $SITE-DATA/site:site[@id eq $site]/site:location[@id eq $location]
};

(: config.xqy :)
