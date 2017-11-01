Option Explicit

Dim VBSContainerType
Dim VBSModel
Dim VBSModelView
Dim VBSCurrentModelView
Dim VBSModelViews
Dim PPApp
Dim PPPres
Dim PPSlide
Dim PPAspect
Dim VBSContainers
Dim VBSInstances
Dim VBSInstance
Dim VBSSelection
Dim VBSInstanceView
Dim VBSStrName
Dim VBSObject
Dim iSlide
Dim iAnswer

Dim ifDialog
Dim ifSelectedColl
Dim ifInstanceColl

set VBSContainerType = metis.findType("metis:stdtypes#oid3")
set VBSModel = metis.currentModel
set VBSModelViews = VBSModel.views
set VBSCurrentModelView = VBSModel.currentModelView

set VBSContainers = VBSModel.findInstances(VBSContainerType,"","")

Set ifInstanceColl = metis.newInstanceList

iSlide = 1

Set ifDialog = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
If ifDialog is Nothing Then MsgBox "Dialog is Nothing!?"
ifDialog.title = "Create PowerPoint Presentation"
ifDialog.heading = "Please select Model Views"
ifDialog.singleSelect = False
ifDialog.columnLabel = True
ifDialog.columnURI = False
ifDialog.columnType = False

' The select dialog does not support model views. Need to fake this using dummy objects

for each VBSModelView in VBSModelViews 
    set VBSObject = VBSModel.newObject(metis.findType("metis:stdtypes#oid3"))
    Call VBSObject.setNamedStringValue("name",VBSModelView.title)
    ifInstanceColl.addLast(VBSObject)
next

ifDialog.addData ifInstanceColl
Set ifSelectedColl = ifDialog.show

if ifSelectedColl.count > 0 then
   Set PPApp = CreateObject("Powerpoint.Application")
   Set PPPres = PPApp.Presentations.Add
   PPPres.PageSetup.SlideWidth = 720
   PPPres.PageSetup.SlideHeight = 540
   PPAspect = PPPres.PageSetup.SlideWidth / PPPres.PageSetup.SlideHeight
   'Set PPSlide = PPPres.Slides.Add(1,12)
   PPApp.Visible = True
   for each VBSInstance in ifSelectedColl
      set VBSModelView = VBSModel.modelView(VBSInstance.getNamedStringValue("name"))
      Call metis.show(VBSModelView)
'     Call metis.runCommand("zoom-all")
      Call WholeModelViewToPowerPoint
   next
   Call metis.show(VBSCurrentModelView)
   Call metis.runCommand("zoom-all")
end if

' Delete the dummy objects.

for each VBSInstance in ifInstanceColl
    Call VBSModel.deleteObject(VBSInstance)
next

' Cleaning up

Set VBSContainerType = Nothing
Set VBSModel = Nothing
Set VBSModelView = Nothing
Set VBSCurrentModelView = Nothing
Set VBSModelViews = Nothing
Set VBSContainers = Nothing
Set VBSInstances = Nothing
Set VBSInstance = Nothing
Set VBSSelection = Nothing
Set VBSInstanceView = Nothing
Set VBSObject = Nothing
Set ifDialog = Nothing
Set ifSelectedColl = Nothing
Set ifInstanceColl = Nothing


sub ModelViewToPowerPoint
Call VBSModelView.select(VBSContainers)
set VBSSelection = metis.selection

for each VBSInstanceView in VBSSelection
    if VBSInstanceView.hasInstance then
       set VBSInstance = VBSInstanceView.instance
       set VBSInstances = metis.newInstanceList
       Call VBSInstances.AddFirst(VBSInstance)
       Call VBSModelView.select(VBSInstances)
'       Call metis.runCommand("zoom-text-size")
       Call metis.runCommand("zoom-to")
    else
       Call metis.zoomInstanceView(VBSModelView, VBSInstanceView)
    end if
    Call VBSInstanceView.copyImageToClipboard
    Set PPSlide = PPPres.Slides.Add(iSlide,12)
    PPApp.ActiveWindow.View.GotoSlide(iSlide)
    PPApp.ActiveWindow.View.Paste

    iSlide = iSlide + 1
next

end sub


sub WholeModelViewToPowerPoint
    Dim ImageAspect

    set VBSInstanceView = VBSModelView.children.Item(1)
    Call metis.runCommand("zoom-all")
    Call VBSInstanceView.copyImageToClipboard
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

end sub
