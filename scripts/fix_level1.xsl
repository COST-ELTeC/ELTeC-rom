<!-- Fix some small errors in ELTeC-rom level1:
     - U+00A0 NO-BREAK SPACE to ordinary space (done in previous run)
     - remove leading and trailing blanks (done in previous run)
     - fix gap attributes
     - replace '-1' with '-l'
     - replace ’ with ' when used for contractions with '-'
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
  <xsl:param name="change">Fixed gap attributes, replaced '-1' with '-l' and [’'] when used for contractions with '-'</xsl:param>
  
  <xsl:variable name="Today" select="substring-before(current-date() cast as xs:string, '+')"/>

  <xsl:template match="tei:publicationStmt/tei:date">
    <xsl:copy>
      <xsl:attribute name="when" select="$Today"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:revisionDesc">
    <xsl:copy>
      <change when="{$Today}">
	<xsl:value-of select="$change"/>
      </change>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="processing-instruction()">
    <xsl:copy-of select="."/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="replace(
			  replace(., 
			  &quot;(\p{L})[’'](\p{L})&quot;, 
			  &quot;$1-$2&quot;),
			  '-1', '-l')"/>
  </xsl:template>

  <xsl:template match="tei:gap">
    <xsl:variable name="reason">
      <xsl:choose>
	<xsl:when test="@rend">editorial</xsl:when>
	<xsl:when test="@n = 'missing resource text'">missing</xsl:when>
	<xsl:when test="@unit = 'image'">editorial</xsl:when>
	<xsl:when test="@unit = 'graphic'">editorial</xsl:when>
	<xsl:when test="@unit = 'illustration'">editorial</xsl:when>
	<xsl:when test="@unit = 'toc'">editorial</xsl:when>
	<xsl:when test="@unit = 'line'">missing</xsl:when>
	<xsl:when test="@unit = 'page'">missing</xsl:when>
	<xsl:when test="@unit = 'pages'">missing</xsl:when>
	<xsl:when test="not(@*)">illegible</xsl:when>
	<xsl:otherwise>
	  <xsl:message select="concat('ERROR: gap with attributes ', name(@*), ' = ', @*)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="desc" select="replace(
				      replace(@rend, '^figure', 'Figure'),
				      '^Figure_', 'Figure: ')"/>
    <xsl:copy>
      <!-- We should use @reason and <desc>, but ELTeC schema allows neither! -->
      <xsl:variable name="n" select="normalize-space(concat('[', $reason, '] ', $desc))"/>
      <xsl:if test="normalize-space($n)">
	<xsl:attribute name="n" select="$n"/>
      </xsl:if>
      <xsl:if test="@unit">
	<!-- Get rid of plurals, e.g. "pages" <- "page" -->
	<xsl:attribute name="unit" select="replace(@unit, 's$', '')"/>
      </xsl:if>
      <xsl:if test="matches(@extent, '^\d+$') or matches(@n, '^\d+$')">
	<xsl:attribute name="quantity">
	  <xsl:choose>
	    <xsl:when test="matches(@extent, '^\d+$')">
	      <xsl:value-of select="@extent"/>
	    </xsl:when>
	    <xsl:when test="matches(@n, '^\d+$')">
	      <xsl:value-of select="@n"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:message select="concat('ERROR: gap with @extent=', @extent, ' and @n=', @n)"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>
      </xsl:if>
      <!-- ELTeC schema does not allow desc!
      <xsl:if test="$desc">
	<desc>
  	  <xsl:value-of select="$desc"/>
	</desc>
      </xsl:if>
      -->
    </xsl:copy>
  </xsl:template>
  
  <!-- Did this in 
       https://github.com/COST-ELTeC/ELTeC-rom/commit/c06108f7f21e1fa50423eb4ac8cfee752c50ce99
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
	<xsl:value-of select="replace($trim, ' ([,.!?;:])', '$1')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$text"/> 
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template-->
  
  <!-- Copy everything else -->
  <xsl:template match="* | @* | comment()">
    <xsl:copy>
      <xsl:apply-templates select="* | @* | processing-instruction() | comment() | text()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
