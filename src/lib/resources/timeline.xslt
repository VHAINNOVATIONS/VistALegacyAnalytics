<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" extension-element-prefixes="xdmp" xmlns:xdmp="http://marklogic.com/xdmp" xmlns:util="ns://va.gov/2012/ip401/util" xmlns="http://www.w3.org/1999/xhtml">
	<xdmp:import-module href="/lib/util.xqy" namespace="ns://va.gov/2012/ip401/util"/>
	<xsl:template match="va:vital">
		<tr>
			<td>Vitals</td>
			<td><xsl:variable name="taken" select="va:taken"/><xsl:value-of select="util:millisecond-date($taken)"/></td>
			<td><xsl:apply-templates select="./va:measurements/va:measurement" mode="vital-description" /></td>
		</tr>
	</xsl:template>
	<xsl:template match="*" mode="vital-description">
		<xsl:value-of select="va:measurement-name"/>: <xsl:value-of select="va:value"/> <xsl:value-of select="va:units"/><br/>
	</xsl:template>
	<xsl:template match="va:procedure">
		<tr>
			<td>Procedures</td>
			<td><xsl:variable name="dateTime" select="va:dateTime"/><xsl:value-of select="util:millisecond-date($dateTime)"/></td>
			<td><xsl:value-of select="va:procedure-name"/></td>
		</tr>
	</xsl:template>
	<xsl:template match="va:med">
		<tr>
			<td>Meds</td>
			<td><xsl:variable name="dateTime" select="va:start"/><xsl:value-of select="util:millisecond-date($dateTime)"/></td>
			<td><xsl:value-of select="va:med-name"/></td>
		</tr>
	</xsl:template>
	<xsl:template match="va:problem">
		<tr>
			<td>Problems</td>
			<td><xsl:variable name="dateTime" select="va:entered"/><xsl:value-of select="util:millisecond-date($dateTime)"/></td>
			<td><xsl:value-of select="va:problem-name"/></td>
		</tr>
	</xsl:template>
	<xsl:template match="va:visit">
		<tr>
			<td>Visits</td>
			<td><xsl:variable name="dateTime" select="va:dateTime"/><xsl:value-of select="util:millisecond-date($dateTime)"/></td>
			<td><xsl:value-of select="va:service"/></td>
		</tr>
	</xsl:template>
	<xsl:template match="*"><xsl:apply-templates select="./*"/></xsl:template>
</xsl:stylesheet>