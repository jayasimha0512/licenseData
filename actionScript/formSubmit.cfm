<cfsetting showDebugOutput="No">

<cftry>
    <cfset path = ExpandPath( "../csvFiles") >
    <cfif not directoryExists(path)>
        <cfdirectory action="create" directory="#path#">
    </cfif>

    <cfset dest = getTempDirectory()>
    <!---Set upload file name--->
        <!---check if the file exist to validate--->
    <cffile action="upload" destination="#dest#" filefield="Form.EXCELDATA" result="upload" nameconflict="makeunique"> 
    <cfif upload.fileWasSaved>
    <cfset theFile = upload.serverDirectory & "/" & upload.serverFile>
    </cfif>

    <cfset ranNum = randRange(100000,200000)>

    <cfif upload.SERVERFILEEXT EQ 'xlsx' OR upload.SERVERFILEEXT EQ 'xls'>
        <cfset fileName = 'createdCSV'&ranNum&'.csv' />
        <cfspreadsheet action="read" src = "#theFile#" format="csv" name="csvdata" >
        <cffile action="write" file="#path#/#fileName#" output="#csvdata#">

    <cfelseif upload.SERVERFILEEXT EQ 'txt'>
        <cfset fileName = 'createdCSV'&ranNum&'.csv' />
        <cffile action="read" file = "#theFile#" variable="inputData" >
        <cfset findPipe = Find("|", inputData) >
        <cfset findComma = Find(",", inputData) >
        <cfif findPipe EQ 0>
            <cfset dataFormat = 'comma'>
        <cfelseif findComma EQ 0>
            <cfset dataFormat = 'pipe'>
        <cfelseif findPipe GT findComma>
            <cfset dataFormat = 'comma'>
        <cfelse>
            <cfset dataFormat = 'pipe'>
        </cfif>

        <cffile action="write" file="#path#/#fileName#" output="" >
        <cfscript>
            // Function to split a row while preserving empty cells and handling quoted fields
            function splitPreserveEmptyCells(str, delimiter) {
                var result = [];
                var temp = "";
                var i = 1;
                while (i <= len(str)) {
                    if (mid(str, i, 1) eq delimiter) {
                        arrayAppend(result, temp);
                        temp = "";
                    } else {
                        temp &= mid(str, i, 1);
                    }
                    i++;
                }
                arrayAppend(result, temp); // Add the last element
                return result;
            }
        </cfscript>
        <cfif dataFormat EQ 'comma'>
        
            <cfscript>
                // Define the paths to the input text file and output CSV file
                inputFilePath = "#theFile#";

                outputFilePath = "#path#/#fileName#";

                // Read the content of the input text file
                fileContent = FileRead(inputFilePath);

                // Split the content into lines (rows)
                rows = ListToArray(fileContent, Chr(10)); // Chr(10) is the newline character

                // Initialize an empty string to hold the CSV data
                csvData = "";

                // Process each line (row)
                for (row in rows) {
                    // Split the row into columns while preserving empty cells
                    columns = splitPreserveEmptyCells(row, ",");
                    // Join the columns into a single CSV line
                    csvLine = ArrayToList(columns, ",");
                    // Add the CSV line to the CSV data string
                    csvData &= csvLine ;
                }
                // Write the CSV data to the output file
                FileWrite(outputFilePath, csvData);

            </cfscript>
        <cfelse>
            <cfscript>
                // Define the paths to the input text file and output CSV file
                inputFilePath = "#theFile#";
                outputFilePath = "#path#/#fileName#";
            
                // Read the content of the input text file
                fileContent = FileRead(inputFilePath);
            
                // Split the content into lines (rows)
                rows = ListToArray(fileContent, Chr(10)); // Chr(10) is the newline character
            
                // Initialize an empty string to hold the CSV data
                csvData = "";       
        
                // Process each line (row)
                for (row in rows) {
                    // Trim the row to remove any extra newlines or spaces
                    row = trim(row);
                    // Skip empty rows
                    if (len(row) eq 0) {
                        continue;
                    }
                    // Split the row into columns while preserving empty cells and handling quoted fields
                    columns = splitPreserveEmptyCells(row, "|");
                    

                    // Join the columns into a single CSV line
                    for (i = 1; i <= arrayLen(columns); i++) {
                            if (find(",", columns[i])) {
                                columns[i] = '"' & (columns[i]) & '"';
                            }
                        }
                        csvLine = arrayToList(columns, ",");
                
                    // Add the CSV line to the CSV data string
                    csvData &= csvLine & Chr(13) & Chr(10);
            
                }
            
                // Write the CSV data to the output file
                FileWrite(outputFilePath, csvData);
            </cfscript>
        </cfif>
    <cfelseif upload.SERVERFILEEXT EQ 'csv'>
        <cfset TITLE = replace(upload.serverFileName," ","_","All") />
        <cfset fileName = ListAppend(TITLE&ranNum,upload.CLIENTFILEEXT,'.')>
        <cffile action = "rename" source = "#theFile#" destination = "#path#/#fileName#">
    </cfif>

    <cfscript>
        fileReader = createobject("java","java.io.FileReader");
        fileReader.init('#path#/#fileName#');
        csvReader = createObject("java","com.opencsv.CSVReader");
        csvReader.init(fileReader);
        ArrData = csvReader.readAll();
        csvReader.close();
        fileReader.close();
    </cfscript>

    <cffile action="read" file="#path#/#fileName#" variable="csvfile">
    <cfset csvLines = ListToArray(csvfile,chr(13))>
    <cfset firstLine = csvLines[1] >
    <cfset headerRowInfo = replaceNoCase(replaceNoCase(replaceNoCase(firstLine,', ','_','all'),' ','_','all'),'"','','all') >

    <cfset mainTable  = trim(form.industry) & '_' & trim(form.judiciary) & '_Main'>
    <cfset expirationTable  = trim(form.industry) & '_' & trim(form.judiciary) & '_Expiration'>
    <cfset acqDataTable  = trim(form.industry) & '_' & trim(form.judiciary) & '_Acquired_Data'>

    <cfquery datasource="LicenseData" name="checkMainTable">
        SELECT * 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'dbo' 
        AND  TABLE_NAME = '#mainTable#'
    </cfquery>
    <cfquery datasource="LicenseData" name="checkExpTable">
        SELECT * 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'dbo' 
        AND  TABLE_NAME = '#expirationTable#'
    </cfquery>
    <cfquery datasource="LicenseData" name="checkAcqDataTable">
        SELECT * 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'dbo' 
        AND  TABLE_NAME = '#acqDataTable#'
    </cfquery>

    <cfquery datasource="LicenseData" name="getTableKeys">
        select ColumnName,ColumnDataType,ColumnDefault from TableKey
    </cfquery>

    <cfsavecontent variable="mainTableContent">
        <cfset i = 1>
        <cfoutput>
            <cfloop query="getTableKeys">
                #getTableKeys.ColumnName# #getTableKeys.ColumnDataType# DEFAULT <cfif LEN(trim(getTableKeys.ColumnDefault)) EQ 0>NULL<cfelse>#getTableKeys.ColumnDefault#</cfif><cfif i NEQ getTableKeys.recordCount>,</cfif>
                <cfset i++>
            </cfloop>
        </cfoutput>
    </cfsavecontent>

    <cfif checkMainTable.recordCount LT 1 >
        <cfquery datasource="LicenseData" name="createMainTable">
            CREATE TABLE [dbo].[#mainTable#] (
                #mainTableContent#
            )ON [PRIMARY]
        </cfquery>
    <cfelse>
        <cfif isDefined('form.infoAction') AND form.infoAction EQ 1>
            <cfquery datasource="LicenseData" name="createMainTable">
                exec sp_rename 'dbo.#mainTable#', '#mainTable#_#DateFormat(now(),"yyyymmdd")#'
            </cfquery>
            <cfquery datasource="LicenseData" name="createMainTable">
                CREATE TABLE [dbo].[#mainTable#] (
                    #mainTableContent#
                )ON [PRIMARY]
            </cfquery>
        </cfif>
    </cfif>
    <cfif checkExpTable.recordCount LT 1>
        <cfquery datasource="LicenseData" name="createExpTable">
            CREATE TABLE [dbo].[#expirationTable#](
                [ID] [int] IDENTITY(1,1) NOT NULL,
                [LicenseNumber] [nvarchar](100) NULL,
                [ExpirationDate] [date] NULL,
                [CEDueDate] [date] NULL
            ) ON [PRIMARY]
        </cfquery>
    </cfif>
    <cfif checkAcqDataTable.recordCount LT 1>
        <cfquery datasource="LicenseData" name="createAcqDataTable">
            CREATE TABLE [dbo].[#acqDataTable#](
                [ID] [int] IDENTITY(1,1) NOT NULL,
                [LicenseUUID] [nvarchar](50) NULL,
                [LicenseNumber] [nvarchar](100) NULL,
                [FirstName] [nvarchar](100) NULL,
                [MiddleName] [nvarchar](100) NULL,
                [LastName] [nvarchar](100) NULL
            ) ON [PRIMARY]
        </cfquery>
    </cfif>
    <cfquery datasource="LicenseData" name="createSchedularQuery" result="getIDData">
        INSERT INTO TBL_schedulerInfo (fileName,industry,judiciary,totalRows,MainTable,ExpirationTable,AcqDataTable,InfoAction,headerRows,CREATED_DATE)
        values ('#fileName#','#form.industry#','#form.judiciary#',#arrayLen(ArrData)#,'#mainTable#','#expirationTable#','#acqDataTable#','#form.infoAction#','#headerRowInfo#',getdate())
    </cfquery>
    <cfset encryptyedID =  encrypt(getIDData.IDENTITYCOL, "l80yTxCYSSk=", "DES", "Base64")>
    <cfoutput>#serializeJSON({"result":"success","dataID":"#encryptyedID#"})#</cfoutput>
    <cfcatch type="any"><cfdump var="#cfcatch#"><!---<cfoutput>#serializeJSON({"result":"failed"})#</cfoutput>---></cfcatch>
</cftry>