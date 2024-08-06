<cfquery datasource="LicenseData" name="getData">
	SELECT TOP 1 ID,
            fileName,industry,judiciary,loopingRow,totalRows,InfoAction,MainTable,ExpirationTable,
            AcqDataTable,headerRows,fieldsData,completedStatus,CREATED_DATE,UPDATED_DATE, namePosition,
            cityStateZipPos,namePositionValue,cityStateZipPositionValue,headerRowsProcessed,
            dataMatchedStructKeys,dataMatchedExpStructKeys,dataMatchedAcqStructKeys,dataMatchedStructValues,
            dataMatchedExpStructValues,dataMatchedAcqStructValues,fullNameFormat
    FROM TBL_schedulerInfo WHERE completedStatus = 0 AND InfoAction = 4;
</cfquery>

<cfif getData.recordCount GT 0>
	
	<cfscript>
		csvName = getData.fileName;
		path = ExpandPath( "\");
        
		CSVFile = "#path#/licenseData/csvfiles/#csvName#";
		fileReader = createobject("java","java.io.FileReader");
		fileReader.init(CSVFile);
		csvReader = createObject("java","com.opencsv.CSVReader");
		csvReader.init(fileReader);
		batchSize = 10;
        counter = 1;

        loopingRowval = int(getData.loopingRow)
        if(getData.loopingRow > 1){
            csvReader.skip(loopingRowval)
            startRow =loopingRowval;
            currentRow = loopingRowval;
        }else{
            startRow = 1;
            currentRow = 1;
        }
        nextCSVline = csvReader.readNext();
		ArrData = arrayNew(2);
		while (isdefined("nextCSVline") && nextCSVline  != '') {
			
			if (currentRow >= startRow && currentRow < startRow + batchSize) {

				ArrayAppend(ArrData[counter],nextCSVline,true);
				nextCSVline = csvReader.readNext()
				
			} else if (currentRow >= startRow + batchSize) {
				break; // Exit the loop after processing the desired batch size
			}
			counter++
			currentRow++;
		}
		
		headerRow = getData.headerRows;
		coldArr = arrayNew(2);
		
		for(v=1;v<= arraylen(ArrData);v++){
			ArrayAppend(coldArr[v],ArrData[v],true);
		}
		if(startRow != 1){
			arrayPrepend(coldArr, listToArray(headerRow));
		}
		
		csvReader.close();
		fileReader.close();
		
	</cfscript>
    
	<cfscript>
	if(startRow == 1){
		arr = coldArr[1];
		findNamePos = 0;
		namePositionValue = '';
		cityStateZipPos = 0;
		cityStateZipPositionValue = '';

		for(i=1;i<=arrayLen(arr);i++){
			arr[i]= ucase(replace(replace(replace(arr[i]," ","_", "all"),"-","", "all"),",","", "all"));
		}
		
		if(isDefined('getData.namePositionValue') && len(getData.namePositionValue) > 0 ){
			namePositionValue = getData.namePositionValue;
		}
		if(isDefined('getData.cityStateZipPositionValue') && len(getData.cityStateZipPositionValue) > 0 ){
			cityStateZipPositionValue = getData.cityStateZipPositionValue;
		}
		fieldsDataStruct = deserializeJSON(getData.fieldsData);

		if(len(cityStateZipPositionValue)){
			try{
				cityStateZipPos = ArrayFind(arr, cityStateZipPositionValue);
				ArrayDeleteAt(arr,cityStateZipPos);
				ArrayInsertAt(arr,cityStateZipPos, "MailingCity");
				ArrayInsertAt(arr,cityStateZipPos+1, "MailingState");
				ArrayInsertAt(arr,cityStateZipPos+2, "MailingZip");
				
				ArrayDeleteAt(coldArr[1],cityStateZipPos);
				ArrayInsertAt(coldArr[1],cityStateZipPos, "MailingCity");
				ArrayInsertAt(coldArr[1],cityStateZipPos+1, "MailingState");
				ArrayInsertAt(coldArr[1],cityStateZipPos+2, "MailingZip");

				StructDelete(fieldsDataStruct, 'CITYSTATEZIPCODE')
				fieldsDataStruct['MailingCity'] = 'MailingCity';
				fieldsDataStruct['MailingState'] = 'MailingState';
				fieldsDataStruct['MailingZip'] = 'MailingZip';
			}
			catch (any excpt) {
				writeDump(excpt)
			}
		}
		
		if(len(namePositionValue)){
			try{
				findNamePos = ArrayFind(arr, namePositionValue);
				ArrayDeleteAt(arr,findNamePos);
				ArrayInsertAt(arr,findNamePos, "FirstName");
				ArrayInsertAt(arr,findNamePos+1, "MiddleName");
				ArrayInsertAt(arr,findNamePos+2, "LastName");
				
				ArrayDeleteAt(coldArr[1],findNamePos);
				ArrayInsertAt(coldArr[1],findNamePos, "FirstName");
				ArrayInsertAt(coldArr[1],findNamePos+1, "MiddleName");
				ArrayInsertAt(coldArr[1],findNamePos+2, "LastName");

				StructDelete(fieldsDataStruct, 'FULLNAME')
				fieldsDataStruct['FirstName'] = 'FirstName';
				fieldsDataStruct['MiddleName'] = 'MiddleName';
				fieldsDataStruct['LastName'] = 'LastName';
			}
			catch (any excpt) {
				writeDump(excpt)
			}
		}
		tableHeader = arrayToList(arr);
		for(i=1;i<=arrayLen(arr);i++){
			coldArr[1][i] = arr[i];
		}
		qService = new query(); 
		qService.setDatasource("LicenseData"); 
		qService.setName("updateRows");
		qService.addParam(name="rows", value="#trim(tableHeader)#", cfsqltype="cf_sql_varchar");
		qService.addParam(name="fieldsData", value="#serializeJSON(fieldsDataStruct)#", cfsqltype="cf_sql_varchar");
		qService.addParam(name="id", value="#trim(getData.ID)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="namePos", value="#trim(findNamePos)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="cityStateZipPos", value="#trim(cityStateZipPos)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="updatedDate", value="#now()#", cfsqltype="cf_sql_integer");
		qService.setSql("
			UPDATE TBL_schedulerInfo
			SET
			headerRows = :rows,
			fieldsData = :fieldsData, 
			namePosition = :namePos,
			cityStateZipPos = :cityStateZipPos,
			UPDATED_DATE = :updatedDate
			WHERE ID = :id
		");
		qService.execute();
		tableHeader=ListAppend(tableHeader,"UUID",",");
		GetResults = QueryNew(tableHeader);
        headerRow = tableHeader;
	}else{
		fieldsDataStruct = deserializeJSON(getData.fieldsData);
		headerRow = getData.headerRows;
		headerRow=ListAppend(headerRow,"UUID",",");
		findNamePos = getData.namePosition;
		cityStateZipPos = getData.cityStateZipPos;
		GetResults = QueryNew(headerRow);
	}

    /* Checking if LicenseNumber is there in the the fieldsDataStructure, if it is there, then we are getting the column name for that, else it will be 0 */
    licenseNumberField = ((structKeyExists(fieldsDataStruct, "LicenseNumber")) ? fieldsDataStruct.LicenseNumber : 0);
	
	Rows = arraylen(coldArr);
	Fields = arraylen(listToArray(headerRow));
	for(thisRow=2; thisRow lte Rows; thisRow = thisRow + 1){
		queryaddrow(GetResults);
		nameReplaceFlag = true; // to make sure we replace the name only once in each row, otherwise it will keep happening for all the columns in the row
		cityStateZipRepFlag = true
       
		if(findNamePos){
			nameData = coldArr[thisRow][findNamePos];
		}
		if(cityStateZipPos){
			cityStateZipData = coldArr[thisRow][cityStateZipPos];
		}
		ArrayAppend(coldArr[thisRow],''); // to insert UUID
		
		for(thisField=1; thisField lte Fields; thisField = thisField + 1){
			try{
				if(cityStateZipPos && cityStateZipRepFlag){
					if(len(trim(cityStateZipData)) > 0){
						nameArr = ListToArray(cityStateZipData,',',false,false)
                  
						city =  nameArr[1];
						stateZipData = ListToArray(nameArr[2],' ',false,false);
						if(arrayLen(stateZipData) >= 2){
							state = stateZipData[1];
							zip = stateZipData[2];
						}
						
						ArrayDeleteAt(coldArr[thisRow],cityStateZipPos);
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos, city);
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos+1, state);
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos+2, zip);
						
					}else{
						ArrayDeleteAt(coldArr[thisRow],cityStateZipPos);
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos, '');
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos+1, '');
						ArrayInsertAt(coldArr[thisRow],cityStateZipPos+2, '');
					}
					cityStateZipRepFlag = false;
					
				}
				if(findNamePos && nameReplaceFlag){
					if(getData.fullNameFormat == 2){
						nameArr = ListToArray(nameData,',',false,false)
						
						LastName =  trim(nameArr[1]);
						FirstMiddleName = ListToArray(trim(nameArr[2]),' ',false,false);
						if(arrayLen(FirstMiddleName) >= 2){
							FirstName = trim(FirstMiddleName[1]);
							MiddleName = trim(FirstMiddleName[2]);
						}else{
							FirstName = trim(nameArr[2]);
							MiddleName = '';
						}
						
						ArrayDeleteAt(coldArr[thisRow],findNamePos);
						ArrayInsertAt(coldArr[thisRow],findNamePos, FirstName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+1, MiddleName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+2, LastName);
						nameReplaceFlag = false;
					}
					else if(getData.fullNameFormat == 1){
						nameArr = ListToArray(nameData,',',false,false)
						
						LastName =  trim(nameArr[2]);
						FirstMiddleName = ListToArray(trim(nameArr[1]),' ',false,false);
						if(arrayLen(FirstMiddleName) >= 2){
							FirstName = trim(FirstMiddleName[1]);
							MiddleName = trim(FirstMiddleName[2]);
						}else{
							FirstName = trim(nameArr[2]);
							MiddleName = '';
						}
						
						ArrayDeleteAt(coldArr[thisRow],findNamePos);
						ArrayInsertAt(coldArr[thisRow],findNamePos, FirstName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+1, MiddleName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+2, LastName);
						nameReplaceFlag = false;
					}
					else if(getData.fullNameFormat == 3){
						nameArr = ListToArray(nameData,' ',false,false)
						if(arrayLen(nameArr) == 3){
							FirstName = trim(nameArr[1]);
							MiddleName = trim(nameArr[2]);
							LastName =  trim(nameArr[3]);
						}
						else{
							FirstName = trim(nameArr[1]);
							MiddleName = '';
							LastName =  trim(nameArr[2]);
						}
						
						ArrayDeleteAt(coldArr[thisRow],findNamePos);
						ArrayInsertAt(coldArr[thisRow],findNamePos, FirstName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+1, MiddleName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+2, LastName);
						nameReplaceFlag = false;
					}
					else if(getData.fullNameFormat == 4 || getData.fullNameFormat == 6){
						nameArr = ListToArray(nameData,' ',false,false)
						if(arrayLen(nameArr) == 3){
							FirstName = trim(nameArr[2]);
							MiddleName = trim(nameArr[3]);
							LastName =  trim(nameArr[1]);
						}
						else{
							FirstName = trim(nameArr[2]);
							MiddleName = '';
							LastName =  trim(nameArr[1]);
						}
						
						ArrayDeleteAt(coldArr[thisRow],findNamePos);
						ArrayInsertAt(coldArr[thisRow],findNamePos, FirstName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+1, MiddleName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+2, LastName);
						nameReplaceFlag = false;
					}
					else if(getData.fullNameFormat == 5){
						nameArr = ListToArray(nameData,' ',false,false)
						if(arrayLen(nameArr) == 3){
							FirstName = trim(nameArr[2]);
							MiddleName = trim(nameArr[3]);
							LastName =  trim(nameArr[1]);
						}
						else{
							FirstName = trim(nameArr[2]);
							MiddleName = '';
							LastName =  trim(nameArr[1]);
						}
						
						ArrayDeleteAt(coldArr[thisRow],findNamePos);
						ArrayInsertAt(coldArr[thisRow],findNamePos, FirstName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+1, MiddleName);
						ArrayInsertAt(coldArr[thisRow],findNamePos+2, LastName);
						nameReplaceFlag = false;
					}
				}
				
				if(thisField != Fields){
					QuerySetCell(GetResults, coldArr[1][thisfield], coldArr[thisRow][thisfield]);
				}else{
					QuerySetCell(GetResults, 'UUID', CreateUUID());
				}
			}
			catch (any excpt) {
				writeDump(excpt)
			}
		}
	}

	if(getData.headerRowsProcessed == 0){

		matchedStructKeysListMain = StructKeyList(fieldsDataStruct); /*DB Columns Main*/
		matchedStructKeysArrMain = listToArray(matchedStructKeysListMain); 
		ArrayAppend(matchedStructKeysArrMain,'UUID',"true"); // Adding UUID

		valuesExcelMainArr = [];
		/* Getting Main Excel Columns from Main Columns */
		for (key in fieldsDataStruct) {
			ArrayAppend(valuesExcelMainArr, fieldsDataStruct[key], true);
		}
		ArrayAppend(valuesExcelMainArr,'UUID',"true"); // Adding UUID

		expirationColumns = ["LicenseNumber","ExpirationDate","CEDueDate"];
		matchedStructKeysArrExp = []
		acquiredDataColumns = ["LicenseUUID","LicenseNumber","FirstName","MiddleName","LastName"]
		matchedStructKeysArrAcq = []

		/* Getting Expiration Columns from Main Columns */
		for(i=1;i<=arrayLen(expirationColumns);i++){
			if(arrayFindNoCase(matchedStructKeysArrMain,expirationColumns[i])){
				ArrayAppend(matchedStructKeysArrExp,expirationColumns[i],"true");
			}
		}
		matchedStructKeysListExp = arrayToList(matchedStructKeysArrExp);

		/* Getting Expiration Excel Columns from Main Columns */
		valuesExcelExpArr = [];
		for (key in fieldsDataStruct) {
			if(arrayFindNoCase(matchedStructKeysArrExp,key)){
				ArrayAppend(valuesExcelExpArr, fieldsDataStruct[key], true);
			}
		}
		matchedStructValuesExpList = arrayToList(valuesExcelExpArr); /*Excel Columns Exp*/

		/* Getting Acquired Data Columns from Main Columns */
		for(i=1;i<=arrayLen(acquiredDataColumns);i++){
			if(arrayFindNoCase(matchedStructKeysArrMain,acquiredDataColumns[i])){
				ArrayAppend(matchedStructKeysArrAcq,acquiredDataColumns[i],"true");
			}
		}
		ArrayAppend(matchedStructKeysArrAcq,'LicenseUUID',"true"); // Adding UUID
		matchedStructKeysListAcq = arrayToList(matchedStructKeysArrAcq);

		/* Getting Acquires Data Excel Columns from Main Columns */
		valuesExcelAcqArr = [];
		for (key in fieldsDataStruct) {
			if(arrayFindNoCase(matchedStructKeysArrAcq,key)){
				ArrayAppend(valuesExcelAcqArr, fieldsDataStruct[key], true);
			}
		}
		ArrayAppend(valuesExcelAcqArr,'UUID',"true"); // Adding UUID
		matchedStructValuesAcqList = arrayToList(valuesExcelAcqArr); /*Excel Columns Exp*/

		/*Remove unwanted columns from the tables, 
		we cannot do this as it affects the other tables depending on main arr*/

		/* Remove ExpirationDate and CEDueDate if they are present in the Main Arr */
		if(arrayFindNoCase(matchedStructKeysArrMain,'ExpirationDate')){
			ArrayDeleteAt(matchedStructKeysArrMain,arrayFindNoCase(matchedStructKeysArrMain,'ExpirationDate'));
		}
		if(arrayFindNoCase(matchedStructKeysArrMain,'CEDueDate')){
			ArrayDeleteAt(matchedStructKeysArrMain,arrayFindNoCase(matchedStructKeysArrMain,'CEDueDate'));
		}

		/* Remove ExpirationDate and CEDueDate if they are present in the Main Values Arr */
		if(isdefined('fieldsDataStruct.ExpirationDate') && arrayFindNoCase(valuesExcelMainArr,fieldsDataStruct['ExpirationDate'])){
			ArrayDelete(valuesExcelMainArr,fieldsDataStruct['ExpirationDate']);
		}
		if(isdefined('fieldsDataStruct.CEDueDate') && arrayFindNoCase(valuesExcelMainArr,fieldsDataStruct['CEDueDate'])){
			ArrayDelete(valuesExcelMainArr,fieldsDataStruct['CEDueDate']);
		}
		matchedStructValuesMainList = arrayToList(valuesExcelMainArr); /*Excel Columns Exp*/
		matchedStructKeysListMain = arrayToList(matchedStructKeysArrMain); /*Excel Columns Main*/

	}
</cfscript>

<cfif getData.headerRowsProcessed EQ 0>
	<cfquery datasource="LicenseData" name="updateInfo">
		UPDATE TBL_schedulerInfo SET 
		<cfif matchedStructKeysListMain EQ ''>
			dataMatchedStructKeys = <cfqueryparam value="#matchedStructKeysListMain#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedStructKeys = <cfqueryparam value="#matchedStructKeysListMain#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructKeysListExp EQ ''>
			dataMatchedExpStructKeys = <cfqueryparam value="#matchedStructKeysListExp#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedExpStructKeys = <cfqueryparam value="#matchedStructKeysListExp#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructKeysListAcq EQ ''>
			dataMatchedAcqStructKeys = <cfqueryparam value="#matchedStructKeysListAcq#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedAcqStructKeys = <cfqueryparam value="#matchedStructKeysListAcq#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructValuesMainList EQ ''>
			dataMatchedStructValues = <cfqueryparam value="#matchedStructValuesMainList#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedStructValues = <cfqueryparam value="#matchedStructValuesMainList#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructValuesExpList EQ ''>
			dataMatchedExpStructValues = <cfqueryparam value="#matchedStructValuesExpList#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedExpStructValues = <cfqueryparam value="#matchedStructValuesExpList#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructValuesAcqList EQ ''>
			dataMatchedAcqStructValues = <cfqueryparam value="#matchedStructValuesAcqList#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedAcqStructValues = <cfqueryparam value="#matchedStructValuesAcqList#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		headerRowsProcessed = <cfqueryparam value="1" cfsqltype="CF_SQL_BIT" >
		WHERE ID = <cfqueryparam value="#trim(getData.ID)#" cfsqltype="cf_sql_integer" >
	</cfquery>
<cfelse>
	<cfset matchedStructKeysListMain = getData.dataMatchedStructKeys >
	<cfset matchedStructKeysArrMain = listToArray(matchedStructKeysListMain) >

	<cfset matchedStructKeysListExp = getData.dataMatchedExpStructKeys >
	<cfset matchedStructKeysArrExp = listToArray(matchedStructKeysListExp) >

	<cfset matchedStructKeysListAcq = getData.dataMatchedAcqStructKeys >
	<cfset matchedStructKeysArrAcq = listToArray(matchedStructKeysListAcq) >

	<cfset matchedStructValuesMainList = getData.dataMatchedStructValues>
	<cfset valuesExcelMainArr = listToArray(matchedStructValuesMainList) >

	<cfset matchedStructValuesExpList = getData.dataMatchedExpStructValues>
	<cfset valuesExcelExpArr = listToArray(matchedStructValuesExpList) >

	<cfset matchedStructValuesAcqList = getData.dataMatchedAcqStructValues>
	<cfset valuesExcelAcqArr = listToArray(matchedStructValuesAcqList) >
</cfif>

<cftry>
    <!--- Querying LicenseNumber column from GetResults column  --->
    <cfquery dbtype="query" name="getLicenseNumbers">
        SELECT #licenseNumberField# FROM GetResults
    </cfquery>
    <cfset licenseNumberValuesList = ''>
    <!--- Generating column valueList of LicenseNumber column from getLicenseNumbers column and storing it into licenseNumberValuesList --->
    <cfoutput>
        <cfloop query = "getLicenseNumbers">
            <cfloop array = "#getLicenseNumbers.getColumnList()#" index = columnName>
                <cfset licenseNumberValuesList=ListAppend(licenseNumberValuesList,getLicenseNumbers[columnName][currentrow],",") >
            </cfloop>
        </cfloop>
    </cfoutput>

    <cfquery datasource="LicenseData" name="getLicenseNumbersMain">
        SELECT LicenseNumber FROM #getData.MainTable# WHERE LicenseNumber IN (#licenseNumberValuesList#)
    </cfquery>

    <!--- Checking if recordcount of getLicenseNumbers > 0, if true we will save valuelist of LicenseNumber from main table into mainTableLicenseNumbersList 
    else we save null --->
    <cfset mainTableLicenseNumbersList = ( (getLicenseNumbersMain.recordCount GT 0) ? valueList(getLicenseNumbersMain.LicenseNumber) : '') >
	<cfset licenseNumberUpdatedList = ''>

    <cfif len(mainTableLicenseNumbersList) GT 0 >
        <cfset variables.mainTableLicenseNumbersArr = listToArray(mainTableLicenseNumbersList) >
        <cfset variables.licenseNumberValuesArr = listToArray(licenseNumberValuesList) >

        <cfloop from = "1" to="#arrayLen(variables.mainTableLicenseNumbersArr)#" index="i">
            <cfset variables.arrayPositionVal = arrayFind(variables.licenseNumberValuesArr,variables.mainTableLicenseNumbersArr[i]) >
            <cfif variables.arrayPositionVal >
                <cfset arrayDeleteAt(variables.licenseNumberValuesArr, variables.arrayPositionVal) >
            </cfif>
        </cfloop>
        <cfset licenseNumberUpdatedList = arrayToList(licenseNumberValuesArr) >
    </cfif>

	<!--- Debugging
	<cfdump var="#licenseNumberUpdatedList#"> 
	<cfdump  var="#getLicenseNumbers#">
	<cfdump var="#GetResults#">
	<cfdump  var="#getLicenseNumbersMain#" label = "Main table data" >--->
	<cfif listLen(licenseNumberUpdatedList) GT 0>
		<cfquery dbtype="query" name="GetResultsUpdated">
			SELECT * FROM GetResults WHERE #arrayToList(getLicenseNumbers.getColumnList())# IN (#licenseNumberUpdatedList#)
		</cfquery>
	
		<cfquery dbtype="query" name="matchedInfo">
			SELECT #matchedStructValuesMainList# FROM GetResultsUpdated
		</cfquery>

		<cfquery dbtype="query" name="matchedExpInfo">
			SELECT #matchedStructValuesExpList# FROM GetResultsUpdated
		</cfquery>

		<cfquery dbtype="query" name="matchedAcqInfo">
			SELECT #matchedStructValuesAcqList# FROM GetResultsUpdated
		</cfquery>
 	<cfelseif getLicenseNumbersMain.recordCount EQ 0> 
		<cfquery dbtype="query" name="matchedInfo">
			SELECT #matchedStructValuesMainList# FROM GetResults
		</cfquery>

		<cfquery dbtype="query" name="matchedExpInfo">
			SELECT #matchedStructValuesExpList# FROM GetResults
		</cfquery>

		<cfquery dbtype="query" name="matchedAcqInfo">
			SELECT #matchedStructValuesAcqList# FROM GetResults
		</cfquery>
	</cfif>

	<cfcatch type="any">
		<cfdump var="#cfcatch#">
	</cfcatch>
</cftry>
 
<cfscript>
	if(isdefined("nextCSVline") && nextCSVline != ''){
        if(startRow == 1){
			loopingRow = --currentRow;
		}else{
			loopingRow = currentRow;
		}
        qService = new query(); 
		qService.setDatasource("LicenseData"); 
		qService.setName("updateLoopingRow");
		qService.addParam(name="loopRow", value="#trim(loopingRow)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="id", value="#trim(getData.ID)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="updatedDate", value="#now()#", cfsqltype="cf_sql_integer");
		qService.setSql("
			UPDATE TBL_schedulerInfo
			SET
			loopingRow = :loopRow,
			UPDATED_DATE = :updatedDate
			WHERE ID = :id
		");
		qService.execute();
    }else{
        loopingRow = currentRow;
        qService = new query(); 
		qService.setDatasource("LicenseData"); 
		qService.setName("updateLoopingRow");
		qService.addParam(name="loopRow", value="#trim(loopingRow)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="id", value="#trim(getData.ID)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="cmpStatus", value="1", cfsqltype="cf_sql_bit");
		qService.addParam(name="updatedDate", value="#now()#", cfsqltype="cf_sql_integer");
		qService.setSql("
			UPDATE TBL_schedulerInfo
			SET
			loopingRow = :loopRow,
			UPDATED_DATE = :updatedDate,
			completedStatus = :cmpStatus
			WHERE ID = :id
		");
        qService.execute();
    }
	</cfscript>

	<cfif isdefined('matchedInfo') AND matchedInfo.recordCount GT 0>
		<cfquery datasource="LicenseData" name="insertMainTableData">
			INSERT INTO #getData.MainTable# (#matchedStructKeysListMain#) values 
			<cfoutput query="matchedInfo">
				(
				<cfloop from="1" to="#arraylen(valuesExcelMainArr)#" index="i">
					<cfset currentPosition = matchedInfo[valuesExcelMainArr[i]]>
					<cfif currentPosition EQ ''><cfqueryparam value="" cfsqltype="CF_SQL_VARCHAR" null="true"><cfelse><cfqueryparam value="#currentPosition#" cfsqltype="CF_SQL_VARCHAR"></cfif><cfif i NEQ arraylen(valuesExcelMainArr)>,</cfif>
				</cfloop>
				)<cfif matchedInfo.currentRow NEQ matchedInfo.recordCount>,</cfif>
			</cfoutput>
		</cfquery>
	</cfif>

	<cfif isdefined('matchedExpInfo') AND matchedExpInfo.recordCount GT 0>
		<cfquery datasource="LicenseData" name="insertExpTableData">
			INSERT INTO #getData.ExpirationTable# (#matchedStructKeysListExp#) values 
			<cfoutput query="matchedExpInfo">
				(
				<cfloop from="1" to="#arraylen(valuesExcelExpArr)#" index="i">
					<cfset currentPosition = matchedExpInfo[valuesExcelExpArr[i]]>
					<cfif currentPosition EQ ''><cfqueryparam value="" cfsqltype="CF_SQL_VARCHAR" null="true"><cfelse><cfqueryparam value="#currentPosition#" cfsqltype="CF_SQL_VARCHAR"></cfif><cfif i NEQ arraylen(valuesExcelExpArr)>,</cfif>
				</cfloop>
				)<cfif matchedExpInfo.currentRow NEQ matchedExpInfo.recordCount>,</cfif>
			</cfoutput>
		</cfquery>
	</cfif>

	<cfif isdefined('matchedAcqInfo') AND matchedAcqInfo.recordCount GT 0>
		<cfquery datasource="LicenseData" name="insertAcqInfoData">
			INSERT INTO #getData.AcqDataTable# (#matchedStructKeysListAcq#) values 
			<cfoutput query="matchedAcqInfo">
				(
				<cfloop from="1" to="#arraylen(valuesExcelAcqArr)#" index="i">
					<cfset currentPosition = matchedAcqInfo[valuesExcelAcqArr[i]]>
					<cfif currentPosition EQ ''><cfqueryparam value="" cfsqltype="CF_SQL_VARCHAR" null="true"><cfelse><cfqueryparam value="#currentPosition#" cfsqltype="CF_SQL_VARCHAR"></cfif><cfif i NEQ arraylen(valuesExcelAcqArr)>,</cfif>
				</cfloop>
				)<cfif matchedAcqInfo.currentRow NEQ matchedAcqInfo.recordCount>,</cfif>
			</cfoutput>
		</cfquery>
	</cfif>

	<cfsetting enablecfoutputonly="No">
	<cfdump var="#GetResults#">
</cfif>