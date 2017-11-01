Option Explicit
' Used in Troux Architect
' Purpose: copy selected Modelviews to png-files or slides in PowerPoint and scale them to fill the slide size.
' eFaros Ltd. 2010 Snorre Fossland
Dim oContainerType
Dim oModel
Dim oModelView
Dim oCurrentModelView
Dim oModelViews

Dim oContainers
Dim oInstances
Dim oInstance
Dim oSelection
Dim oInstanceView
Dim oStrName
Dim oObject
Dim iAnswer
Dim strNote
Dim ifDialog
Dim ifSelectedColl
Dim ifInstanceColl
Dim VBSStrName
Dim PPApp, PPPres, PPAspect, PPSlide, iSlide, ImageAspect
Dim pngFolder,pngFileName
Dim strURI 
Dim	strModelURL
Dim strModelName
Dim strModelPath
Dim oModelViewImg

Dim objDoc
Dim objectselection
Dim maxLevelGraphic
maxLevelGraphic = 6

'Const END_OF_STORY = 6
'Const MOVE_SELECTION = 0

set oContainerType = metis.findType("metis:stdtypes#oid3")
set oModel = metis.currentModel
set oModelViews = oModel.views
set oCurrentModelView = oModel.currentModelView

set oContainers = oModel.findInstances(oContainerType,"","")

Set ifInstanceColl = metis.newInstanceList

VBSStrName = "Yes for PowerPoint and No for PNG-files!            (PNG-files needs a subfolder named ""Dokumentasjon"" in current folder)"
iAnswer = MsgBox(VBSStrName, vbYesNoCancel + vbQuestion, "Outputformat")
	If iAnswer = vbYes Then ' PowerPoint
		Set PPApp = CreateObject("Powerpoint.Application")
		Set PPPres = PPApp.Presentations.Add
		PPPres.PageSetup.SlideWidth = 720
		PPPres.PageSetup.SlideHeight = 540
		PPAspect = PPPres.PageSetup.SlideWidth / PPPres.PageSetup.SlideHeight
		PPApp.Visible = True
	End if

Set ifDialog = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
If ifDialog is Nothing Then MsgBox "Dialog is Nothing!?"
ifDialog.title = "Create Png files or PowerPoint slides from modelviews"
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
 	iSlide = 1  
   for each oInstance in ifSelectedColl
      set oModelView = oModel.modelView(oInstance.getNamedStringValue("name"))
      Call metis.show(oModelView)
	'     Call metis.runCommand("zoom-all")
	'******************************************************************************************************************************************************
	If 	oModelView.title <> "TrouxSource Repository" Then
'		if iAnswer <> vbCancel then
'		  If iAnswer = vbYes Then ' PowerPoint
'		      Call WholeModelViewToPP(oModelView) 'saves the modelviews to a PP file
'		  elseif iAnswer = vbNo Then ' png-files
		      Call WholeModelViewToFiles(oModelView) 'saves the modelviews as png files
'	      End if
'	    End if
    End If    
	'******************************************************************************************************************************************************
   next
   Call metis.show(oCurrentModelView)
   Call metis.runCommand("zoom-all")
end if
'	Set PPPres = PPApp.Presentations.Add
'    PPPres.SaveAs(strModelName)
'    PPPres.Close


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


Sub WholeModelViewToFiles(oModelView)
    if metis.currentModel.currentModelView.children.count > 0 Then
	    Call metis.runCommand("zoom-all")
	    Call metis.runCommand("zoom-in")
	    Call metis.runCommand("zoom-in")
	   '	Call oModelView.children(1).open ' just in case the top container is closed	
	    Call oModelView.copyImageToClipboard
		Call metis.runCommand("zoom-in")
		Call metis.runCommand("zoom-in")
		Call metis.runCommand("zoom-in")
		'Call oModelView.children(1).copyImageToClipboard
		'MsgBox oModelView.children(1).title
		if iAnswer <> vbCancel then
		  If iAnswer = vbYes Then ' PowerPoint
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
		    end if
		    iSlide = iSlide + 1	  
		  elseif iAnswer = vbNo Then ' png-files
			pngFolder =".\Dokumentasjon\"
			'pngFileName= pngFolder & metis.currentModel.title & "-"&oModelView.Title &".png"						
			strURI = oModel.uri
		    strModelURL = Left(strURI, InStrRev(strURI, "#")-5)
		    strModelName = modelName(strModelURL)
		    pngFileName = pngFolder & strModelName & "_"&oModelView.title & ".png" 	
			'MsgBox pngFileName
	   		Call oModelView.children(1).open ' just in case the top container is closed	
			Call oModelView.children(1).copyImageToFile(pngFileName,1)
			'Call oModelView.children(1).copyImageToFile("C:\Windows\Temp\TATemp.png",1)
'			pngFolder ="C:\Users\Snorre\SharePoint\SØ - Arkitektur - TrouxExport\UnderArbeid\png\"
'			pngFileName= pngFolder&metis.currentModel.title&"-"&oModelView.Title&".png"
'			Call oModelView.children(1).copyImageToFile(pngFileName,1)			
			'MsgBox pngFileName
			'Call obj.copyImageToFile("C:\Windows\Temp\TATemp.png",1)
			'curObj.copyImageToFile fsoFolderToURL(objTempFolder) & "metis_snapshot.png", 1 '0=BMP|1=PNG			
			'Call oModelView.children(1).copyImageToFile("C:\Users\Snorre\Dropbox\Projects\hso\tmp.png",1)
			Call metis.runCommand("zoom-all")
	      End if
	    End if	
    end if
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
