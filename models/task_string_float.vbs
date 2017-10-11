Option Explicit
' 
' Convert baselineCost and cost from String to float
'

'----------------
'Global Variables
'----------------
Dim ifModel
Dim ifMetisValue1
Dim ifMetisValue2

Dim instCol
Dim instCost
Dim instBaselineCost
Dim typeTask
Dim inst
Dim value1
Dim value2 
Dim numeric1
Dim numeric2

Dim nCostUpdated
Dim nBaselineCostUpdated

Dim tmpString

Set ifModel = metis.currentModel
Set ifMetisValue1 = metis.newValue()
Set ifMetisValue2 = metis.newValue()


Set typeTask = metis.findType("http://xml.metis.no/xml/object_types/task.kmd#oid1")
Set instCol = ifModel.findInstances(typeTask, "", "")

tmpString = "This method converts two properties on all Task objects in the model" & vbCrLf
tmpString = tmpString & "from string to float. This must be done to fix a problem with Baseline" & vbCrLf
tmpString = tmpString & "Cost and Actual Cost being defined as strings in Metis 3.4 and older." & vbCrLf
tmpString = tmpString & "From Metis 3.6 and newer, these properties are now defined as float." & vbCrLf & vbCrLf
tmpString = tmpString & "You should only run this method once per model. If you have run it" & vbCrLf
tmpString = tmpString & "before, and have later updated Baseline Cost and Actual Cost properties" & vbCrLf
tmpString = tmpString & "on Task objects, these changes may be lost." & vbCrLf & vbCrLf
tmpString = tmpString & "Do you really want to run the method?"

if MsgBox(tmpString, vbYesNo + vbQuestion, "Metis 3.6 ITM Task Upgrade Method") = vbYes then

   nCostUpdated = 0
   nBaselineCostUpdated = 0

   for each inst in instCol

	instCost = inst.getNamedStringValue("cost")
	instBaselineCost = inst.getNamedStringValue("baselineCost")
	
	numeric1 = IsNumeric(instCost)
	numeric2 = IsNumeric(instBaselineCost)
	
	' check the cost value
	if numeric1 then
		value1 = Cdbl(instCost)
		Call ifMetisValue1.setFloat(value1)
		inst.setNamedValue "costFloat", ifMetisValue1
		nCostUpdated = nCostUpdated + 1
	end if
	
	' check the baselineCost value
	if numeric2 then
		value2 = Cdbl(instBaselineCost)
		Call ifMetisValue2.setFloat(value2)
		inst.setNamedValue "baselineCostFloat", ifMetisValue2
		nBaselineCostUpdated = nBaselineCostUpdated + 1
	end if

   next

   tmpString = "Method completed successfully." & vbCrLf
   tmpString = tmpString & "A total of " & nCostUpdated & " Actual Cost property values" & vbCrLf
   tmpString = tmpString & "and " & nBaselineCostUpdated & " Baseline Cost property values was updated."

   MsgBox tmpString, vbInformation, "Metis 3.6 ITM Task Upgrade Method"

else

   MsgBox "Method was cancelled by user", vbInformation, "Metis 3.6 ITM Task Upgrade Method"

end if
