<cfscript>    
    component displayname="LicenseDataProject" output="false"{
        remote any function getHeaderRowData (any id){
            getPageContext().getResponse().setContentType("text/plain");
            //writeDump(arguments.id);abort;
            /*Decrpt the ID we got from the request*/
            idDecrypted = decrypt(arguments.id,"l80yTxCYSSk=", "DES", "Base64");
            /**
             * Get Header row from the passed ID
             */
            qService = new query(); 
            qService.setDatasource("LicenseData"); 
            qService.setName("getRows");
            qService.addParam(name="id", value="#idDecrypted#", cfsqltype="cf_sql_integer");
            qService.setSql("SELECT TOP 1 headerRows FROM TBL_schedulerInfo WHERE ID = :id ORDER BY ID DESC");
            result = qService.execute();
            headerRowRes = result.getResult()
            metaInfo = result.getPrefix(); 
            
            if(metaInfo.recordCount > 0){
               
                headerRowData = valueList(headerRowRes.headerRows);
                data = {
                    "headerDataValue" : "#headerRowData#"
                }
                return serializeJSON(data);
            }else{
                return ''
            }

        }
    }
</cfscript>