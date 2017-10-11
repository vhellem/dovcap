Option Explicit
' Used in Troux Architect
' Purpose: Copy selected Modelviews to word-files.
' eFaros Ltd. 2010 Snorre Fossland
Dim oContainerType
Dim oModel
Dim oModelView
Dim oCurrentModelView
Dim oModelViews
Dim PPApp
Dim PPPres
Dim PPSlide
Dim PPAspect
Dim oContainers
Dim oInstances
Dim oInstance
Dim oSelection
Dim oInstanceView
Dim oStrName
Dim oObject
Dim iSlide
Dim iAnswer
Dim strNote
Dim ifDialog
Dim ifSelectedColl
Dim ifInstanceColl

Dim WApp
Dim objDoc
Dim objectselection

Dim strURI 
Dim	strModelURL
Dim strModelName
Dim strModelNameView
Dim strModelPath
Dim maxLevelGraphic
Dim strWordTemplate
maxLevelGraphic = 6

'Const END_OF_STORY = 6
'Const MOVE_SELECTION = 0


set oContainerType = metis.findType("metis:stdtypes#oid3")
set oModel = metis.currentModel
set oModelViews = oModel.views
set oCurrentModelView = oModel.currentModelView

set oContainers = oModel.findInstances(oContainerType,"","")

Set ifInstanceColl = metis.newInstanceList

iSlide = 1

Set ifDialog = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
If ifDialog is Nothing Then MsgBox "Dialog is Nothing!?"
ifDialog.title = "Word Report (Saved to My Documents)"
ifDialog.heading = "Please select Model Views"
ifDialog.singleSelect = False
ifDialog.columnLabel = True
ifDialog.columnURI = False
ifDialog.columnType = False
' The select dialog does not support model views. Need to fake this using dummy objects

for each oModelView in oModelViews 
    set oObject = oModel.newObject(metis.findType("metis:stdtypes#oid3"))
    Call oObject.setNamedStringValue("name",oModelView.title)
    ifInstanceColl.addLast(oObject)
next

ifDialog.addData ifInstanceColl
Set ifSelectedColl = ifDialog.show

if ifSelectedColl.count > 0 then
   
   for each oInstance in ifSelectedColl
      set oModelView = oModel.modelView(oInstance.getNamedStringValue("name"))
      Call metis.show(oModelView)
'     Call metis.runCommand("zoom-all")
'******************************************************************************************************************************************************
  

''Check for directory folder.
'If objFSO.FolderExists(strDirectory) Then
'        Set objFolder = objFSO.GetFolder(strDirectory)

 	   Set WApp = CreateObject("Word.Application")
	   WApp.visible = False
	   strURI = oModel.uri
	   strModelURL = Left(strURI, InStrRev(strURI, "#")-5)
	   strModelName=modelName(strModelURL)
	   'strModelPath = Replace(strModelURL,"/","\")
	   'MsgBox strModelPath
	   'InStrRev(strURI,"/")
	   strModelNameView = strModelName&"_"&oModelView.title&".doc" 	
	   strWordTemplate = "C:\Users\Public\Documents\Troux\Troux Architect 9.2\xml\http\metadata.bpmt.info\templates\WordReportTemplate.dot"
	 'strModelName = LTrim(strModelPath, InStrRev(strModelPath, "\")) 
		'strModelName = Right(strModelName, InStrRev(strModelName, "/")) 
	   'MsgBox strModelName
	   'strModelName = oModel.title
	   
	   Set objDoc = WApp.Documents.Add(strWordTemplate)
	   'Set objDoc = WApp.Documents.Open(strWordTemplate)



      'Call WholeModelViewToPowerPoint 'insert modelview graphics in powerpoint slide
      Call WholeModelViewToWord
      objDoc.TablesOfContents(1).Update
      Call UpdateALL()
      objDoc.SaveAs(strModelNameView)
      objDoc.Close

'******************************************************************************************************************************************************
   next
   Call metis.show(oCurrentModelView)
   Call metis.runCommand("zoom-all")
end if



' Delete the dummy objects.

for each oInstance in ifInstanceColl
    Call oModel.deleteObject(oInstance)
next

' Cleaning up

Set oContainerType = Nothing
Set oModel = Nothing
Set oModelView = Nothing
Set oCurrentModelView = Nothing
Set oModelViews = Nothing
Set oContainers = Nothing
Set oInstances = Nothing
Set oInstance = Nothing
Set oSelection = Nothing
Set oInstanceView = Nothing
Set oObject = Nothing
Set ifDialog = Nothing
Set ifSelectedColl = Nothing
Set ifInstanceColl = Nothing
Set PPApp = Nothing
Set PPPres = Nothing
Set PPSlide = Nothing
Set PPAspect = Nothing
MsgBox "Wordfile generated"

Sub WholeModelViewToWord
	'Dim
    Dim ImageAspect,level,objView, slideNote, Sh, Sc, PPTSlide, strPreviousType
    if metis.currentModel.currentModelView.children.count > 0 Then

        Call metis.runCommand("zoom-all")
        Call metis.runCommand("zoom-in")
        Call metis.runCommand("zoom-in")
       	Call oModelView.children(1).open ' just in case the top container is closed

        Call oModelView.copyImageToClipboard
		Set objectselection = WApp.Selection
        Set objView = metis.currentModel.currentModelView
        'objectselection.Style = -32
		'objectselection.TypeText  "Troux Architect Word report"

'		objectselection.EndKey 6,0
		'objectselection.TypeParagraph()
'		' Paste the top object/container into word ********************************************************************
'		objectselection.Paste
		'objectselection.HomeKey 6,0

		'objectselection.Style = "Subtle Reference"
'		objectselection.TypeText  "Fig: Modelview name - " & objView.title '& vbCr & vbCr
'		objectselection.TypeParagraph()
''		objectselection.TypeText  objView.instance.getNamedStringValue("description")
''		objectselection.TypeParagraph()
		objectselection.EndKey 6,0
 ''       'ImageAspect = PPPres.Slides.Item(iSlide).Shapes.Item(1).Width / PPPres.Slides.Item(iSlide).Shapes.Item(1).Heigh
 		'objectselection.TypeText strModelName
		'objectselection.TypeParagraph()
       level = 0
		Call writeModelViewToWord(objView, level)
 
    end if
		strNote = ""

End Sub

Sub writeModelViewToWord(objView, level)
	Dim oModelViewChildren, oModelViewChild,isExcluded, strType, strStyle,showPict, oChild
	Set oModelViewChildren = objView.children	
	level = level+1
	For Each oModelViewChild In oModelViewChildren
		on error resume Next
		'Call oModelViewChild.open
		strType = oModelViewChild.instance.Type.Name 
		isExcluded = checkIfExcluded(strType)
		If Not isExcluded Then
			If oModelViewChild.title <> "" Then
				Select Case level
				Case 0 
					strStyle = -3 '"Heading 1"
					showPict = True
					Call oModelViewChild.open
				Case 1 ' top container/Swimlane diagram
					strStyle = -3 '"Heading 1"
					showPict = True
					Call oModelViewChild.open
				Case 2 'swimlane diagram /swimlane
					strStyle = -3 '"Heading 2"
					showPict = True
					'MsgBox level&oModelViewChild.title
					Call oModelViewChild.open
				Case 3 ' Swimlane
					strStyle = -4 '"Heading 3"
					showPict = True
					Call oModelViewChild.open
				Case 4 ' Swimlane or processes(objects) in swimlane
					strStyle = -5 '"Heading 4"
					'strStyle = -88 '"Strong"					
					'strStyle = -1 '"Normal"					
					showPict = True 
				Case 5 ' Processes
					'strStyle = -88 '"Strong"					
					strStyle = -1 '"Normal"					
					showPict = True
				Case Else
					strStyle = -1 '"Normal"					
					showPict = True
				End Select
				Call printPObject(oModelViewChild,strStyle,strType,showPict,level)	
				'If level < 3 Or strType = "Container" Then 'Or strType = "Process" Then
				If strType = "Container" Then 'Or strType = "Process" Then
					Call oModelViewChild.open
				ElseIf strType = "Swimlane Diagram" Then	
					Call oModelViewChild.open
				ElseIf strType = "Role" Then	
					Call oModelViewChild.open
				ElseIf strType = "Process" Then	
					Set oModelViewGranChildren = oModelViewChild.children	
					If oModelViewGranChildren.count > 0 Then
					else
				 		Call oModelViewChild.close
				 	End if
				End if
			End If
			strStyle = Null
		End If
		Set oChild = oModelViewChild
		Call writeModelViewToWord(oChild, level)
		level = level-1
	Next
	
End Sub

Sub printPObject(obj,strStyle,strType,showPict,level)
	Dim objInlineShape, strIcon, objPropertyValue, objType, objProperty, objProperties

		objectselection.EndKey 6,0
	'Call metis.runCommand("zoom-all")
'	If strType = "Process" Then
		'Call obj.open
	'	Call metis.runCommand("zoom-text-size")
	'
		'	Call metis.runCommand("zoom-in")
		If strType = "Process" then
		Else
			Call metis.runCommand("zoom-in")
		End If
		
	
		Call obj.copyImageToClipboard
		Call obj.copyImageToFile("C:\Windows\Temp\TATemp.png",1)
		
		If strType = "Process" then
		Else
			Call metis.runCommand("zoom-out")
		End If
		'	Call metis.runCommand("zoom-out")
		' Oversett til norsk
		'strStyle = Replace(strStyle, "Heading","Overskrift")
		'strStyle = Replace(strStyle, "Strong","Sterk")
		objectselection.Style = strStyle
		'	objectselection.ParagraphFormat.Alignment = 0	
		objectselection.TypeText obj.title
		' *************************************
		' smallIcon as bullet
		'	strIcon = ""
		'	strIcon = imgBullet(strType)
		'	If strType = "Process" then
		'		If strIcon <> "" then
		'			objectselection.InlineShapes.AddPictureBullet(strIcon)
		'			objectselection.ParagraphFormat.Alignment = 0
		'		End If 
		'	End if
		'**************************************
	
		objectselection.TypeParagraph()
			If showPict = True then
				'If level > 2 Then '****************************************************************************************
					'MsgBox strType
					If strType = "Container" Or strType = "Swimlane_Diagram" Or strType = "Process" or strType = "Role"  Then
						objectselection.InlineShapes.AddPicture("C:\Windows\Temp\TATemp.png")
						'If ojectselection.InlineShapes.Width > 720 Then
							'objectselection.InlineShapes.width = 300
						objectselection.TypeParagraph()
					End if
				'End if
			End If
			objectselection.Font.Size = "8"
			objectselection.TypeText "("&strType&")"
			'objectselection.TypeText  "Fig: Modelview name - " & objView.title & vbCr' & vbCr
			objectselection.TypeParagraph()
		'
		'If obj.instance.getNamedStringValue("description") <> "" Then
			objectselection.Font.Size = "11"		
			'objectselection.TypeText  " - description : " & obj.instance.getNamedStringValue("description") & vbCrLf
			objectselection.TypeText obj.instance.getNamedStringValue("description") '& vbCrLf
			'objectselection.TypeText obj.instance.getNamedStringValue("description")
			objectselection.TypeParagraph()
			objectselection.Font.Size = "8"
		'End If
	
		Set objType = obj.instance.type
		Set objProperties = objType.propertyCollection
		For Each objProperty In objProperties
			on error resume Next
			objPropertyValue = obj.instance.getNamedStringValue(objProperty.name)
			 'objProperty.name & " : " & objPropertyValue
			Select Case objProperty.name
				Case "troux_shape"
				Case "troux_color" 
				Case "troux_iconAlias"
				Case "troux_terminalForTracing"
				Case "troux_toplevel" 
				Case "dbms-admin.commitFlag"
				Case "dbms-admin.system-uploaded"
				Case "dbms-admin.propertyList"
				Case "textFitFlag" 
				Case "description" 
				Case "name"
				Case "journalID"
				Case "Metis_CreateObjectClosed"
				Case "Metis_NestedDecompositionFactor" 
				Case "BPM_Description"
				Case "BPM_Name"
				Case "BPM_FillPattern"
				Case "BPM_OpenColor"
				Case "BPM_ClosedColor" 
				Case "punctuationMark" 
				Case "prefix" 
				Case "symbolLabel" 
				Case "parentId"
				Case "durationUnit" 
				Case "identification"
				Case "sequenceNumber"
				Case "color" 
				Case "type" 
				Case "titleStretch" 
				Case "duration" 
				Case "processModelChange" 
				' Application properties
				Case "externalID" 
				Case "recurringCost" 
				Case "recommendation" 
				Case "businessRiskScore"
				Case "supportRisk" 
				Case "businessCriticalityScore"
				
				 
				Case "comments"objPropertyValue
					If objPropertyValue <> "" then
						objectselection.TypeText " - " & objProperty.name & " : " & vbCrLf & objPropertyValue & vbCrLf
					End if
				Case "duration"
					If objPropertyValue <> "" then
						objectselection.TypeText " - " & objProperty.name & " : " & objPropertyValue & " : " & obj.instance.getNamedStringValue("durationUnit")	& vbCrLf	
					End if
				Case Else
					If objPropertyValue <> "" and objPropertyValue <> "00000000" and objPropertyValue <> "0" And objPropertyValue <> "Undefined" then
						objectselection.TypeText " - " & objProperty.name & " : " & objPropertyValue & vbCrLf
					End if
			End Select
		Next
	objectselection.TypeParagraph()
'		objectselection.TypeText "-------------------------------------------------------"&vbCrLf						  				
'		objectselection.TypeText "Business Impact Analysis Score : " & obj.instance.getNamedStringValue("businessImpactAnalysisScore")&vbCrLf						  				
'		objectselection.TypeText "IT Effectiveness Percentage : " & obj.instance.getNamedStringValue("itEffectivenessPercentage")&vbCrLf						  				
'		objectselection.TypeText "Business Criticality Score : " & obj.instance.getNamedStringValue("businessCriticalityScore")&vbCrLf						  				
'		objectselection.TypeText "Duration : " & obj.instance.getNamedStringValue("duration")& " "& obj.instance.getNamedStringValue("durationUnit")&vbCrLf						  				
'		objectselection.TypeText "Automation : " & obj.instance.getNamedStringValue("automation")&vbCrLf						  				
'		objectselection.TypeText "Process Model Change status : " & obj.instance.getNamedStringValue("processModelChange")'&vbCrLf						  				
'	objectselection.TypeParagraph()

	'Call obj.open
End sub

Function imgBullet(strType)
	Dim strBullet
	'MsgBox strType
	Select Case strType
        Case "Process"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\process.png"
		Case "mechanism"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\mechanism.png"
		Case "control"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\control.png"
		Case "input"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\input.png"
		Case "output"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\output.png"
		Case "intermediateeven"
			strBullet = "C:\Users\Snorre\Dropbox\XML\hso\xml\http\metadata.troux.info\meaf\icons\bpm\intermediateeven.png"
		Case Else
			strBullet = ""
	End Select
	imgBullet = strBullet
End Function

Function checkIfExcluded(strType)
' object types that should be excluded from the export = True
	Select Case strType
        Case "process"
 			checkIfExcluded = "False"
 			strType = "Process"
        Case "Horizontal Swimlane"
 			checkIfExcluded = "False"
 			strType = "Role"
        Case "Swimlane Diagram"
 			checkIfExcluded = "False"
        Case "Title_Right"
 			checkIfExcluded = "True"
        Case "Title_Left"
 			checkIfExcluded = "True"
        Case "process_mechanism"
 			checkIfExcluded = "True"
        Case "BPM_text"
 			checkIfExcluded = "True"
   		Case "Word Relationship Report " 
 			checkIfExcluded = "True"
		Case "Word_Relationship_Report_Action_Button" 
 			checkIfExcluded = "True"
		Case "process_start_event" 
 			checkIfExcluded = "True"
		Case "Label2" 
 			checkIfExcluded = "True"
		Case "Comment" 
 			checkIfExcluded = "True"
		Case "BPM_Text" 
 			checkIfExcluded = "True"
		Case "Database Field" 
 			checkIfExcluded = "True"
		Case "Atomic Property" 
 			checkIfExcluded = "True"
		Case "Database Query" 
 			checkIfExcluded = "True"
 		Case "process_intermediate_event" 
 			checkIfExcluded = "True"
 		Case "process_end_event" 
 			checkIfExcluded = "True"
 		Case "process_intermediate_event" 
 			checkIfExcluded = "True"
 		Case "Connector" 
 			checkIfExcluded = "True"
 '		Case "Input" 
 '			checkIfExcluded = "True"
 '		Case "Output" 
 '			checkIfExcluded = "True"
  		Case "PushPin" 
 			checkIfExcluded = "True"
 		Case "TrouxNews" 
 			checkIfExcluded = "True"
  		Case "TrouxMarshalling" 
 			checkIfExcluded = "True"
  		Case "ActionButton" 
 			checkIfExcluded = "True"
   		Case Else
			checkIfExcluded = "False"
    End Select
End Function


sub WholeModelViewToPowerPoint
    Dim ImageAspect,level,objView, slideNote, Sh, Sc, PPTSlide, strPreviousType
    if metis.currentModel.currentModelView.children.count > 0 Then

        Call metis.runCommand("zoom-all")
        Call oModelView.copyImageToClipboard
        Set PPSlide = PPPres.Slides.Add(iSlide,12)
        PPApp.ActiveWindow.View.GotoSlide(iSlide)
        PPApp.ActiveWindow.View.Paste
        ImageAspect = PPPres.Slides.Item(iSlide).Shapes.Item(1).Width / PPPres.Slides.Item(iSlide).Shapes.Item(1).Height
        if ImageAspect > PPAspect then
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Width = PPPres.PageSetup.SlideWidth * 0.9
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Left = PPPres.PageSetup.SlideWidth * 0.05
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Height = PPPres.Slides.Item(iSlide).Shapes.Item(1).Width / ImageAspect
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Top = (PPPres.PageSetup.SlideHeight - PPPres.Slides.Item(iSlide).Shapes.Item(1).Height) / 2 
        else
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Height = PPPres.PageSetup.SlideHeight * 0.9
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Top = PPPres.PageSetup.SlideHeight * 0.05
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Width = PPPres.Slides.Item(iSlide).Shapes.Item(1).Height * ImageAspect
           PPPres.Slides.Item(iSlide).Shapes.Item(1).Left = (PPPres.PageSetup.SlideWidth - PPPres.Slides.Item(iSlide).Shapes.Item(1).Width) / 2
        end If
        level = 0
        Set objView = metis.currentModel.currentModelView
        strNote = "ModelView: " & objView.title & " - " & objView.children(1).parent.instance.getNamedStringValue("description")& vbCr 
		'Call writeModelViewToWord(objView, level)
		Set PPTSlide = PPPres.Slides.Item(iSlide)
		'PPPres.Slides.Item(iSlide).NotesPage.Shapes(1).TextFrame.TextRange.Text=strNote
		Const msoTextOrientationHorizontal = 1
		With PPTSlide		 
            If PPTSlide.NotesPage.Shapes.Count = 0 Then 'If no shapes to take Notes then add a shape first
               PPTSlide.NotesPage.Shapes.AddShape msoShapeRectangle, 0, 0, 0, 0
               'PPTSlide.NotesPage.Shapes.AddShape msoTextOrientationHorizontal, 0, 0, 0, 0
               Sh = PPTSlide.NotesPage.Shapes(1)
               Sh.TextFrame.TextRange.Text = strNote
            Else    'has shapes, so see if they take text
                For Each Sh In PPTSlide.NotesPage.Shapes
                    If Sh.HasTextFrame Then
                        'Sh.TextFrame.TextRange.Style = "Heading 3"
                        Sh.TextFrame.TextRange.Font.Size = 20
                        Sh.TextFrame.TextRange.Text = strNote
                    End if
                Next
            End If
'            Sc =  PPTSlide.AddComments
'            Sc.Text = "aaaaaaaaaaaaaaaabbbbbbbbbbbbbb"
		End With


		'MsgBox strNote
		strNote = ""
        iSlide = iSlide + 1
    end if
end Sub


sub ModelViewToPowerPoint
Call oModelView.select(oContainers)
set oSelection = metis.selection

for each oInstanceView in oSelection
    if oInstanceView.hasInstance then
       set oInstance = oInstanceView.instance
       set oInstances = metis.newInstanceList
       Call oInstances.AddFirst(oInstance)
       Call oModelView.select(oInstances)
'       Call metis.runCommand("zoom-text-size")
       Call metis.runCommand("zoom-to")
        Call metis.runCommand("zoom-in")
    else
       Call metis.zoomInstanceView(oModelView, oInstanceView)
    end if
    Call oInstanceView.copyImageToClipboard
    Set PPSlide = PPPres.Slides.Add(iSlide,12)
    PPApp.ActiveWindow.View.GotoSlide(iSlide)
    PPApp.ActiveWindow.View.Paste

    iSlide = iSlide + 1
next

end Sub


Sub UpdateALL 'This one updates all the fields in the document:
    Dim oStory 
    Dim oToc
     
     'exit if no document is open
    'If Documents.Count = 0 Then Exit Sub 
    WApp.ScreenUpdating = False 
     
    For Each oStory In objDoc.StoryRanges 
        oStory.Fields.Update 'update fields in all stories
    Next 
     
    For Each oToc In objDoc.TablesOfContents 
        oToc.Update 'update TOC's
    Next 
     
    WApp.ScreenUpdating = True 
End Sub 


Function modelName(s)
	' Returns the numeric value of a Metis URL including the '#oid' substring
	' Ie. http://xml.metis.no/test.kmd#oid1243 will return 1243
	Dim i 
'	i = InStr(s, "#oid")
	i = InStrRev(s, "/")
	If i > 0 Then
	    modelName = Right(Trim(s), Len(Trim(s)) - i)
	Else
	    modelName = ""
	End If
End Function