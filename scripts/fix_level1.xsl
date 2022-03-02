<!-- Fix some small errors in ELTeC-rom level1:
     - U+00A0 NO-BREAK SPACE to ordinary space
     - remove leading and trailing blanks
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
  <xsl:variable name="Today" select="substring-before(current-date() cast as xs:string, '+')"/>

  <xsl:template match="/">
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="processing-instruction()">
    <xsl:copy-of select="."/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:revisionDesc">
    <xsl:copy>
      <xsl:text>&#10;</xsl:text>
      <change when="{$Today}">
	<xsl:text>Corrected errors in spacing</xsl:text>
      </change>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="text()">
    <xsl:variable name="text" select="replace(., '&#xA0;', ' ')"/>
    <xsl:choose>
      <xsl:when test="normalize-space($text)">
	<xsl:variable name="trim">
	  <xsl:variable name="pre">
	    <xsl:choose>
	      <xsl:when test="preceding-sibling::tei:*">
		<xsl:value-of select="$text"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:value-of select="replace($text, '^\s+', '')"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:variable>
	  <xsl:variable name="post">
	    <xsl:choose>
	      <xsl:when test="following-sibling::tei:*">
		<xsl:value-of select="$pre"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:value-of select="replace($pre, '\s+$', '')"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:variable>
	  <xsl:value-of select="replace($post, '\s+', ' ')"/>
	</xsl:variable>
	<!--xsl:value-of select="$trim"/-->
	<!-- Also fix left-join punctuation, as it is inconsistent -->
	<xsl:value-of select="replace($trim, ' ([,.!?;:])', '$1')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$text"/> 
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Copy everything else -->
  <xsl:template match="* | @* | comment()">
    <xsl:copy>
      <xsl:apply-templates select="* | @* | processing-instruction() | comment() | text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
