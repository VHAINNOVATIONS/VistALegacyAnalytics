xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : ingest-ontology.xqy
 :
 : @author Brad Mann
 :
 : This main module is used by RecordLoader to ingest ICD-9 and SNOMED documents.
 :
 :)
declare namespace va="ns://va.gov/2012/ip401" ;

import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "../lib/ontology.xqy";
import module namespace trgr='http://marklogic.com/xdmp/triggers' 
   at '/MarkLogic/triggers.xqy';

declare variable $trgr:uri as xs:string external;
declare variable $trgr:trigger as node() external;

declare variable $type as xs:string := if (fn:ends-with($trgr:uri, '.csv')) then 'ICD9' else 'SNOMED';

(
	xdmp:log(text{"Ontology trigger activated."}),
	on:transform(fn:doc($trgr:uri), $type)
)