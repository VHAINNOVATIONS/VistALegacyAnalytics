xquery version "1.0-ml";
declare namespace alert = "http://marklogic.com/xdmp/alert";

declare variable $alert:doc as node() external;
declare variable $alert:rule as element(alert:rule) external;

declare variable $USER-MATCHES-DOC-URI := fn:concat("/users/", xdmp:get-current-user(), "/", "savedsearch-match.xml");
declare variable $USER-MATCHES-DOC := fn:doc($USER-MATCHES-DOC-URI);


let $now := fn:current-dateTime()
return
	xdmp:node-insert-child($USER-MATCHES-DOC/savedsearch-match, element latest-match {$now})
	