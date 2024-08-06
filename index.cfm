<cfsetting showDebugOutput="No">
<cfquery datasource="LicenseData" name="getIndustries">
    SELECT Industry_Name FROM Industries
</cfquery>
<cfquery datasource="LicenseData" name="getJurisdictions">
    SELECT Jurisdiction_Name FROM Jurisdictions
</cfquery>
<cfquery datasource="LicenseData" name="getColumnNames">
    SELECT ColumnName from TableKey WHERE ColumnName NOT IN ('Custom1','Custom2','Custom3','Active','UUID');
</cfquery>

<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Bootstrap demo</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    </head>
    <body>
        <div class="container">
            <header class="d-flex flex-wrap justify-content-center py-3 mb-4 border-bottom">
                <a href="/" class="d-flex align-items-center mb-3 mb-md-0 me-md-auto link-body-emphasis text-decoration-none">
                  <svg class="bi me-2" width="40" height="32"><use xlink:href="#bootstrap"></use></svg>
                  <span class="fs-4">Simple header</span>
                </a>
                
                <ul class="nav nav-pills">
                  <li class="nav-item"><a href="#" class="nav-link active" aria-current="page">Home</a></li>
                  <li class="nav-item"><a href="#" class="nav-link">Features</a></li>
                  <li class="nav-item"><a href="#" class="nav-link">Pricing</a></li>
                  <li class="nav-item"><a href="#" class="nav-link">FAQs</a></li>
                  <li class="nav-item"><a href="#" class="nav-link">About</a></li>
                </ul>
            </header>
            <div class="row d-flex justify-content-center">
                <div class="col-md-8">
                    <form class="row g-3" action="actionScript/formSubmit.cfm" method="post" id="submitData" name="submitData" enctype="multipart/form-data">
                        <div id="alertsDiv"></div>
                        <div class="col-md-6">
                            <label for="indudustry" class="form-label">Industry</label>
                            <select id="indudustry" class="form-select" name="industry">
                                <option value="" disabled selected>Select your option</option>
                                <option>Cosmetology</option>
                                <cfoutput query="getIndustries">
                                    <option>#getIndustries.Industry_Name#</option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label for="judiciary" class="form-label">Judiciary</label>
                            <select id="judiciary" class="form-select" name="judiciary">
                                <option value="" disabled selected>Select your option</option>
                                <cfoutput query="getJurisdictions">
                                    <option>#getJurisdictions.Jurisdiction_Name#</option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label for="infoAction" class="form-label">Action</label>
                            <select id="infoAction" class="form-select" name="infoAction">
                                <option value="" disabled selected>Select your option</option>
                                <option value="1">Add Data (New table)</option>
                                <option value="2">Update Expiration Info</option>
                                <option value="3">Add Data (Existing table)</option>
                                <option value="4">Insert Only New Data from the File</option>
                            </select>
                        </div>
                        <div class="col-12">
                            <label for="excelData" class="form-label">Import Data</label>
                            <input class="form-control" type="file" id="excelData" name="excelData" accept=".csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel,text/plain">
                        </div>
                        <div class="col-12">
                            <button type="button" name="upload" value="upload" id="upload" class="btn btn-primary">Upload</button>
                        </div>
                    </form>

                </div>
            </div>
            <div class="row d-flex justify-content-center mt-4">
                <div class="col-md-8">
                    <form class="row g-3" action="actionScript/formFieldsInsert.cfm" method="post" id="submitFieldsData" name="submitFieldsData" enctype="multipart/form-data">
                        <cfoutput>
                            <div class="col-md-4">
                                <label for="field_fullName" class="form-label">Full Name</label>
                            </div>
                            <div class="col-md-8">
                                <select id="fullName" class="form-select rowsOptions" name="field_fullName">
                                    <option value="" disabled selected>Select your option</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="fullNameFormat" class="form-label">Full Name Format</label>
                            </div>
                            <div class="col-md-8">
                                <select id="fullNameFormat" class="form-select" name="fullNameFormat">
                                    <option value="" disabled selected>Select your option</option>
                                    <option value="1">First Middle,Last</option>
                                    <option value="2">Last, First Middle</option>
                                    <option value="3">First Middle Last</option>
                                    <option value="4">Last First Middle</option>
                                    <option value="5">First Last</option>
                                    <option value="6">Last First</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="field_cityStateZipcode" class="form-label">City State Zipcode</label>
                            </div>
                            <div class="col-md-8">
                                <select id="cityStateZipcode" class="form-select rowsOptions" name="field_cityStateZipcode">
                                    <option value="" disabled selected>Select your option</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="field_ExpirationDate" class="form-label">ExpirationDate</label>
                            </div>
                            <div class="col-md-8">
                                <select id="ExpirationDate" class="form-select rowsOptions" name="field_ExpirationDate">
                                    <option value="" disabled selected>Select your option</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="field_CEDueDate" class="form-label">CEDueDate</label>
                            </div>
                            <div class="col-md-8">
                                <select id="CEDueDate" class="form-select rowsOptions" name="field_CEDueDate">
                                    <option value="" disabled selected>Select your option</option>
                                </select>
                            </div>
                            <cfloop query="getColumnNames">
                                <div class="col-md-4">
                                    <label for="field_#getColumnNames.ColumnName#" class="form-label">#getColumnNames.ColumnName#</label>
                                </div>
                                <div class="col-md-8">
                                    <select id="#getColumnNames.ColumnName#" class="form-select rowsOptions" name="field_#getColumnNames.ColumnName#">
                                        <option value="" disabled selected>Select your option</option>
                                    </select>
                                </div>
                            </cfloop>
                            <input type="hidden" value="" name="colId" id="colId">
                            <div class="col-12">
                                <button type="button" name="uploadFields" value="uploadFields" id="uploadFields" class="btn btn-primary">Upload</button>
                            </div>
                        </cfoutput>
                    </form>
                </div>
            </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
        <script>
            const alertPlaceholder = document.getElementById('submitData')
            document.querySelector("#submitFieldsData").style.display = 'none';
            
            const appendAlert = (message, type) => {
                const wrapper = document.getElementById('alertsDiv')
                let newAlert = [
                    `<div class="alert alert-${type} alert-dismissible" role="alert">`,
                    `   <div>${message}</div>`,
                    '   <button type="button" id="alertClose" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>',
                    '</div>'
                ].join('')
                alertsDiv.innerHTML += newAlert;
                //alertPlaceholder.prepend(wrapper)
            }
            
            document.querySelector('#upload').addEventListener('click', async function(e){
                if(!(document.querySelector('#infoAction').value) || !(document.querySelector('#judiciary').value) || !(document.querySelector('#indudustry').value)){
                    if(typeof(document.querySelector('#alertClose')) != 'undefined' && document.querySelector('#alertClose') != null){
                        document.querySelector('#alertClose').click();
                    }
                    appendAlert('Please fill all the fields in the form!', 'danger');
                    return false;
                }
                else if(!(document.querySelector('#excelData').value)){
                    if(typeof(document.querySelector('#alertClose')) != 'undefined' && document.querySelector('#alertClose') != null){
                        document.querySelector('#alertClose').click();
                    }
                    document.querySelector('#excelData').click();
                    appendAlert('Please add a file to upload.', 'danger');
                    return false;
                }
                const regInfo = document.querySelector("#submitData");
                const formData = new FormData(regInfo);
    
                const response = await fetch("http://127.0.0.1:8500/licenseData/actionScript/formSubmit.cfm", {
                  method: "POST",
                  body: formData,
                });
                let res = (await response.json());
                if(res.result == 'success'){
                    document.querySelector("#submitFieldsData").style.display = 'flex';
                    if(typeof(document.querySelector('#alertClose')) != 'undefined' && document.querySelector('#alertClose') != null){
                        document.querySelector('#alertClose').click();
                    }
                    document.querySelector('#excelData').value = '';
                    document.querySelector('#infoAction').value = '';
                    document.querySelector('#judiciary').value = '';
                    document.querySelector('#indudustry').value = '';
                    appendAlert('File has beed uploaded! Data will be added soon!', 'success');
                    document.getElementById('colId').value = res.dataID;
                    const headerRowsReq = await fetch("http://127.0.0.1:8500/licenseData/cfc/getHeaderRows.cfc?method=getHeaderRowData&returnFormat=plain&id="+encodeURIComponent(res.dataID), {
                        method: "GET",
                    }).then(res => res.json())
                    .then(data => {
                        const options = data.headerDataValue.split(',');
                       
                        document.querySelectorAll('.rowsOptions').forEach((selectEle) => {
                            options.forEach((element) => {
                                var opt = document.createElement("option");
                                opt.text = element;
                                opt.value = element;
                                selectEle.appendChild(opt); // Append the option to each element
                            });
                        });
                    });
                    
                   
                }else{
                    appendAlert('File has not beed uploaded! Please contact support.', 'danger');
                }
            })
            document.querySelector('#uploadFields').addEventListener('click', async function(e){
                const fieldsInfo = document.querySelector("#submitFieldsData");
                const formData = new FormData(fieldsInfo);

                const response = await fetch("http://127.0.0.1:8500/licenseData/actionScript/formFieldsInsert.cfm", {
                  method: "POST",
                  body: formData,
                }).then(res => res.json())
                .then(data => {
                    if(data.result == 'success'){
                        document.querySelectorAll('.rowsOptions').forEach((selectEle) => {
                            selectEle.value = '';
                        });
                        fieldsInfo.style.display = 'none';
                    }
                });
            });
        </script>
    </body>
</html>
