<cfcomponent extends="_components.base" displayname="Document ClassActions" output="no" hint="All ClassAction methods, including Find">

<!--- ==== Constructor === --->
<cffunction  name="init"	displayName="Initialize class action object" output="no"
	hint="init([id:Numeric][,name:String]) initializes a ClassAction, returns THIS">
	<cfargument name="Id" displayName="Id of class action" type="Numeric" required="false" default="0"/>
	<cfargument name="Name" displayName="Name of class action" type="String" required="false" default=""/>
	<cfargument name="Type" displayName="Type (1 for filing, 2 for settlement)" type="numeric" required="false" default="1"/>
	<cfargument name="Link" displayName="Link to class action" type="String" required="false" default=""/>
	<cfargument name="Date" displayName="Date of class action" type="String" required="false" default=""/>
	<cfargument name="Summary" displayName="Summary of class action" type="String" required="false" default=""/>
	<cfargument name="Settlement" displayName="Settlement (Class action settlements only)" type="String" required="false" default=""/>	
	
	<cfscript>				
		VARIABLES.classAction = structNew();
		setID(ARGUMENTS.ID);
		setName(ARGUMENTS.Name);
		setType(ARGUMENTS.Type);
		setLink(ARGUMENTS.Link);
		setDate(ARGUMENTS.Date);
		setSummary(ARGUMENTS.Summary);
		setSettlement(ARGUMENTS.Settlement);
		
		return THIS;
	</cfscript>
</cffunction>

<!--- ==== Public Class Methods === --->
<cffunction	name="findAll" displayName="Get an array class action filings or settlements" returnType="Array">
	
	<cfargument name="type" displayName="Type"
		type="Numeric" required="false" default="1">
	<cfargument name="lastDate" displayName="Date to check by"
		type="String" required="false" default="">		
		
	<cfscript>
		var result=ArrayNew(1);
		var ClassActionQuery='';
	</cfscript>

	<cfquery name="ClassActionQuery" datasource="#request.dsn#">
		SELECT	caID AS Id, caName AS Name, caType as Type, caLink AS link, caDate as Date, 
				caSummary as Summary, caSettlement AS settlement, caDateCreated AS DateCreated
		FROM	ClassActions
		WHERE	caType = <cfqueryparam cfsqltype="cf_sql_numeric" value="#ARGUMENTS.type#">
				<cfif Len(ARGUMENTS.lastDate)>
					AND caDateCreated >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#ARGUMENTS.lastDate#">
				</cfif>
		ORDER BY caDate desc
	</cfquery>

	<cfloop query="ClassActionQuery">
		<cfscript>
			THIS.init(ClassActionQuery.Id, ClassActionQuery.Name, ClassActionQuery.Type, ClassActionQuery.Link, ClassActionQuery.Date, ClassActionQuery.Summary, ClassActionQuery.Settlement);
			ArrayAppend(result, VARIABLES.classAction);
		</cfscript>
	</cfloop>

	<cfreturn result />
</cffunction>
	
<cffunction	name="load"	returnType="struct"	displayName="Load a specific ClassAction instance" output="no">
	
	<cfargument name="caID" type="numeric" required="false" default="0">
	
	<cfif (not isDefined("ARGUMENTS.caID") OR ARGUMENTS.caID EQ 0) and isDefined("VARIABLES.classAction.ID")>
		<cfset ARGUMENTS.caID = VARIABLES.classAction.ID>
	</cfif>
	
	<cfquery name="getClassAction" maxrows="1" datasource="#request.dsn#">
		SELECT	caID, caName, caType, caLink, caDate, caSummary, caSettlement
		FROM	ClassActions
		WHERE	caID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#ARGUMENTS.caID#">
	</cfquery>
	
	<cfscript>
		if (getClassAction.recordCount)	{
			THIS.setID(getClassAction.caID);
			THIS.setName(getClassAction.caName);
			THIS.setType(getClassAction.caType);
			THIS.setLink(getClassAction.caLink);
			THIS.setDate(getClassAction.caDate);
			THIS.setSummary(getClassAction.caSummary);
			THIS.setSettlement(getClassAction.caSettlement);
		}
	</cfscript>
	
	<cfreturn VARIABLES.classAction />
</cffunction>

<cffunction	name="save"	returnType="struct"	displayName="Save a ClassAction instance to the database" output="no">
	
	<cfif (VARIABLES.classAction.ID GT 0)>
		<cfquery name="updateClassAction" maxrows="1" datasource="#request.dsn#">
			UPDATE 	ClassActions
			SET			caName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.name#">,
						caType = <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.classAction.type#">,
						caLink = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.link#">,
						caDate = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.classAction.date#">,
						caSummary = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.summary#">,
						caSettlement = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.settlement#">,
						caDateModified = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
			WHERE		caID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.classAction.ID#">
		</cfquery>
	<cfelse>
		<cfquery name="insertClassAction" maxrows="1" datasource="#request.dsn#">
			SET nocount ON
				INSERT INTO ClassActions (caName, caType, caLink, caDate, caSummary, caSettlement)
				VALUES (<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.name#">,
						<cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.classAction.type#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.link#">,
						<cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.classAction.date#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.summary#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.classAction.settlement#">)
			 
			 	SELECT caID=@@identity from ClassActions
			SET nocount OFF
		</cfquery>
		
		<cfset tmp = THIS.setID(insertClassAction.caID)>
	</cfif>
	
	<cfreturn THIS />
</cffunction>

<cffunction	name="delete" returnType="any" displayName="Delete a specific class action instance" output="no">
	
	<cfargument name="caID" type="numeric" required="true">
	
	<cfquery maxrows="1" datasource="#request.dsn#">
		DELETE
		FROM	ClassActions
		WHERE	caID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#ARGUMENTS.caID#">
	</cfquery>

	<cfreturn THIS />
</cffunction>

<!--- ==== Getters/Setters ==== --->
<cffunction	name="getID" returnType="numeric" displayName="Get ClassAction ID" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.ID")) return VARIABLES.classAction.ID;
	</cfscript>
	
</cffunction>

<cffunction	name="setID" displayName="Set class action ID" output="no">	
	<cfargument name="caID" type="numeric" required="true">	
	
	<cfscript>
		VARIABLES.classAction.ID = ARGUMENTS.caID;
		
		return THIS;
	</cfscript>
	
</cffunction>

<cffunction	name="getName" returnType="string" displayName="Get ClassAction name" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.name")) return VARIABLES.classAction.name;
	</cfscript>
	
</cffunction>

<cffunction	name="setName" displayName="Set ClassAction name" output="no">	
	<cfargument name="caName" type="string" required="true">	
	
	<cfscript>
		VARIABLES.classAction.name = ARGUMENTS.caName;
		
		return THIS;
	</cfscript>		
	
</cffunction>

<cffunction	name="getType" returnType="numeric" displayName="Get ClassAction type" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.type")) return VARIABLES.classAction.type;
	</cfscript>
	
</cffunction>

<cffunction	name="setType" displayName="Set ClassAction type" output="no">	
	<cfargument name="caType" type="numeric" required="true">	
	
	<cfscript>
		VARIABLES.classAction.type = ARGUMENTS.caType;
		
		return THIS;
	</cfscript>		
	
</cffunction>

<cffunction	name="getLink" returnType="string" displayName="Get ClassAction link" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.link")) return VARIABLES.classAction.link;
	</cfscript>
	
</cffunction>

<cffunction	name="setLink" displayName="Set ClassAction link" output="no">	
	<cfargument name="caLink" type="string" required="true">	
	
	<cfscript>
		VARIABLES.classAction.link = ARGUMENTS.caLink;
		
		return THIS;
	</cfscript>		
	
</cffunction>

<cffunction	name="getDate" returnType="any" displayName="Get ClassAction date" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.date")) return VARIABLES.classAction.date;
	</cfscript>
	
</cffunction>

<cffunction	name="setDate" displayName="Set ClassAction date" output="no">	
	<cfargument name="caDate" type="string" required="true">	
	
	<cfscript>
		if (Len(ARGUMENTS.caDate) and not isDate(ARGUMENTS.caDate))
			abort('Improper format for Date: #ARGUMENTS.caDate#',1);
			
		VARIABLES.classAction.date = ARGUMENTS.caDate;
		
		return THIS;
	</cfscript>		
	
</cffunction>

<cffunction	name="getSummary" returnType="string" displayName="Get ClassAction summary" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.summary")) return VARIABLES.classAction.summary;
	</cfscript>
	
</cffunction>

<cffunction	name="setSummary" displayName="Set ClassAction summary" output="no">	
	<cfargument name="caSummary" type="string" required="true">	
	
	<cfscript>
		VARIABLES.classAction.summary = ARGUMENTS.caSummary;
		
		return THIS;
	</cfscript>		
	
</cffunction>

<cffunction	name="getSettlement" returnType="string" displayName="Get ClassAction settlement" output="no">
	
	<cfscript>
		if (isDefined("VARIABLES.classAction.settlement")) return VARIABLES.classAction.settlement;
	</cfscript>
	
</cffunction>

<cffunction	name="setSettlement" displayName="Set ClassAction settlement" output="no">	
	<cfargument name="caSettlement" type="string" required="true">	
	
	<cfscript>
		VARIABLES.classAction.settlement = ARGUMENTS.caSettlement;
		
		return THIS;
	</cfscript>		
	
</cffunction>

</cfcomponent>
