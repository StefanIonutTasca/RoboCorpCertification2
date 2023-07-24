*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             DateTime
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             String


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${image_directory}=         ${OUTPUT_DIR}${/}images/
${zip_directory}=           ${OUTPUT_DIR}${/}


*** Tasks ***
Download the orders file, read it as a table, and return the result
    Open the robot order website
    Click OK
    Download the Excel file
    Fill in the order form using the data from the csv file
    Archive receipts as a ZIP    ${receipt_directory}    ${zip_directory}receipts.zip
    Close the browser and delete temporary files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Click OK
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    css:.btn-dark

Fill the form for one order
    [Arguments]    ${orders}
    Wait Until Page Contains Element    class:form-group
    Select From List By Index    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    2min    500ms    Make order

Make order
    Click Button    Order
    Page Should Contain Element    id:receipt

Fill in the order form using the data from the csv file
    ${orders}=    Read table from CSV    path=orders.csv
    FOR    ${order}    IN    @{orders}
        Fill the form for one order    ${order}
        Save order details
        Wait Until Element Is Visible    id:order-another
        Click Button    order-another
        Click OK
    END

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}
    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Combine receipt with robot image to a PDF    ${receipt_filename}    ${image_filename}

Combine receipt with robot image to a PDF
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_filename}
    Close Pdf

Close the browser and delete temporary files
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}
    [Teardown]    Close Browser

Archive receipts as a ZIP
    [Arguments]    ${receipts_dir}    ${output_zip_file}
    Archive Folder With Zip    ${receipts_dir}    ${output_zip_file}
