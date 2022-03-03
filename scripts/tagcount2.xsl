<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="tei"
    version="2.0">
  <xsl:output method="text"/>
  <xsl:template match="@*|processing-instruction()|comment()|text()"/>
  <xsl:template match="/">
    <xsl:apply-templates mode="tagCount" select=".//tei:facsimile | .//tei:text"/>
  </xsl:template>
  <xsl:template mode="tagCount" match="*">
    <xsl:variable name="self" select="name()"/>
    <xsl:if test="not(following::*[name()=$self] or descendant::*[name()=$self] )">
      <xsl:value-of select="$self"/>
      <xsl:text>&#9;</xsl:text>
      <xsl:number level="any" from="tei:facsimile | tei:text"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:apply-templates mode="tagCount"/>
  </xsl:template>
  <xsl:template mode="tagCount" match="text()"/>
</xsl:stylesheet>
