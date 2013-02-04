<!--- $Id: Query.cfc 16483 2010-07-20 19:00:18Z rehm $ --->
<cfcomponent extends="_components.classes.Object" output="false" displayName="Search/Query.cfc" hint="Search/Query provides access to and retrieval from Coveo indexes">

  <cfset VARIABLES.FUNCBASE='/_components/functions'/>
	<cfset VARIABLES.CLASSBASE='_components.classes'/>

<cfsavecontent variable="VARIABLES.TRANSFORM_XSLT">
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

 <xsl:output method="xml" version="1.0" encoding="utf-8" indent="no" />
 <xsl:strip-space elements="name value" />

 <xsl:template match="/">
  <xsl:apply-templates />
 </xsl:template>

 <xsl:template match="/QueryResults">
  <xsl:element name="root">
	 <xsl:element name="Success"><xsl:value-of select="Executed"/></xsl:element>
	 <xsl:element name="Total"><xsl:value-of select="TotalCount"/></xsl:element>
	 <xsl:element name="Time"><xsl:value-of select="Time"/></xsl:element>
	 <xsl:element name="BasicQuery"><xsl:value-of select="BasicQuery"/></xsl:element>
	 <xsl:element name="AdvancedQuery"><xsl:value-of select="AdvancedQuery"/></xsl:element>
	 <xsl:element name="ExpandedQuery"><xsl:value-of select="ExpandedQuery"/></xsl:element>
	 <xsl:apply-templates />
	</xsl:element>
 </xsl:template>

 <xsl:template match="/QueryResults/Results">
	<xsl:element name="results">
		<xsl:for-each select="QueryResult/Fields">
			<xsl:element name="result">
				<xsl:for-each select="ResultField">
					<xsl:element name="{substring(Name,2)}">
						<xsl:value-of select="Value"/>
					</xsl:element>
				</xsl:for-each>
			</xsl:element>
		</xsl:for-each>
	</xsl:element>
 </xsl:template>

 <!-- override default template -->
 <xsl:template match="@*|text()" />

</xsl:stylesheet>
</cfsavecontent>

	<cfinclude template="#FUNCBASE#/Config/ClassInit.cfm"/>

	<cfset import('Strings,CFScript,Types')/>

	<cffunction name="init" returntype="Any" output="true" displayName="constructor: init" hint="instantiates a new Query object">
		<cfscript>
			var $args=IIF(ArrayLen(ARGUMENTS) EQ 1 AND IsArray(ARGUMENTS[1]), 'ARGUMENTS[1]','ARGUMENTS');
			var $num_args=ArrayLen($args);
			var $tmp=ArrayNew(1);
			var $i=0;

			if(TypeOf($args) EQ 'cfarguments') {
				for($i=1; $i LTE ArrayLen($args);$i=$i+1)
					$tmp[$i]=$args[$i];
				$args=$tmp;
			}

			$Uri=CreateObject('component','#CLASSBASE#.Search.Query.Uri').init($args);

			SUPER.init(
				'Uri',               $Uri.asString(),
				'Source',            '',
				'Xslt',              '#VARIABLES.TRANSFORM_XSLT#',
				'Xml',				 '',
				'Results',           ArrayNew(1),
				'ThrowOnError',      true
			);

			return THIS;
		</cfscript>
	</cffunction>

	<cffunction name="getUri" displayName="getter for Uri:string" returntype="string" output="false">
		<cfreturn THIS.ivar('Uri') />
	</cffunction>

	<cffunction name="setUri" displayName="setter for Uri:string" returntype="Any" output="false">
			<cfargument name="Uri_arg" type="string" required="true"/>
		<cfreturn THIS.ivar('Uri',ARGUMENTS.Uri_arg) />
	</cffunction>

	<cffunction name="getSource" displayName="getter for Source:string" returntype="string" output="false">
			<cfargument name="printable" type="boolean" required="false" default="false"/>
		<cfif ARGUMENTS.printable EQ true>
			<cfreturn REReplaceNoCase(THIS.ivar('Source'),'<','&lt;','ALL')/>
		<cfelse>
			<cfreturn THIS.ivar('Source') />
		</cfif>
	</cffunction>

	<cffunction name="setSource" displayName="setter for Source:string" returntype="Any" output="false">
			<cfargument name="Source_arg" type="string" required="true"/>
		<cfreturn THIS.ivar('Source',ARGUMENTS.Source_arg) />
	</cffunction>

	<cffunction name="getXslt" displayName="getter for Xslt:string" returntype="string" output="false">
		<cfargument name="printable" type="boolean" required="false" default="false"/>
		<cfif ARGUMENTS.printable EQ true>
			<cfreturn REReplaceNoCase(THIS.ivar('Xslt'),'<','&lt;','ALL')/>
		<cfelse>
			<cfreturn THIS.ivar('Xslt') />
		</cfif>
	</cffunction>

	<cffunction name="setXslt" displayName="setter for Xslt:string" returntype="Any" output="false">
		<cfargument name="Xslt_arg" type="string" required="true"/>
		<cfreturn THIS.ivar('Xslt',ARGUMENTS.Xslt_arg) />
	</cffunction>

	<cffunction name="getXml" displayName="getter for Xml:xml" returntype="xml" output="false">
		<cfreturn THIS.ivar('Xml') />
	</cffunction>

	<cffunction name="setXml" displayName="setter for Xml:xml" returntype="Any" output="false">
		<cfargument name="Xml_arg" type="xml" required="true"/>
		<cfreturn THIS.ivar('Xml',ARGUMENTS.Xml_arg) />
	</cffunction>

	<cffunction name="getThrowOnError" displayName="getter for ThrowOnError:boolean" returntype="boolean" output="false">
		<cfreturn THIS.ivar('ThrowOnError') />
	</cffunction>

	<cffunction name="setThrowOnError" displayName="setter for ThrowOnError:boolean" returntype="Any" output="false">
		<cfargument name="ThrowOnError_arg" type="boolean" required="true"/>
		<cfreturn THIS.ivar('ThrowOnError',ARGUMENTS.ThrowOnError_arg) />
	</cffunction>

	<cffunction name="transform" returntype="Any" output="false">
		<cfargument name="xslt" type="string" required="false" default="#THIS.getXslt()#"/>
		<cfscript>
			var $xslt=ARGUMENTS.xslt;
			var $source=THIS.getSource();
			if(Len($xslt) GT 0) {
				try { $source=XmlTransform($source,$xslt); }
				catch(Any E) {
					cfthrow$('failed to transform $source: #E.message#');
				}
				THIS.setSource($source);
			}
			return THIS;
		</cfscript>
	</cffunction>

	<cffunction name="convert" returntype="Any" output="false" displayName="Convert" hint="converts document source to xml">
		<cfscript>
			var $xml='';

			try { $xml=XmlParse(THIS.getSource()); }
			catch(Any E) {
				cfthrow$('failed to parse $source as xml: #E.message# '
					& '- source is:#THIS.getSource(true)#');
			}

			if(NOT IsXmlDoc($xml))
				cfthrow$('$result is not an xml document object after XmlParse');

			THIS.setXml($xml);

			return THIS;
		</cfscript>
	</cffunction>

	<cffunction name="load" returntype="Any" output="false" displayName="Load" hint="retrieves document source from a query uri">
		<cfscript>
			var $source=cfhttp$(
				url=THIS.getUri(),
				throwonerror=THIS.getThrowOnError()
			);

			if(NOT IsXml($source))
				cfthrow$("$source is not valid xml: source=#$source#");

			THIS.setSource($source);

			return THIS;
		</cfscript>
	</cffunction>

	<cffunction name="submit" returntype="xml" output="false" displayName="Submit" hint="submits query uri, retrieves result, transforms it and converts it to XML">
		<cfscript>
			return THIS.load().transform().convert().getXml();
		</cfscript>
	</cffunction>

	<cffunction name="getConcepts" returntype="struct" output="false" displayName="getConcepts" hint="returns an array of concepts from an xml result">
		<cfscript>
			var $result=StructNew();
			var $xml=THIS.getXml();
			var xsl='';
			if(NOT IsDefined('$xml') OR NOT IsXml($xml)) cfthrow$('need xml');
		</cfscript>

		<cfsavecontent variable="xsl">
			<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	 			<xsl:output method="text" version="1.0" encoding="utf-8" indent="yes" />
	 			<xsl:variable name="nl">
					<xsl:text></xsl:text>
				</xsl:variable>
	 			<xsl:template match="/QueryResults">
			 		<xsl:for-each select="//QueryResult/Concepts/*">
						<xsl:value-of select="text()"/>
						<xsl:copy-of select="$nl"/>
					</xsl:for-each>
				</xsl:template>
				<xsl:template match="@*|text()" />
			</xsl:stylesheet>
		</cfsavecontent>

		<cfscript>
			$concepts=StrSplit(XmlTransform($xml,xsl)).iterator();
			while($concepts.hasNext()) {
				$concept=$concepts.next();
				if(NOT StructKeyExists($result,$concept)) $result[$concept]=0;
				$result[$concept]=$result[$concept]+1;
			}
			return $result;
		</cfscript>
	</cffunction>

</cfcomponent>
