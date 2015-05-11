(: Shared step called by CORB once before it runs any transformation steps :)

xquery version "1.0-ml";

declare namespace va = "ns://va.gov/2012/ip401";

import module namespace util = "ns://va.gov/2012/ip401/util" at "/lib/util.xqy";

util:non-enriched-uris(xs:QName("va:conceptEnrichment"))