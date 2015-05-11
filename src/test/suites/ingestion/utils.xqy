xquery version "1.0-ml";
(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : suites/ingestion/utils.xqy
 :
 : @author Michael Blakeley
 :
 : This test module exercises utility functions from the ingestion library.
 :
 :)

declare namespace va = "ns://va.gov/2012/ip401";

import module namespace test="http://marklogic.com/roxy/test-helper"
  at "/test/test-helper.xqy";
import module namespace in = "ns://va.gov/2012/ip401/ingest"
  at "/lib/ingest.xqy";
import module namespace on = "ns://va.gov/2012/ip401/ontology"
  at "/lib/ontology.xqy";

(: basic functionality :)
test:assert-equal('A', in:site-from-uri('/A/12345')),
test:assert-equal('A', in:site-from-uri('/vpr/A/12345')),
test:assert-equal(
  '/vpr/A/12345',
  in:uri(
    'A',
    element va:patient { element va:id { attribute value { '12345' } } })),

(: enrichment
 : See suite-setup.xqy for the available subset of the ontology.
 :)
test:assert-exists(on:enrich(element content { 'foo' })),
test:assert-equal(
  3,
  count(
    on:enrich(<p>
According to Wikipedia, Glanders (from Middle English glaundres or Old French glandres, both meaning glands) (Latin: Malleus German: Rotz) (also known as "Equinia," "Farcy," and "Malleus") is an infectious disease that occurs primarily in horses, mules, and donkeys. It can be contracted by other animals such as dogs, cats and goats. It is caused by infection with the bacterium Burkholderia mallei, usually by ingestion of contaminated food or water. Symptoms of glanders include the formation of nodular lesions in the lungs and ulceration of the mucous membranes in the upper respiratory tract. The acute form results in coughing, fever and the release of an infectious nasal discharge, followed by septicaemia and death within days. In the chronic form, nasal and subcutaneous nodules develop, eventually ulcerating. Death can occur within months, while survivors act as carriers.
</p>)/on:concept)),
test:assert-equal(
  2,
  count(
    on:enrich(<p>
According to Wikipedia, Glanders (from Middle English glaundres or Old French glandres, both meaning glands) (Latin: Malleus German: Rotz) (also known as "Equinia," "Farcy," and "Malleus") is an infectious disease that occurs primarily in horses, mules, and donkeys. It can be contracted by other animals such as dogs, cats and goats. It is caused by infection with the bacterium Burkholderia mallei, usually by ingestion of contaminated food or water. Symptoms of glanders include the formation of nodular lesions in the lungs and ulceration of the mucous membranes in the upper respiratory tract. The acute form results in coughing, fever and the release of an infectious nasal discharge, followed by septicaemia and death within days. In the chronic form, nasal and subcutaneous nodules develop, eventually ulcerating. Death can occur within months, while survivors act as carriers.
</p>)/on:concept[ @code eq '024.' ])),
test:assert-equal(
  1,
  count(
    on:enrich(<p>
According to Wikipedia, Glanders (from Middle English glaundres or Old French glandres, both meaning glands) (Latin: Malleus German: Rotz) (also known as "Equinia," "Farcy," and "Malleus") is an infectious disease that occurs primarily in horses, mules, and donkeys. It can be contracted by other animals such as dogs, cats and goats. It is caused by infection with the bacterium Burkholderia mallei, usually by ingestion of contaminated food or water. Symptoms of glanders include the formation of nodular lesions in the lungs and ulceration of the mucous membranes in the upper respiratory tract. The acute form results in coughing, fever and the release of an infectious nasal discharge, followed by septicaemia and death within days. In the chronic form, nasal and subcutaneous nodules develop, eventually ulcerating. Death can occur within months, while survivors act as carriers.
</p>)/on:concept[ @code eq '786.2' ])),

(: end of list :)
()

(: suites/ingestion/utils.xqy :)
