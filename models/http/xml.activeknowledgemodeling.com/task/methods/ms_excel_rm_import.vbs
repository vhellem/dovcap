Option Explicit

Dim xlsfile
Dim worksheet
Dim objXL
Dim VBSHorizontalObjectType
Dim VBSVerticalObjectType
Dim VBSRelationshipType
Dim horizontalObjectProperty
Dim verticalObjectProperty
Dim relationshipProperty
Dim sizeColumns
Dim sizeRows
Dim startColumn
Dim startRow
Dim VBSHorizontalContainer
Dim VBSHorizontalContainerView
Dim VBSVerticalContainer
Dim VBSVerticalContainerView

Dim VBSContainerType 
Dim VBSModel 
Dim VBSModelView 
Dim VBSActionButton

Dim VBSCollection
Dim VBSCriteria
Dim VBSInstance 
Dim VBSErrorMsg

Dim VBSObject
Dim VBSObjectView
Dim VBSRelationship
Dim VBSRelationshipView
Dim VBSHorizontalList
Dim VBSValueSet

Dim col
Dim row
Dim cellValue
  
set VBSModel = metis.currentModel
set VBSModelView = VBSModel.currentModelView
set VBSContainerType = metis.findType("metis:stdtypes#oid3")

set VBSActionButton = VBSModel.currentInstance
set VBSHorizontalObjectType = metis.findType(VBSActionButton.getNamedStringValue("horizontalType"))
set VBSVerticalObjectType = metis.findType(VBSActionButton.getNamedStringValue("verticalType"))
set VBSRelationshipType = metis.findType(VBSActionButton.getNamedStringValue("relationshipType"))

horizontalObjectProperty = VBSActionButton.getNamedStringValue("horizontalTypeProperty")
verticalObjectProperty = VBSActionButton.getNamedStringValue("verticalTypeProperty")
relationshipProperty = VBSActionButton.getNamedStringValue("relationshipTypeProperty")

xlsfile = VBSActionButton.getNamedValue("xlsFile").getUrl
xlsfile = metis.urlToFileName(xlsfile)
worksheet = VBSActionButton.getNamedStringValue("xlsWorksheet")

set VBSHorizontalContainer = metis.findInstance(VBSActionButton.getNamedStringValue("horizontalObjectContainer"))
set VBSVerticalContainer = metis.findInstance(VBSActionButton.getNamedStringValue("verticalObjectContainer"))
set VBSHorizontalContainerView = VBSHorizontalContainer.views.Item(1)
set VBSVerticalContainerView = VBSVerticalContainer.views.Item(1)

sizeColumns = VBSActionButton.getNamedValue("columns").getInteger
sizeRows = VBSActionButton.getNamedValue("rows").getInteger
startColumn = VBSActionButton.getNamedValue("startColumn").getInteger
startRow = VBSActionButton.getNamedValue("startRow").getInteger

if MsgBox("Do you really want to import " & xlsfile & " into the containers with URI " & VBSHorizontalContainer.uri & " and " & VBSVerticalContainer.uri & "?", vbQuestion + vbYesNo, "MS Excel RM to Metis") = vbYes then
   
   Set objXL = CreateObject("Excel.Application")
   objXL.Workbooks.Open(xlsfile)
   objXL.Worksheets(worksheet).Activate

   set VBSHorizontalList = metis.newInstanceList

   for col = startColumn+1 to startColumn+sizeColumns-1
       Set VBSObject = VBSHorizontalContainer.newPart(VBSHorizontalObjectType)
       Set VBSObjectView = VBSHorizontalContainerView.newObjectView(VBSObject)
       Call VBSObject.setNamedStringValue(horizontalObjectProperty, objXL.Cells(startRow, col))
       Call VBSHorizontalList.AddLast(VBSObject)
   next

   Call metis.doLayout(VBSHorizontalContainerView)

   for row = startRow+1 to startRow+sizeRows-1
       Set VBSObject = VBSVerticalContainer.newPart(VBSVerticalObjectType)
       Set VBSObjectView = VBSVerticalContainerView.newObjectView(VBSObject)
       Call VBSObject.setNamedStringValue(verticalObjectProperty, objXL.Cells(row, startColumn))
       for col = startColumn+1 to startColumn+sizeColumns-1
          cellValue = objXL.Cells(row, col)
          if cellValue <> "" then
             Set VBSRelationship = VBSModel.newRelationship(VBSRelationshipType, VBSObject, VBSHorizontalList.Item(col-startColumn))
             Set VBSRelationshipView = VBSModelView.newRelationshipView(VBSRelationship, VBSObjectView, VBSHorizontalList.Item(col-startColumn).Views(1))
	     if LCase(cellValue) <> "x" and relationshipProperty <> "" then
                Set VBSValueSet = VBSRelationship.getNamedValue(relationshipProperty)
		if VBSValueSet.isString then
		   Call VBSValueSet.setString(CStr(cellValue))
                elseif VBSValueSet.isInteger then
		   if isNumeric(cellValue) then
		      Call VBSValueSet.setInteger(CInt(cellValue))
		   end if
		elseif VBSValueSet.isFloat then
		   if isNumeric(cellValue) then
		      Call VBSValueSet.setFloat(CDbl(cellValue))
		   end if
		end if
	     end if
          end if
       next
   next

   Call metis.doLayout(VBSVerticalContainerView)

'   objXL.Visible = True
'   MsgBox objXL.Cells(5, 5).Value

   objXL.Workbooks.Close

   ' Cleaning up
   Set objXL = Nothing

   metis.runCommand("update-macros")

   if VBSErrorMsg = "" then
      VBSErrorMsg = "No errors found"
   end if
    
   MsgBox "MS Excel to Metis RM import", vbInformation, "MS Excel RM to Metis" 

end if

' Cleaning up
Set VBSHorizontalObjectType = Nothing
Set VBSVerticalObjectType = Nothing
Set VBSRelationshipType = Nothing
Set VBSHorizontalContainer = Nothing
Set VBSHorizontalContainerView = Nothing
Set VBSVerticalContainer = Nothing
Set VBSVerticalContainerView = Nothing

Set VBSContainerType  = Nothing
Set VBSModel  = Nothing
Set VBSModelView  = Nothing
Set VBSActionButton = Nothing

Set VBSCollection = Nothing
Set VBSCriteria = Nothing
Set VBSInstance  = Nothing

Set VBSObject = Nothing
Set VBSObjectView = Nothing
Set VBSRelationship = Nothing
Set VBSRelationshipView = Nothing
Set VBSHorizontalList = Nothing
Set VBSValueSet = Nothing
