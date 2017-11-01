Option Explicit
' 20120625  Snorre Fossland  Copyright eFaros Ltd
' For all processes and Icoms, set or remove identification in name
Dim objMModel
Dim VBSModel
Dim VBSSelection
Dim VBSInstanceView
Dim VBSInstance, VBSParent
Dim VBSObject, VBSCollection
Dim objXL
Dim nInstances
Dim objType
Dim strId, strIdParent, sIdent
Dim strUri
Dim strName,oTName,VBSStrName
Dim objIcom, icomColl
Dim iAnswer
' #############           ##########################
Set objMModel = Metis.currentModel
Set VBSCollection = objMModel.allParts

VBSStrName = "Click:  "&vbLf&"Yes - to add Process Id no. to name!"&vbLf&"No - to remove Process Id from name"
iAnswer = MsgBox(VBSStrName, vbYesNoCancel + vbQuestion, "Add Process id to Process name")
if iAnswer = vbYes then
	for each VBSObject in VBSCollection
		on error resume Next
		If VBSObject.Type.Name = "process" Then
			Call copyProcessId2Name(VBSObject)
		ElseIf  VBSObject.Type.Name = "process_input" Or VBSObject.Type.Name = "process_control" Or VBSObject.Type.Name = "process_output" Or VBSObject.Type.Name = "process_mechanism" then
			Call copyProcessId2Name(VBSObject)
			'MsgBox VBSObject.title
		End If
	Next
ElseIf iAnswer = vbNo then
	for each VBSObject in VBSCollection
		on error resume Next
		If VBSObject.Type.Name = "process" Then
			Call removeProcessIdFromName(VBSObject)
		ElseIf  VBSObject.Type.Name = "process_input" Or VBSObject.Type.Name = "process_control" Or VBSObject.Type.Name = "process_output" Or VBSObject.Type.Name = "process_mechanism" then
			Call removeProcessIdFromName(VBSObject)
			'MsgBox VBSObject.title
		End If
	Next
end If

Sub copyProcessId2Name(obj)' adding the processId to the name where the id has changes
	Dim strB,strA, strName2, i
	'Processes
	If obj.Type.Name = "process" Then
		strId = obj.getNamedStringValue("identification")
		If strId <> "" then
			Call getProcessIdFromName(obj,sIdent)
			' check if changed
			If sIdent <> strId Then  ' change the name by adding id.			
				Call removeProcessIdFromName(obj)
				strName= strId&": "&obj.name
			'MsgBox  strId & " - " & sIdent & " - " &strName
	'			Else 
	'				strName = obj.name
	'			End If
				Call obj.setNamedStringValue("name", strName)
			End if
		End if	
	' ICOMS
	ElseIf obj.Type.Name = "process_input" Or obj.Type.Name = "process_control" Or obj.Type.Name = "process_output" Or obj.Type.Name = "process_mechanism" then
		strIdParent = obj.parent.getNamedStringValue("identification")
		If strIdParent <> "" then
			Call getProcessIdFromName(obj,sIdent)
			' check if changed
			If sIdent <> strIdParent Then  ' change the name	
					Call removeProcessIdFromName(obj)
					strName= strIdParent&": "&obj.name
	'			Else
	'				strName=obj.name 
	'			End If
				'MsgBox sIdent & strIdParent	
				'MsgBox strName
				'strIdOld = obj.getNamedStringValue("name")
				'If sIdent <> "" Then  ' chenge the name		
				'MsgBox obj.getNamedStringValue("name")
				'MsgBox strName
				Call obj.setNamedStringValue("name", strName)
			End If
		End if
	End if		
End Sub
Sub removeProcessIdFromName(obj)
	Dim strB
	strName= obj.getNamedStringValue("name")
	strB = findBeforeCol(strName)
	If Len(strB) > 1 Then 'remove if id in name exist
		strName= obj.getNamedStringValue("name")
		strName=findAfterCol(strName)
		'strName=Replace(strName, ":", "")' remove :
		Call obj.setNamedStringValue("name", strName)
	End If	
End sub
Sub getProcessIdFromName(obj,sIdent)
	Dim strB
	strName= obj.getNamedStringValue("name")
	strB = findBeforeCol(strName)
	sIdent=strB
End sub
Function findBeforeCol(s)
	' Returns the string before the semicolon
	s=Replace(s, vbCr, "")'remove cr
	s=Replace(s, vbLf, "")' remove lf
	Dim i, strEnd
	i = InStr(s, ": ")	  ' retuns all before :
	If i > 0 And i < 22 Then ' < 22  just in case there is a colon in the text
	    strEnd = Left(Trim(s), Len(Trim(s))-(Len(Trim(s))-i+1))
		findBeforeCol = strEnd
 	End If
End Function
Function findAfterCol(s)
	' Returns all after :
	s=Replace(s, vbCr, "")'remove cr
	s=Replace(s, vbLf, "")' remove lf

	Dim i, strEnd
	i = InStr(s, ": ")	  ' retuns all after ;
	'If i > 0 Then
	If i > 0 And i < 22 Then ' < 22  just in case there is a colon in the text
	    strEnd = Right(Trim(s), Len(Trim(s)) - i)
	    findAfterCol = Left(Trim(strEnd), Len(Trim(strEnd))-0)
	End If
End Function
