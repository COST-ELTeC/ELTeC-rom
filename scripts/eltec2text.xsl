<!-- Dump text from ELTEC, one "paragraph" per line -->
<xsl:stylesheet version="2.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema" 
		xmlns:tei="http://www.tei-c.org/ns/1.0"    
		xmlns:eltec="http://distantreading.net/eltec/ns"
		xmlns="http://www.tei-c.org/ns/1.0"
		exclude-result-prefixes="xs tei eltec">

  <xsl:output method="text"/>
  <xsl:template match="text()"/>
  <xsl:template match="/">
    <xsl:apply-templates select="tei:TEI/tei:text"/>
  </xsl:template>
  <xsl:template match="tei:p | tei:note | tei:l | tei:trailer">
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
