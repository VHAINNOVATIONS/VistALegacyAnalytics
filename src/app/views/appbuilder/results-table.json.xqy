xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace patient-lib = "ns://va.gov/2012/ip401/patient" at "/app/models/patient-lib.xqy";

declare variable $table := vh:get('table');
declare variable $total := vh:get('total');
declare variable $td := vh:get('total-display');
declare variable $echo := vh:get('echo');

let $obj := json:object(
	<json:object>
		<json:entry>
			<json:key>aaData</json:key>
			<json:value>
				<json:array>
				{
					for $rowmap in $table
					return
						<json:value>
							<json:array>
							{
								for $key at $idx in ("key", $patient-lib:GENDERS, $patient-lib:RACES, $patient-lib:AGES)
								let $val := if (map:contains($rowmap, $key)) then map:get($rowmap, $key) else 0
								return <json:value xsi:type="xs:string">{$val}</json:value>
							}
							</json:array>
						</json:value>
				}
				</json:array>
			</json:value>
		</json:entry>
		<json:entry>
			<json:key>iTotalRecords</json:key>
			<json:value xsi:type="xs:integer">{$total}</json:value>
		</json:entry>
		<json:entry>
			<json:key>iTotalDisplayRecords</json:key>
			<json:value xsi:type="xs:integer">{$td}</json:value>
		</json:entry>
		<json:entry>
			<json:key>sEcho</json:key>
			<json:value xsi:type="xs:integer">{$echo}</json:value>
		</json:entry>
	</json:object>
)
return xdmp:to-json($obj)