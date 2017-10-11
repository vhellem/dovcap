'
' Commit Control - Set Selected Objects Utility
'
' Owner: Troux TSG
'
' Author: Dan Belville
'   
' Updated By:(CP & Dan, 4th Nov.)
'   updated to force all objects and relationsips to a commit state without asking . First all to keep local , then everything in the snapshot to commit
'
' Updated Date: 16th November 2010
'
' Date: May, 2006
'
' Copyright (C) 2006 Troux Technologies . All rights reserved.
'
' SCRIPT PURPOSE
'
'   Used to set the ME commit flag on objects to either commit or keep local. 
'
' GUIDE FOR USING THIS SCRIPT
'
' GUIDE FOR CONFIGURING THIS SCRIPT
' 
'----------------------------------------------------------------
' Declare your parameters here
'----------------------------------------------------------------
'
'Global Variables
'----------------
Dim ifModel, ifModelView, repositoryCheckProperty, ifObjectTypeColl, ifObjectType, objectToAdd, dialogTypeCol
Dim ifDialog, controlContainer, commitCount, ifSelectedColl, ifPart, allInstancesOfType, objectURI
Dim ifObject, startingInstanceView, parentView, objectType, startingInstance, commitFlag, commitLimit
Dim foundInModelView
DIM modelviewtouse

Function setbeforecommit()

'Initialize Constants
'--------------------
Set ifModel = metis.currentModel
Set ifModelView = ifModel.currentModelView
Set modelViews = ifModel.views

commitFlag = "Keep Local"

for each ifObject in ifModel.UsedObjectTypes
    set allInstancesOfType = ifModel.findInstances(ifObject, "", "")
	for each ifInstance in allInstancesOfType
		 on ERROR Resume Next
		 ifInstance.setNamedStringValue "dbms-admin.commitFlag", commitFlag
		 on ERROR goto 0
	next
next

for each ifObject in ifModel.UsedRelationshipTypes
    set allInstancesOfType = ifModel.findInstances(ifObject, "", "")
	for each ifInstance in allInstancesOfType
		 on ERROR Resume Next
		 ifInstance.setNamedStringValue "dbms-admin.commitFlag", commitFlag
		 on ERROR goto 0
	next
next

for each modelView in modelViews 
    if modelView.title = "Snapshots" then
	  set modelviewtouse = modelview
	end if
next

call findallobjects(modelviewtouse)

setbeforecommit = -1
end function 

sub findallobjects(view)
Dim views, instanceview
Set views = view.children 
for each instanceview in views
	on ERROR resume next
	instanceview.instance.setNamedStringValue "dbms-admin.commitFlag", "Commit"
	on ERROR goto 0
	if instanceview.children.count > 0 then 
		call findallobjects(instanceview)
	end if
next
end sub
 


