option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim documentType, hasDocumentType
dim document, documents, documentList
dim openMethod
dim cvwSelectDialog

' Current values
set currentModel = metis.currentModel
set currentModelView = currentModel.currentModelView
set currentInstance = currentModel.currentInstance
set currentInstanceView = currentModelView.currentInstanceView

' Types
set documentType    = metis.findType("http://xml.chalmers.se/class/cc_document.kmd#CC_document")
set hasDocumentType = metis.findType("metis:stdtypes#oid121")

' Methods
set openMethod = metis.findMethod("metis:stdmethods#oid5")

' Main code
set documentList = currentInstance.getNeighbourObjects(0, hasDocumentType, documentType)
if isValid(documentList) then
    if documentList.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select dialog"
        cvwSelectDialog.heading = "Select document"
        set documents = cvwSelectDialog.show(documentList)
        if documents.count > 0 then
            set document = documents(1)
        end if
    elseif documentList.count = 1 then
        set document = documentList(1)
    end if
    if isEnabled(document) then
        call currentModel.runMethodOnInst(openMethod, document)
    end if
    set cvwSelectDialog = Nothing
else
    MsgBox "No documents references!"
end if

