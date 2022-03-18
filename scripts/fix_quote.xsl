<!-- Fix <quote> elements that now appear in many contexts:
     when <quote> contains text content directly, 
     but its siblings are not text nodes
     then out <p> inside quote
-->
<xsl:stylesheet version="2.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema" 
		xmlns:h="http://www.w3.org/1999/xhtml" 
		xmlns:tei="http://www.tei-c.org/ns/1.0"    
		xmlns:eltec="http://distantreading.net/eltec/ns"
		xmlns="http://www.tei-c.org/ns/1.0"
		exclude-result-prefixes="xs h tei eltec">

  <xsl:output indent="yes"/>
  <xsl:template match="tei:quote">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
	<xsl:when test="./text()[normalize-space(.)] and 
			not(preceding-sibling::text()[normalize-space(.)] or 
			following-sibling::text()[normalize-space(.)])">
	  <p>
	    <xsl:apply-templates/>
	  </p>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
    
  <!-- Copy everything else -->
  <xsl:template match="* | @* | comment() | processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="* | @* | processing-instruction() | comment() | text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
