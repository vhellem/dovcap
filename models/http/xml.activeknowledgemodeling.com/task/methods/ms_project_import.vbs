Option Explicit

Dim mppfile
Dim containerName
Dim project
Dim objMSP
Dim task
Dim taskIndex
Dim doLayout
Dim VBSContainerType 
Dim VBSProjectType 
Dim VBSTaskType 
Dim VBSModel 
Dim VBSModelView 
Dim VBSTopObject 
Dim VBSTopObjectView 
Dim VBSActionButton
Dim VBSCollection
Dim VBSCriteria
Dim VBSUniqueIDArgument
Dim VBSCriteriaFindTasks
Dim VBSInstance 
Dim VBSObject
Dim VBSObjectView
Dim VBSErrorMsg
Dim tasksNew
Dim tasksUpdated
Dim tasksDeleted
Dim tasksMoved
  
set VBSModel = metis.currentModel
set VBSModelView = VBSModel.currentModelView
set VBSActionButton = VBSModel.currentInstance
set VBSCriteria = metis.findCriteria("http://xml.activeknowledgemodeling.com/task/criteria/msproject_interface_criteria.kmd#oid1")
set VBSCriteriaFindTasks = metis.findCriteria("http://xml.activeknowledgemodeling.com/task/criteria/msproject_interface_criteria.kmd#oid2")

set VBSContainerType = metis.findType("metis:stdtypes#oid3")
set VBSProjectType = metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/context.kmd#AKM_Context")
set VBSTaskType = metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task.kmd#AKM_Task")

set VBSUniqueIDArgument = metis.newValue()

mppfile = VBSActionButton.getNamedValue("mppFile").getUrl
containerName = VBSActionButton.getNamedStringValue("rootContainer")
mppfile = metis.urlToFileName(mppfile)

set VBSTopObject = metis.findInstance(containerName)
'MsgBox VBSCollection.Count
set VBSCollection = VBSTopObject.views
set VBSTopObjectView = VBSCollection.Item(1)

if MsgBox("This utility will import the project plan located at " & vbcrlf & vbcrlf & " " & mppfile & vbcrlf & vbcrlf & "into the container at URI " & vbcrlf & vbcrlf & " " & VBSTopObject.uri & vbcrlf & vbcrlf &  "Continue?", vbQuestion + vbYesNo, "MS Project Import into Metis") = vbYes then

'if MsgBox("Do you really want to import " & mppfile & " into the container with URI " & VBSTopObject.uri & "?", vbQuestion '+ vbYesNo, "MS Project to Metis") = vbYes then
   
   'MsgBox containerName & mppfile

   Set objMSP = CreateObject("MSProject.Application")
   objMSP.FileOpen (mppfile)
   Set project = objMSP.ActiveProject

   ' Create top object
   ' Does the project already exist?
   Call VBSUniqueIDArgument.setString(project.Name & project.UniqueID)
   Call VBSCriteria.setArgument("Unique ID", VBSUniqueIDArgument)
   set VBSCollection = metis.runCriteria(VBSCriteria)
   if VBSCollection.Count = 1 then
      Set VBSObject = VBSCollection.Item(1)
      Set VBSObjectView = VBSObject.views.Item(1)
   else
      Set VBSObject = VBSTopObject.newPart(VBSProjectType)
      Set VBSObjectView = VBSTopObjectView.newObjectView(VBSObject)
   end if

   Call SetProjectValues(VBSObject, project)

   ' Blank out ID field in tasks - used to delete MS Project deleted tasks
   set VBSCollection = metis.runCriteriaOnInstance(VBSCriteriaFindTasks, VBSObject)
   for each VBSInstance in VBSCollection
      Call VBSInstance.setNamedStringValue("taskId", "0")
   next 

   taskIndex = 1
   doLayout = False
   VBSErrorMsg = ""
   tasksNew = 0
   tasksUpdated = 0
   tasksDeleted = 0
   tasksMoved = 0

   Do
      Call newTask(VBSObject, VBSObjectView, project.Tasks.Item(taskIndex))
      If taskIndex < project.Tasks.Count Then
         taskIndex = taskIndex + 1
      End If
   Loop While taskIndex < project.Tasks.Count

   ' Delete tasks still having WBS = "0". These have been deleted in MS Project.
   set VBSCollection = metis.runCriteriaOnInstance(VBSCriteriaFindTasks, VBSObject)
   for each VBSInstance in VBSCollection
      if VBSInstance.getNamedStringValue("taskId") = "0" then
         tasksDeleted = tasksDeleted + 1
         Call VBSModel.deleteObject(VBSInstance)
      end if
   next 

   'if doLayout then
      Call metis.doLayout(VBSTopObjectView)
   'end if

   objMSP.FileClose(0)

   ' Cleaning up
   Set project = Nothing
   Set objMSP = Nothing
   Set task = Nothing
   Set VBSCollection = Nothing

   metis.runCommand("update-macros")

   if VBSErrorMsg = "" then
      VBSErrorMsg = "No errors found"
   end if
    
   MsgBox "MS Project to Metis sync completed" & vbCrLf & "Tasks created : " & tasksNew & vbCrLf & "Tasks updated : " & tasksUpdated & " (moved : " & tasksMoved & ")" & vbCrLf & "Tasks deleted : " & tasksDeleted & vbCrLf & vbCrLf & "Error log" & vbCrLf & VBSErrorMsg, vbInformation, "MS Project to Metis" 

end if

' Cleaning up
Set VBSContainerType  = Nothing
Set VBSProjectType  = Nothing
Set VBSTaskType  = Nothing
Set VBSModel  = Nothing
Set VBSModelView  = Nothing
Set VBSTopObject  = Nothing
Set VBSTopObjectView  = Nothing
Set VBSActionButton = Nothing
Set VBSCriteria = Nothing
Set VBSUniqueIDArgument = Nothing
Set VBSCriteriaFindTasks = Nothing
Set VBSInstance  = Nothing
Set VBSObject = Nothing
Set VBSObjectView = Nothing


Sub newTask(TopObject, TopObjectView, task)
   Dim outlineLevel
   Dim VBSObject
   Dim VBSObjectView
   outlineLevel = task.outlineLevel
' Does the task or project already exist?
   Call VBSUniqueIDArgument.setString(task.UniqueID)
   Call VBSCriteria.setArgument("Unique ID", VBSUniqueIDArgument)
   set VBSCollection = metis.runCriteria(VBSCriteria)
   if VBSCollection.Count = 1 then
      Set VBSObject = VBSCollection.Item(1)
      Set VBSObjectView = VBSObject.views.Item(1)
' Does the parent match?
      if (TopObject.uri <> VBSObject.parent.uri) and (TopObject.uri <> VBSObject.uri) then
         Call MoveObject(VBSObject, TopObject)
	 tasksMoved = tasksMoved + 1
'	 MsgBox "Mismatch on parent 1"
      end if
      tasksUpdated = tasksUpdated + 1
   else
      Set VBSObject = TopObject.newPart(VBSTaskType)
      Set VBSObjectView = TopObjectView.newObjectView(VBSObject)
      tasksNew = tasksNew + 1
   end if
   Call SetTaskValues(VBSObject, task)
   taskIndex = taskIndex + 1
   Do While taskIndex <= project.Tasks.Count
      If project.Tasks.Item(taskIndex).outlineLevel > outlineLevel Then
'         MsgBox "Recursing: " & project.Tasks.Item(taskIndex).name
         Call newTask(VBSObject, VBSObjectView, project.Tasks.Item(taskIndex))
      End If
      if taskIndex > project.Tasks.Count then Exit Do
      If project.Tasks.Item(taskIndex).outlineLevel < outlineLevel Then
         Exit Sub
      End If
      If project.Tasks.Item(taskIndex).outlineLevel = outlineLevel Then
         Do While project.Tasks.Item(taskIndex).outlineLevel = outlineLevel
            'Call VBSUniqueIDArgument.setString(project.Tasks.Item(taskIndex).Parent & project.Tasks.Item(taskIndex).UniqueID)
            Call VBSUniqueIDArgument.setString(project.Tasks.Item(taskIndex).UniqueID)
            Call VBSCriteria.setArgument("Unique ID", VBSUniqueIDArgument)
            set VBSCollection = metis.runCriteria(VBSCriteria)
            if VBSCollection.Count = 1 then
               Set VBSObject = VBSCollection.Item(1)
               Set VBSObjectView = VBSObject.views.Item(1)
' Does the parent match?
	       if TopObject.uri <> VBSObject.parent.uri then
         	  Call MoveObject(VBSObject, TopObject)
		  tasksMoved = tasksMoved + 1
'	          MsgBox "Mismatch on parent 2"
	       end if
	       tasksUpdated = tasksUpdated + 1
	    else
		Set VBSObject = TopObject.newPart(VBSTaskType)
		Set VBSObjectView = TopObjectView.newObjectView(VBSObject)
		tasksNew = tasksNew + 1
            end if
            Call SetTaskValues(VBSObject, project.Tasks.Item(taskIndex))
            If taskIndex < project.Tasks.Count Then
               taskIndex = taskIndex + 1
            Else
               Exit Sub
            End If
         Loop
      End If
   Loop
End Sub

Sub MoveObject(VBSObject, TopObject)
   Dim VBSSelection
   Set VBSSelection = metis.newInstanceList
   VBSSelection.AddFirst(VBSObject)
   Call VBSModelView.select(VBSSelection)
   Call metis.runCommand("cut-structure")
'   Call metis.runCommand("copy-sel-tab")
'   MsgBox "Copied"
   VBSSelection.RemoveAt(1)
   VBSSelection.AddFirst(TopObject)
   Call VBSModelView.select(VBSSelection)
   Call metis.runCommand("paste-structure")
'   MsgBox "Pasted"
End Sub

Sub SetTaskValues(obj, task)
   Dim VBSValueSet
   Dim VBSValueSet1
   Dim VBSValueSet2
   Dim VBSValueSet3
   Dim VBSValueSet4
   Dim VBSValueSet5
   Dim VBSValueSet6
   Dim VBSValueSet7

'   Call obj.setNamedStringValue("name", task.WBS & " " & task.Name)
   Call obj.setNamedStringValue("name", task.Name)
'   Call obj.setNamedStringValue("externalID", task.ID)
   Call obj.setNamedStringValue("taskId", task.WBS)
   Call obj.setNamedStringValue("description", task.Text1)
' Date when button pressed
   set VBSValueSet4 = metis.newValue()
   ' Time removed 1/24/2005 BN
   Call VBSValueSet4.setDateByNumbers(Year(Date), Month(Date), Day(Date))
'   Call obj.setNamedValue("status_as_of_date", VBSValueSet4)
' Date properties
   Call setDate(obj, "plannedStartDate", task.Start)
   Call setDate(obj, "plannedFinishDate", task.Finish)
   Call setDate(obj, "actualStartDate", task.ActualStart)
   Call SetDate(obj, "actualFinishDate", task.ActualFinish)
' Priority
'   set VBSValueSet5 = metis.newValue()
'   if task.Priority < 334 then   ' Low
'      Call VBSValueSet5.setInteger(3)
'   elseif task.Priority > 666 then  ' Medium
'      Call VBSValueSet5.setInteger(1)
'   else   ' High
'      Call VBSValueSet5.setInteger(2)
'   end if
'   Call obj.setNamedValue("priority", VBSValueSet5) 
' UniqueID
   set VBSValueSet6 = metis.newValue()
'   Call VBSValueSet6.setString(task.Parent & task.ID)
   Call VBSValueSet6.setString(task.UniqueID)
   Call obj.setNamedValue("externalID", VBSValueSet6)
' Sort Field
  '    set VBSValueSet7 = metis.newValue()
  '    Call VBSValueSet7.setInteger(CInt(task.ID))
  '    Call obj.setNamedValue("sortid", VBSValueSet7)
' Only on leaf nodes:
   if task.OutlineChildren.Count = 0 then
' Planned cost
      set VBSValueSet = metis.newValue()
      Call VBSValueSet.setFloat(task.cost)
      Call obj.setNamedValue("plannedCost", VBSValueSet)
' Actual cost
      set VBSValueSet1 = metis.newValue()
      Call VBSValueSet1.setFloat(task.ActualCost)
      Call obj.setNamedValue("actualCost", VBSValueSet1)
' Planned completeness
      'set VBSValueSet2 = metis.newValue()
      'Call VBSValueSet2.setInteger(CInt(task.PercentComplete))
      'Call obj.setNamedValue("plannedCompleteness", VBSValueSet2)
' Percent work complete
      set VBSValueSet3 = metis.newValue()
      Call VBSValueSet3.setInteger(CInt(task.PercentWorkComplete))
      Call obj.setNamedValue("completionPercentage", VBSValueSet3)
   end if

End Sub

Sub setDate(obj, prop, date) 
' The format of date depends on Regionale Settings. We use the VBScript
' function CDate to convert from this format to integer values representing
' year, month, day, hour, etc. 
' When regionale is Norwegian, the date is in the format '29.06.2004 08:04:34'. 
' When regionale is US, the date is in the format '29/06/2004 08.04.34 PM'. 
' Must be converted to a format that Metis can understand.

   Dim VBSValueSet
   if date = "NA" then Exit Sub
'  VBSErrorMsg = vbCrLf & VBSErrorMsg & date  
'  MsgBox date
'  MsgBox CLng(Year(DateValue(Replace(Left(date, 10),".","/"))))
   set VBSValueSet = metis.newValue()

'   Call VBSValueSet.setDateByNumbers(CLng(Year(DateValue(Replace(Left(date, 10),".","/")))), CLng(Month(DateValue(Replace(Left(date, 10),".","/")))), CLng(Day(DateValue(Replace(Left(date, 10),".","/")))))
'   Call VBSValueSet.setTimeByNumbers(Hour(TimeValue(Right(date, 8))), Minute(TimeValue(Right(date, 8))), Second(TimeValue(Right(date, 8))), 0)

   if IsDate(date) then
'      MsgBox Year(CDate(date)) & Month(CDate(date)) & Day(CDate(date))
      Call VBSValueSet.setDateByNumbers(Year(CDate(date)), Month(CDate(date)), Day(CDate(date)))
   else
      VBSErrorMsg = vbCrLf & VBSErrorMsg & "Could not interpret date: " & date
   end if

'   Call VBSValueSet.setDateByNumbers(Year(DateValue(Replace(Left(date, 10),".","/"))), Month(DateValue(Replace(Left(date, 10),".","/"))), Day(DateValue(Replace(Left(date, 10),".","/"))))
   Call obj.setNamedValue(prop, VBSValueSet) 

'  MsgBox VBSValueSet.getDate & " " & VBSValueSet.getTime
'  MsgBox Month(DateValue(Replace(Left(task.Start, 10),":","/")))
'  MsgBox Left(task.Start, 10) & " " & Right(task.Start, 8)

End Sub

Sub SetProjectValues(obj, project)
   Dim VBSValueSet1
   Dim VBSValueSet2

   Call obj.setNamedStringValue("name", project.FullName)
   Call obj.setNamedStringValue("taskId", project.Name)
' Date when button pressed
   set VBSValueSet1 = metis.newValue()
   Call VBSValueSet1.setDateByNumbers(Year(Date), Month(Date), Day(Date))
'   Call obj.setNamedValue("status_as_of_date", VBSValueSet1)
' Date properties
   Call setDate(obj, "plannedStartDate", project.ProjectStart)
   Call setDate(obj, "plannedFinishDate", project.ProjectFinish)
' UniqueID
   set VBSValueSet2 = metis.newValue()
   Call VBSValueSet2.setString(project.Name & project.UniqueID)
   Call obj.setNamedValue("externalID", VBSValueSet2)

End Sub

