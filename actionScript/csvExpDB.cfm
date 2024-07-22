<cfquery datasource="LicenseData" name="getData">
	SELECT TOP 1 * from TBL_schedulerInfo WHERE completedStatus = 0 AND InfoAction = 2;
</cfquery>

	<cfscript>
		if(getData.recordCount > 0){
			csvName = getData.fileName;
		}
		path = ExpandPath( "\");
        
		CSVFile = "#path#/licenseData/csvfiles/#csvName#";
		fileReader = createobject("java","java.io.FileReader");
		fileReader.init(CSVFile);
		csvReader = createObject("java","com.opencsv.CSVReader");
		csvReader.init(fileReader);
		batchSize = 100;
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
				//writeDump(nextCSVline)
				//ArrData = csvReader.readAll();
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
		
		writeDump(coldArr)
		csvReader.close();
		fileReader.close();
	</cfscript>
	
	<cfscript>
      
	if(startRow == 1){
		arr = coldArr[1];
			
		for(i=1;i<=arrayLen(arr);i++){
			arr[i]= ucase(replace(replace(replace(arr[i]," ","_", "all"),"-","", "all"),",","", "all"));
		}
        fieldsDataStruct = deserializeJSON(getData.fieldsData);

		tableHeader = arrayToList(arr);

		qService = new query(); 
		qService.setDatasource("LicenseData"); 
		qService.setName("updateRows");
		qService.addParam(name="rows", value="#trim(tableHeader)#", cfsqltype="cf_sql_varchar");
		qService.addParam(name="id", value="#trim(getData.ID)#", cfsqltype="cf_sql_integer");
		qService.addParam(name="updatedDate", value="#now()#", cfsqltype="cf_sql_integer");
		qService.setSql("
		UPDATE TBL_schedulerInfo
		SET
		headerRows = :rows,
		UPDATED_DATE = :updatedDate
		WHERE ID = :id
		");
		qService.execute();

		for(i=1;i<=arrayLen(arr);i++){
			coldArr[1][i] = arr[i];
		}
		GetResults = QueryNew(ArrayToList(coldArr[1]));
        headerRow = ArrayToList(coldArr[1]);
	}else{
		headerRow = getData.headerRows;
		fieldsDataStruct = deserializeJSON(getData.fieldsData);
		GetResults = QueryNew(headerRow);
	}
	if(getData.headerRowsProcessed == 0){ //checking if we have stored the details of matched rows in DB
		matchedStructKeysListMain = StructKeyList(fieldsDataStruct); /*DB Columns Main*/
		matchedStructKeysArrMain = listToArray(matchedStructKeysListMain); 

		valuesExcelMainArr = [];
		/* Getting Main Excel Columns from Main Columns */
		for (key in fieldsDataStruct) {
			ArrayAppend(valuesExcelMainArr, fieldsDataStruct[key], true);
		}

		expirationColumns = ["LicenseNumber","ExpirationDate","CEDueDate"];
		matchedStructKeysArrExp = []

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
	}
</cfscript>
<cfif getData.headerRowsProcessed EQ 0>

	<cfquery datasource="LicenseData" name="updateInfo">
		UPDATE TBL_schedulerInfo SET 
		<cfif matchedStructKeysListExp EQ ''>
			dataMatchedExpStructKeys = <cfqueryparam value="#matchedStructKeysListExp#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedExpStructKeys = <cfqueryparam value="#matchedStructKeysListExp#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		<cfif matchedStructValuesExpList EQ ''>
			dataMatchedExpStructValues = <cfqueryparam value="#matchedStructValuesExpList#" cfsqltype="CF_SQL_VARCHAR" null="true">,
		<cfelse>
			dataMatchedExpStructValues = <cfqueryparam value="#matchedStructValuesExpList#" cfsqltype="CF_SQL_VARCHAR" >,
		</cfif>
		headerRowsProcessed = <cfqueryparam value="1" cfsqltype="CF_SQL_BIT" >
		WHERE ID = <cfqueryparam value="#trim(getData.ID)#" cfsqltype="cf_sql_integer" >
	</cfquery> 

<cfelse>

	<cfset matchedStructKeysListExp = getData.dataMatchedExpStructKeys >
	<cfset matchedStructKeysArrExp = listToArray(matchedStructKeysListExp) >
	
	<cfset matchedStructValuesExpList = getData.dataMatchedExpStructValues>
	<cfset valuesExcelExpArr = listToArray(matchedStructValuesExpList) >

</cfif>



<cfscript>
	Rows = arraylen(coldArr);
	Fields = arraylen(listToArray(headerRow));
	for(thisRow=2; thisRow lte Rows; thisRow = thisRow + 1){
		queryaddrow(GetResults);
       
		for(thisField=1; thisField lte Fields; thisField = thisField + 1){
			try{
				QuerySetCell(GetResults, coldArr[1][thisfield], coldArr[thisRow][thisfield]);
			}
			catch (any excpt) {
				writeDump(excpt)
			}
		}
	}
	
	if(isdefined("nextCSVline") && nextCSVline != ''){
		if(startRow == 1){
			loopingRow = --currentRow;
		}else{
			loopingRow = currentRow;
		}
        loopingRow = currentRow;
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
        loopingRow = --currentRow;
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

	<cfset ExpirationDatePos = arrayFind(matchedStructKeysArrExp,'ExpirationDate') >
	<cfset CEDueDatePos = arrayFind(matchedStructKeysArrExp,'CEDueDate') >
	<cfset LicenseNumberPos = arrayFind(matchedStructKeysArrExp,'LicenseNumber') >

	<cfquery dbtype="query" name="matchedExpInfo">
		SELECT #matchedStructValuesExpList# FROM GetResults
	</cfquery>

<cfoutput query="matchedExpInfo">
	<cfquery datasource="LicenseData" name="insertExpTableData">
		UPDATE #getData.ExpirationTable# SET 
		<cfif ExpirationDatePos GT 0>
			<cfset ExpirationDateVal = matchedExpInfo[valuesExcelExpArr[ExpirationDatePos]] >
			<cfset tempDate = createODBCDateTime(now())>
			ExpirationDate = <cfqueryparam value="#tempDate#" cfsqltype="CF_SQL_DATE">,
		<cfelse>
			ExpirationDate = <cfqueryparam value="" cfsqltype="CF_SQL_DATE" null="true">,
		</cfif>
		<cfif CEDueDatePos GT 0>
			<cfset CEDueDateVal = matchedExpInfo[valuesExcelExpArr[CEDueDatePos]] >
			CEDueDate = <cfqueryparam value="#CEDueDateVal#" cfsqltype="CF_SQL_DATE">
		<cfelse>
			CEDueDate = <cfqueryparam value="" cfsqltype="CF_SQL_DATE" null="true">
		</cfif>
		<cfset LicenseNumberVal = matchedExpInfo[valuesExcelExpArr[LicenseNumberPos]] >
		WHERE LicenseNumber = <cfqueryparam value="#LicenseNumberVal#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
</cfoutput>