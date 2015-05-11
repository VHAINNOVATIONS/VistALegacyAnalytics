<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:va="ns://va.gov/2012/ip401"
    exclude-result-prefixes="va"
    version="2.0">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="va:total">
    <!-- hidden -->
  </xsl:template>

  <xsl:template match="*">
    <li>
      <xsl:value-of select="local-name(.)"/>:
      <xsl:value-of select="string()"/>
    </li>
  </xsl:template>

  <xsl:template match="*[*]">
    <div class="section">
      <div class="section-heading"><xsl:value-of select="local-name(.)"/></div>
      <ul>
        <xsl:apply-templates/>
      </ul>
    </div>  
  </xsl:template>

  <xsl:template match="/">
    <html>
      <head>
        <title>Virtual Patient Record</title>
      </head>
      <body>
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
