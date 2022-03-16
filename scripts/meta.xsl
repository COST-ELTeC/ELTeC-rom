<?xml version='1.0' encoding='UTF-8'?>
<!-- Add metadata to ELTeC level 2: stuff in teiHeader and @xml:id -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="fn tei xi">
  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="tei:c"/>
  <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="today-iso" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
  <xsl:variable name="today-slv" select="format-date(current-date(), '[D1]. [M1]. [Y]')"/>

  <xsl:param name="change">
    <change when="{$today-iso}">Tomaž Erjavec: Annotation with Nikola's tool-chain &amp; TEI editing.</change>
  </xsl:param>

  <xsl:template match="tei:publicationStmt/tei:date">
    <xsl:copy>
      <xsl:attribute name="when" select="$today-iso"/>
      <xsl:value-of select="$today-slv"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="tei:titleStmt/tei:respStmt[last()]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <respStmt>
      <resp xml:lang="sl">Jezikoslovna obdelava</resp>
      <resp xml:lang="en">Linguistic processing</resp>
      <name>Tomaž Erjavec</name>
    </respStmt>
  </xsl:template>
 
  <xsl:template match="tei:tagsDecl/tei:namespace">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
      <xsl:apply-templates mode="tagCount" select="//tei:text//tei:s"/>
      <xsl:apply-templates mode="tagCount" select="//tei:text//tei:w"/>
      <xsl:apply-templates mode="tagCount" select="//tei:text//tei:pc"/>
    </xsl:copy>
  </xsl:template>

  <!-- To fix (ex) bug in level-2 schema
  <xsl:template match="tei:distributor"/>
  <xsl:template match="tei:availability"/>
  -->
  
  <xsl:template match="tei:encodingDesc">
    <xsl:copy>
      <xsl:attribute name="xml:lang">en</xsl:attribute>
      <xsl:attribute name="n">eltec-2</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="tei:encodingDesc/tei:p">
    <xsl:copy>
      <xsl:apply-templates/>
      <xsl:text> Tokenisation and sentence segmentation performed with </xsl:text>
      <ref target="https://github.com/clarinsi/reldi-tokeniser">ReLDI tokeniser</ref>,
      <xsl:text>word modernisation with </xsl:text>
      <ref target="https://github.com/clarinsi/csmtiser">CSMTiser</ref>,
      <xsl:text> and UD morphosyntactic tagging and lemmatisation with </xsl:text>
      <ref target="https://github.com/clarinsi/classla-stanfordnlp">CLASSLA-StanfordNLP</ref>
      <xsl:text> trained for Slovene. Named entities were annotated with </xsl:text>
      <ref target="https://github.com/clarinsi/janes-ner">Janes-NER</ref>
      <xsl:text>, which uses the set of NE labels detailed in the </xsl:text>
      <ref target="http://nl.ijs.si/janes/wp-content/uploads/2017/09/SlovenianNER-eng-v1.1.pdf">Annotation guidelines for Slovenian named entities Janes-NER V1.1</ref>
      <xsl:text>.</xsl:text>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:teiHeader">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
      <xsl:if test="not(tei:revisionDesc)">
	<revisionDesc>
	  <xsl:copy-of select="$change"/>
	</revisionDesc>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:revisionDesc">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:copy-of select="$change"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:div | tei:text//tei:p  | tei:p/tei:l  | tei:text//tei:note
		       | tei:s | tei:w | tei:pc">
    <xsl:copy>
      <xsl:attribute name="xml:id">
	<xsl:value-of select="ancestor::tei:TEI/@xml:id"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="name()"/>
	<xsl:number level="any" from="tei:text"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="xi:include">
    <xsl:copy>
      <xsl:attribute name="href"
		     select="replace(
			     replace(@href, '\.xml', '-ana.xml'),
			     'speech/', '')"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="replace(., '\s+', ' ')"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template mode="tagCount" match="tei:*">
    <xsl:variable name="self" select="name()"/>
    <xsl:if test="not(following::*[name()=$self] or descendant::*[name()=$self] )">
      <tagUsage xmlns="http://www.tei-c.org/ns/1.0" gi="{$self}">
	<xsl:attribute name="occurs">
	  <xsl:number level="any" from="tei:text"/>
	</xsl:attribute>
      </tagUsage>
    </xsl:if>
  </xsl:template>
  <xsl:template mode="tagCount" match="text()"/>

</xsl:stylesheet>
