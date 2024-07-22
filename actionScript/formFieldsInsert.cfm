<cfsetting showDebugOutput="No">
<cftry>
    <cfset decryptedID = decrypt(form.colId, "l80yTxCYSSk=", "DES", "Base64")>
    <cfset dataStruct = StructNew() >
    <cfoutput>
        <cfloop list="#form.fieldnames#" index="field">
            <cfif Left(field,6) EQ 'field_'>
                <cfset fieldName = right(field,len(field) - 6)>
                <cfset dataStruct[#fieldName#] = "#form[field]#">
                <cfif lcase(fieldName) EQ lcase('fullName')>
                    <cfquery datasource="LicenseData" name="updateFields">
                        UPDATE TBL_schedulerInfo
                        SET namePositionValue = <cfqueryparam value="#form[field]#" cfsqltype="CF_SQL_VARCHAR">
                        WHERE ID = <cfqueryparam value="#decryptedID#" cfsqltype="CF_SQL_INTEGER">
                    </cfquery>
                </cfif>
                <cfif lcase(fieldName) EQ lcase('cityStateZipcode')>
                    <cfquery datasource="LicenseData" name="updateFields">
                        UPDATE TBL_schedulerInfo
                        SET cityStateZipPositionValue = <cfqueryparam value="#form[field]#" cfsqltype="CF_SQL_VARCHAR">
                        WHERE ID = <cfqueryparam value="#decryptedID#" cfsqltype="CF_SQL_INTEGER">
                    </cfquery>
                </cfif>
            </cfif>
        </cfloop>
    </cfoutput>

    <cfquery datasource="LicenseData" name="updateFields">
        UPDATE TBL_schedulerInfo
        SET fieldsData = <cfqueryparam value="#serializeJSON(dataStruct)#" cfsqltype="CF_SQL_VARCHAR">
        WHERE ID = <cfqueryparam value="#decryptedID#" cfsqltype="CF_SQL_INTEGER">
    </cfquery>
    <cfoutput>#serializeJSON({"result":"success"})#</cfoutput>
    <cfcatch type="any"><cfoutput>#serializeJSON({"result":"failed"})#</cfoutput></cfcatch>
</cftry>