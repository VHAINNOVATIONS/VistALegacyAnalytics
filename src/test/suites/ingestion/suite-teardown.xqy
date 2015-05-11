(:
 : Copyright (c) 2012 Information Innovators Inc. All Rights Reserved.
 :
 : suites/prm/suite-teardown.xqy
 :
 : @author Michael Blakeley
 :
 : Suite teardown for prm test modules.
 :
 :)
xquery version "1.0-ml";

import module namespace test="http://marklogic.com/roxy/test-helper"
  at "/test/test-helper.xqy";

for $uri in ('/vpr/A/vpr-0', '/vpr/B/vpr-1', '/vpr/B/vpr-2')
where doc($uri)
return xdmp:document-delete($uri)

(: suites/prm/suite-teardown.xqy :)
