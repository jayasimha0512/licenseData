<cfquery datasource="LicenseData" name="getRecordInfo">
	SELECT TOP 1 ID,InfoAction
    FROM TBL_schedulerInfo WHERE completedStatus = 0 ORDER BY InfoAction;
</cfquery>
<cfif getRecordInfo.recordCount GT 0 >
    <cfschedule action="resume" task = "LicenseDataScheduling">
    <cfif getRecordInfo.InfoAction EQ 1 OR getRecordInfo.InfoAction EQ 3 >
        <cfinclude  template="./csvDB.cfm">
    <cfelseif getRecordInfo.InfoAction EQ 2 >
        <cfinclude  template="./csvExpDB.cfm">
    <cfelseif getRecordInfo.InfoAction EQ 4>
        <cfinclude  template="./csvDataUpdate.cfm">
    </cfif>
<cfelse>
    <cfschedule action="pause" task = "LicenseDataScheduling">
</cfif>