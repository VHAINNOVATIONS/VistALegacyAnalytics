<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>
  <xsl:template name="children" match="*" mode="children">
    <li>
      <xsl:choose>
        <xsl:when test="normalize-space(text())">
          <xsl:value-of select="local-name()"/>
          <xsl:text>: </xsl:text><xsl:value-of select="text()"/>
        </xsl:when>
        <xsl:otherwise>
          <h3><xsl:value-of select="local-name()"/></h3>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
      <xsl:if test="exists(child::*)">
        <ul>
          <xsl:apply-templates select="child::*" mode="children"/>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>
  <xsl:template name="root" match="*">
      <ul class="xml_tree">
        <xsl:apply-templates select="self::*" mode="children"/>
      </ul>
  </xsl:template>
</xsl:stylesheet>