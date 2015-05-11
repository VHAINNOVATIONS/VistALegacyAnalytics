xquery version "1.0-ml";
(:
 : Copyright 2012 MarkLogic Corporation
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :    http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
:)

import module namespace req = "http://marklogic.com/roxy/request"
  at "/roxy/lib/request.xqy";
import module namespace vh = "http://marklogic.com/roxy/view-helper"
  at "/roxy/lib/view-helper.xqy";
import module namespace rv = "http://marklogic.com/roxy/views/reports"
  at "lib.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml" ;

declare namespace db = "http://marklogic.com/xdmp/database";

declare namespace va = "ns://va.gov/2012/ip401";

declare variable $words := vh:get("words");
declare variable $seed-words := vh:get("seed-words");
declare variable $sample := vh:get("sample");
declare variable $envelope := vh:get("envelope");
declare variable $reportmatches := vh:get("reportmatches");
declare variable $numberOfWorkContextExamples := vh:get("numberOfWorkContextExamples");
declare variable $enableContextExamples := vh:get("enableContextEx");

rv:page(
  'Term Context Report',
<div id="report">
  <form id="waaw-form">
    <div id="waawRow1">
         <label class="displayedLabel" accesskey="w" for="words-field">Terms:</label>
         <span style="padding-left:1em">
            <input type="text" name="words" size="50" id="words-field" value="{$seed-words}" title="Comma-separate list of terms to search documents for" />
         </span>
    </div>
    <div id="waawRow2">
        <label class="displayedLabel" accesskey="w" for="sample-field">Sample:</label>
        <span style="padding-left:8px;">
            <input type="text" name="sample" size="5" id="sample-field" value="{$sample}" title="Number of documents to sample. (Higher numbers mean slower results.)" />
        </span>
        <span style="padding-left:20px;">
            <label class="displayedLabel" accesskey="w" for="env-field">Envelope:</label>
        </span>
        <span style="padding-left:112px;">
            <input type="text" name="envelope" size="5" id="env-field" value="{$envelope}" title="Number of words in the document surrounding the search terms" />
        </span>
    </div>
    <div id="waawRow3">
        <label class="displayedLabel" accesskey="w" for="matches-field">Matches:</label>
        <span style="padding-left:2px;">
            <input type="text" name="reportmatches" size="5" id="matches-field" value="{$reportmatches}" title="Number of matches to return" />
        </span>
        <span style="padding-left:19px;" >
            <label class="displayedLabel" accesskey="w" for="context-examples-field">Word context examples:</label>
        </span>
        <span style="padding-left:7px;">
            <input type="text" name="wordContextExamples" size="5" id="context-examples-field" value="{$numberOfWorkContextExamples}" title="Number of word context examples to return" />
        </span>
    </div>
    <div style="padding-top:5px;">
        <label class="displayedLabel" accesskey="w" for="matches-field">
            Enable context examples:
        </label>
        <input type="checkbox" id="enableContextExCB" name="enableContextEx" value="enabled" checked="true" title="" />
        <span style="padding-left:10px;">
            <input type="submit" value="Report" id="waawReportButton"/>
        </span>
    </div>
  </form>
  <script type="text/javascript" src="/js/waaw.js">&nbsp;</script>
  <div id="waaw-div">
  {
    if (fn:count($words) = 0) then "No matches found"
    else
      <table id="waawReportTable" class="waaw">
        <thead>
            <tr>
                <th>Word</th>
                <th>Frequency</th>
                <th class="contextExamplesHeader">Context Examples</th>
            </tr>
        </thead>
        <tbody>
        {
          for $wordmap in $words
          return
          <tr>
            <td class="waawwordcolumn">
                <a href="/?q={map:get($wordmap, "word")}">{map:get($wordmap, "word")}</a>
            </td>
            <td class="freq">
                {map:get($wordmap, "frequency")}
            </td>
            <td class="contextExamples">
                {map:get($wordmap, "contextExamples")}
            </td>
          </tr>
        }
        </tbody>
      </table>
  }
  </div>
</div>)

(: reports/vli.html.xqy :)
