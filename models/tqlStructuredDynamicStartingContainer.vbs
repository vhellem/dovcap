OPTION Explicit
On Error GoTo 0

' The following lines enable a script editor (OnScript) to expose the API object model in the editor
' without affecting the running of the script from with Metis, and can be removed or commented out if necessary
On Error Resume Next
if 1 > 2 Then
	Set metis = CreateObject("Metis.Application")
End If
On Error GoTo 0


'
' VBScript utility
'
' Date: January, 2006
' Original Author:  Joachim Lund
' Updated By:  Daniel Belville
'
' Copyright (C) 2006 Troux Technologies . All rights reserved.
'
'
' GUIDE FOR USING THIS SCRIPT
'
'  This is a script that reads a configuration container. The configuration container should be populated with object types and relationships between them. In addition there should be one
' container in there called the value of PARAM_STR_START_CONTAINER_NAME. In this container you should put one and ony one instance. The script will get all of the type present in start from
' the repository. It will prompt the user for a selection (can be multiple) and from that traverse a path. The path traversed is the same as defined in the configuration
'
' Container destination behaviour: In the name fields of the objects that are part of the configuration, you can specify the relative URL to a target container. I.e. #udisada
'
' The name field can instead specify a name for the container to create and place the object in.
'
' Model View behaviour: The script work in context of the current ModelView. If instances exist in the model, this script WILL CREATE new views.See the Sub CreateViewRoutine for detailed
' behaviour
'
' GUIDE FOR CONFIGURING THIS SCRIPT

' Uses one parameter: 
' PARAM_STR_CONFIG_CONTAINER_OID The oid of the container which contains the configuration of the query.
' PARAM_STR_START_CONTAINER_NAME The name of the start container in the configuration.
'----------------------------------------------------------------
' Declare your parameters here
'----------------------------------------------------------------
Dim PARAM_STR_CONFIG_CONTAINER_OID
Dim PARAM_HIGHEST_LEVEL_CONTAINER_OID
Dim PARAM_STR_START_CONTAINER_NAME
Dim ME_QUERY_TYPE_URI
Dim  CONST_STR_METHOD_ONE_URI, CONST_STR_METHOD_TWO_URI, CONST_METHOD_ONE,CONST_METHOD_TWO, CONST_STR_CONTAINER_TYPE_URI, CONST_STR_COMMENT_TYPE_URI, CONST_MER_TYPE
Dim oCurrentModel, containersAdded, containerList 
Dim oConfigContainer, oStartObject, oPossibleContainerChild, oStartContainer, oResultFromRepository, strQueryZeroFirst
Dim tempContainer, tempContainerPart, tempContainerParts
Dim oSelectedInstanceFirst, oSelectedInstanceFirst_uri, oSelectedObjectCollectionFirst, containerPart, checkInstanceNameFirst
Dim exitScript, oCurrentModelView, highestLevelContainerTypeURI, topContainerTypeURI, targetContainerTypeURI
Dim containerAdded, containerAddedView, containerAddedViews
Dim MEQueries, MEQuery, testString, queryMethod
Dim tempContainerView
Dim objMetisProgressDialog, progress
Dim highestLevelContainer, highestLevelContainerView
Dim oStartRelFirst, useContainerTitle
Dim hLevelContainerView, hLevelContainerViews
Dim checkDeleteTargetContainer, checkDeleteTargetContainers, checkDeleteTopLevelContainer, checkDeleteTopLevelContainers, checkDeleteTargetContainerElements

'----------------------------------------------------------------
' Set your parameters default here
'----------------------------------------------------------------
PARAM_STR_CONFIG_CONTAINER_OID = ""
PARAM_HIGHEST_LEVEL_CONTAINER_OID = ""
PARAM_STR_START_CONTAINER_NAME = "Start"	
ME_QUERY_TYPE_URI = "metis:troux#TrouxQuery"

'----------------------------------------------------------------
'Constants and global variables 
'----------------------------------------------------------------

'Initialize global variables. metis is already set
Set oCurrentModel = metis.currentModel
Set oCurrentModelView = oCurrentModel.currentModelView


CONST_STR_METHOD_ONE_URI = "http://metadata.troux.info/serviceutilities/tqlmodeler/methods/extra_tql_methods.kmd#QueryUsingParameters_from_script"
CONST_STR_METHOD_TWO_URI = "http://metadata.troux.info/serviceutilities/tqlmodeler/methods/extra_tql_methods.kmd#RelationshipOnlyQuery"
CONST_STR_CONTAINER_TYPE_URI = "metis:stdtypes#oid3"
CONST_STR_COMMENT_TYPE_URI = "metis:stdtypes#oid22"

Set CONST_METHOD_ONE = metis.findMethod(CONST_STR_METHOD_ONE_URI)
Set CONST_METHOD_TWO = metis.findMethod(CONST_STR_METHOD_TWO_URI)
Set CONST_MER_TYPE = metis.findType("metis:mer#MerObjectProp")
CONST_METHOD_TWO.setArgument1 "EnsureRelationshipEndObjects", 0

'----------------------------------------------------------------
' Enable users to override from Metis here
'----------------------------------------------------------------


Call overrideFromMetis("CONST_STR_CONTAINER_TYPE_URI",CONST_STR_CONTAINER_TYPE_URI)
Call overrideFromMetis("PARAM_HIGHEST_LEVEL_CONTAINER_OID",PARAM_HIGHEST_LEVEL_CONTAINER_OID)
Call overrideFromMetis("PARAM_STR_CONFIG_CONTAINER_OID",PARAM_STR_CONFIG_CONTAINER_OID)
Call overrideFromMetis("PARAM_STR_START_CONTAINER_NAME",PARAM_STR_START_CONTAINER_NAME)


'used to build a list of containers added for each set of queries run from the initial selection list
Set containerList = metis.newInstanceList()

'The exitScript flag is used to exit the script if the startQuery sub function exits because of issues
exitScript = 0
'Starts the script running and checks for issues before looping through selected queries

Set objMetisProgressDialog = CreateObject("Metis.ProgressBar." & metis.versionMajor & "." & metis.versionMinor)

Call startQuery

'After returning from starsQuery this loop provides a dialog to select queries from starting object and then calls the getConfigAndInitialCollection sub function for each query selected 
if exitScript = 0 then

objMetisProgressDialog.title = "Repository Query Progress Indicator"
objMetisProgressDialog.interactive = True
objMetisProgressDialog.logVisible = True
objMetisProgressDialog.logExpanded = False
objMetisProgressDialog.setProgressStatus "Performing Repository Queries"
progress = 1

 useContainerTitle = 0
 For each oStartRelFirst in oStartObject.neighbourRelationships	
   if oStartRelFirst.target.type.title = "TQL Modeler Container Specification" then
      checkInstanceNameFirst = oStartRelFirst.target.getNamedStringValue("name")
      useContainerTitle = 1
   end if
 next
 For each oSelectedInstanceFirst in oSelectedObjectCollectionFirst
  if useContainerTitle = 0 then
    checkInstanceNameFirst = oSelectedInstanceFirst.name
  end if
  oSelectedInstanceFirst_uri = oSelectedInstanceFirst.uri
  set tempContainerParts =  tempContainer.parts
  for each containerPart in tempContainerParts
     if oSelectedInstanceFirst.uri = containerPart.uri then
       oCurrentModel.deleteObject(oSelectedInstanceFirst)
     end if
  next
  Set MEQueries = oCurrentModel.findInstances(metis.findType(ME_QUERY_TYPE_URI),"","")
  testString = 0
  for each MEQuery in MEQueries
    queryMethod = MEQuery.getNamedStringValue("queryMethod")
    testString = inStr(queryMethod,"tqlmodeler") 
    if testString > 0 then
     oCurrentModel.deleteObject(MEQuery)
     end if
  next
  Set containersAdded = metis.newInstanceList()
  Call getConfigAndInitialCollection (oSelectedInstanceFirst_uri, checkInstanceNameFirst)
  for each containerAdded in containersAdded
     set containerAddedViews = containerAdded.views
     for each containerAddedView in containerAddedViews
          containerAddedView.doLayout
          containerAddedView.parent.doLayout
     next
  next
 next
end if
Set MEQueries = oCurrentModel.findInstances(metis.findType(ME_QUERY_TYPE_URI),"","")
testString = 0
for each MEQuery in MEQueries
   queryMethod = MEQuery.getNamedStringValue("queryMethod")
   testString = inStr(queryMethod,"tqlmodeler") 
   if testString > 0 then
     oCurrentModel.deleteObject(MEQuery)
   end if
next
oCurrentModel.deleteObject(tempContainer)
objMetisProgressDialog.setPercentDone 100

'set checkDeleteTopLevelContainers = highestLevelContainer.parts
'for each checkDeleteTopLevelContainer in checkDeleteTopLevelContainers
'   set checkDeleteTargetContainers = checkDeleteTopLevelContainer.parts
'   if checkDeleteTargetContainers.Count < 1 then
'       oCurrentModel.deleteObject(checkDeleteTopLevelContainer)
'   end if
'   for each checkDeleteTargetContainer in checkDeleteTargetContainers
'   set checkDeleteTargetContainerElements = checkDeleteTargetContainer.parts
'      if checkDeleteTargetContainerElements.Count < 1 then 
'        oCurrentModel.deleteObject(checkDeleteTargetContainer)
'      end if
'   next
'next
'for each checkDeleteTopLevelContainer in checkDeleteTopLevelContainers
'   set checkDeleteTargetContainers = checkDeleteTopLevelContainer.parts
'   if checkDeleteTargetContainers.Count < 1 then
'       oCurrentModel.deleteObject(checkDeleteTopLevelContainer)
'   end if
'next

Sub startQuery
Dim eachResult, oInstance

Set highestLevelContainer = metis.findInstance(metis.currentModel.url&PARAM_HIGHEST_LEVEL_CONTAINER_OID)
set hLevelContainerViews = highestLevelContainer.views
for each hLevelContainerView in hLevelContainerViews
  Set highestLevelContainerView = hLevelContainerView
next

	
topContainerTypeURI = oCurrentModel.currentInstance.getNamedStringValue("topContainerType")
if topContainerTypeURI = "" then
	topContainerTypeURI = "metis:stdtypes#oid3"
end if
	
targetContainerTypeURI = oCurrentModel.currentInstance.getNamedStringValue("targetContainerType")
if targetContainerTypeURI = "" then
	targetContainerTypeURI = "metis:stdtypes#oid3"
end if
	
Set oConfigContainer = Nothing
Set oConfigContainer = metis.findInstance(metis.currentModel.url&PARAM_STR_CONFIG_CONTAINER_OID)
If oConfigContainer is Nothing or PARAM_STR_CONFIG_CONTAINER_OID = "" Then '
  Msgbox "Configuration not complete, each action button using this script has to specify a configuration container oid in the variables field with name PARAM_STR_CONFIG_CONTAINER_OID"
  exitScript = 1
  Exit Sub
End if

Set oStartContainer = Nothing
For each oPossibleContainerChild in oConfigContainer.parts
  If oPossibleContainerChild.type.uri = CONST_STR_CONTAINER_TYPE_URI AND oPossibleContainerChild.name = PARAM_STR_START_CONTAINER_NAME Then
  Set oStartContainer = oPossibleContainerChild
  End if
Next
If oStartContainer is Nothing Then
  Msgbox "Configuration not complete, each Config Container should have one and only one start container", vbError,"Model misconfiguration"	
  exitScript = 1
  Exit Sub
End if
If oStartContainer.parts.count <> 1 Then
  Msgbox "Configuration not complete, each Start Container should have one and only one startingobject", vbError,"Model misconfiguration"
  exitScript = 1
  Exit Sub
End if	

Set oStartObject = oStartContainer.parts.Item(1)

strQueryZeroFirst = ""
strQueryZeroFirst = "component.type ="""&oStartObject.type.title&""""&getAdditionalQueryFromConfig (oStartObject)
CONST_METHOD_ONE.setArgument1 "Query0", strQueryZeroFirst
CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0 
set tempContainer = oCurrentModel.newObject(metis.findType("metis:stdtypes#oid3"))
Call tempContainer.setNamedStringValue("name", "Temp Container")
'set tempContainerView = oCurrentModel.currentModelView.newObjectView(tempContainer)
Set oResultFromRepository = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,tempContainer)

Set oSelectedObjectCollectionFirst = getSelectDialog (oResultFromRepository.getCollection, "Query Selection Dialog", "Choose the Object To Query", False)
If oSelectedObjectCollectionFirst.count < 1 Then
  MsgBox "Nothing was selected"
  exitScript = 1
  'Deleting the ones that we originally got back and didnt choose (if they dont have views) 
  For each oInstance in oResultFromRepository.getCollection
   If oInstance.views.count = 0 Then
	oCurrentModel.deleteObject(oInstance)
   End if
  Next
  Exit Sub
End If	
End Sub

Sub getConfigAndInitialCollection (oSelectedInstance_uri, checkInstanceName)
	Dim strQueryZero
	Dim oStartRel, oInstance, oView, oTargetContainer, oTargetContainerCollection,oTargetContainerCandidate, oPartCandidate, bolExtraQuery, strNextQuery
	Dim topContainer, topContainerView, containerView, ifInstanceColl, oTargetContainerView
	Dim targetContainerCollection, targetContainerPart
	Dim topContainerAlreadyAdded, topContainerViews, tcView, oTargetContainerViews
	Dim msgText
	Dim containerCollection, objListDialogBox, containerInModel, containerInModelView, containerInModelViews, containerItem
        Dim oSelectedInstance, oSelectedObjectCollection
	Dim ifOriginInstance, topContainerColl, topContainerCandidate
	Dim topContainerFound
	
	if progress > 90 then
	   progress = 50
	   objMetisProgressDialog.appendToLog "(---> Progress Bar Estimate Reset <---)" & VbCrLf
           objMetisProgressDialog.setPercentDone progress
           objMetisProgressDialog.show 
        else 
	   progress = progress + 5
           objMetisProgressDialog.setPercentDone progress
           objMetisProgressDialog.show 
	end if
	objMetisProgressDialog.appendToLog "Performing Query for Component Type '" & oStartObject.type.title & "' and Children" & VbCrLf
	
        Set topContainer = Nothing
        Set oTargetContainer = Nothing
	Set oTargetContainer = metis.findInstance(metis.currentModel.url&oStartObject.name)  'Try the name URI first
	if oTargetContainer is Nothing then
	   topContainerFound = 0
  	  'to see if topContainer exists or not
	   Set topContainerColl = oCurrentModel.findInstances(metis.findType(topContainerTypeURI),"name",checkInstanceName)
	   For each topContainerCandidate in topContainerColl
             if topContainerCandidate.name = checkInstanceName then
	        Set topContainer = topContainerCandidate
		Set topContainerViews = topContainer.views
		for each tcView in topContainerViews
		    set topContainerView  = tcView
		    topContainerFound = 1
		next
	     end if
           next
	   if topContainerFound = 0 then
		   Set topContainer = highestLevelContainer.newPart(metis.findType(topContainerTypeURI))
	           Call topContainer.setNamedStringValue("name", checkInstanceName)
		   set topContainerView = highestLevelContainerView.newObjectView(topContainer)
	   end if
	end if

	topContainerAlreadyAdded = 0

	If oTargetContainer is Nothing Then
		On Error Resume Next
		Set oTargetContainerCollection = oCurrentModel.findInstances(metis.findType(topContainerTypeURI),"name",checkInstanceName) ' Then try to find container that mathces name
		'If there is a container called the same as the name in this modelview, then use this container as target
		For each oTargetContainerCandidate in oTargetContainerCollection 
                   if oTargetContainerCandidate.name = checkInstanceName then
			   topContainerAlreadyAdded = 1
			   set topContainer = oTargetContainerCandidate
		   end if
		   set targetContainerCollection = oTargetContainerCandidate.parts
                   For each targetContainerPart in targetContainerCollection
			if (oStartObject.name = targetContainerPart.name) Or (oStartObject.type.title = targetContainerPart.name) Then
				Set oTargetContainer = targetContainerPart
			        set oTargetContainerViews = oTargetContainer.views
			        for each tcView in oTargetContainerViews
			        	set oTargetContainerView  = tcView
			        next
			        set topContainerViews = topContainer.views
			        for each tcView in topContainerViews
			        	set topContainerView  = tcView
			        next
				Exit For
			End if
		   next
		Next
		On Error Goto 0
	End if

	If oTargetContainer is Nothing Then
	       if topContainerAlreadyAdded = 0 then
	            Set topContainer = highestLevelContainer.newPart(metis.findType(topContainerTypeURI))
	            Call topContainer.setNamedStringValue("name", checkInstanceName)
	            set topContainerView = highestLevelContainerView.newObjectView(topContainer)
	       else
		   set topContainerViews = topContainer.views
		   for each tcView in topContainerViews
		  	set topContainerView  = tcView
		   next
	       end if
	       Set oTargetContainer = topContainer.newPart(metis.findType(targetContainerTypeURI))
	       if oStartObject.name = "" then
	          Call oTargetContainer.setNamedStringValue("name",oStartObject.type.title)
	       else
	          Call oTargetContainer.setNamedStringValue("name",oStartObject.name)
	       end if
	       set oTargetContainerView = topContainerView.newObjectView(oTargetContainer)
	       Call containersAdded.AddLast(oTargetContainer)
	End if

	' Ok, I have the startObject, meaning I have the start object type, meaning I can ask the server for each object of this type
	' Users also have the possibility to restrict the choice with additional queries

	   strQueryZero = ""
	   strQueryZero = strQueryZero &"Component.id = '" &  getRepositoryId(oSelectedInstance_uri) & "'"
	   CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
	   CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0 
	   Set oResultFromRepository = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer)

	   Set oSelectedObjectCollection = oResultFromRepository.getCollection
	   
	' If user has modelled a part or a parent to this object, then ancestor and/or descendants must also be queried for
	strQueryZero = ""
	For each oSelectedInstance in oSelectedObjectCollection
		strQueryZero = strQueryZero &"Component.id = '" &  getRepositoryId(oSelectedInstance.uri) &"' OR " 'This query is the TQL represenation of the Result from the Select Dialog
	Next
	strQueryZero = Left (strQueryZero, Len(strQueryZero) - 4) 
	bolExtraQuery = false
	For each oPartCandidate in oStartObject.parts
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE) Then ' Users might model comments
			 strQueryZero = strQueryZero&" OR (Component.hasAncestor("&strQueryZero&"))"
			 bolExtraQuery = true
			 Exit For
		End if
	Next
	If Not oStartObject.parent.isContainer Then 
		 strQueryZero = strQueryZero&" OR (Component.hasDescendant("&strQueryZero&"))"
		 bolExtraQuery = true
	End if
	' Run a new query asking for the objects from the select dialog (unncessesary) but also objects that are descendants and/or ancestors of these objects
	if bolExtraQuery Then
		CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
		CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0 
		Set oSelectedObjectCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer).getCollection
	End if

	'Building the query that indentifies the results from the last query to send to the neighbor and also create views
	strNextQuery =""
	For each oInstance in oSelectedObjectCollection
	     Call createViewRoutine (oTargetContainer,oInstance)
	     strNextQuery = strNextQuery &"Component.id = '" &  getRepositoryId(oInstance.uri) &"' OR "
	     objMetisProgressDialog.appendToLog "Query Returned '" & oInstance.type.title & "' (" & oInstance.name & ")" & VbCrLf
	Next
	strNextQuery = Left(strNextQuery, Len(strNextQuery) - 4) 
	
	'Deleting the ones that we originally got back and didnt choose (if they dont have views) 
	For each oInstance in oResultFromRepository.getCollection
		If oInstance.views.count = 0 Then
		'	oCurrentModel.deleteObject(oInstance)
		End if
	Next

	'Sending to neighbor
	For each oStartRel in oStartObject.neighbourRelationships	
		if oStartRel.target.uri = oStartObject.uri  Then 'Other end is origin
	           if oStartRel.origin.type.title <> "TQL Modeler Container Specification" then
			Call recursiveQueryGenerator(oStartRel.origin, oStartRel.target, strNextQuery, oStartRel, topContainer, topContainerView, checkInstanceName)
		   end if
		Elseif oStartRel.origin.uri = oStartObject.uri  Then
	           if oStartRel.target.type.title <> "TQL Modeler Container Specification" then
			Call recursiveQueryGenerator(oStartRel.target,oStartRel.origin, strNextQuery, oStartRel, topContainer, topContainerView, checkInstanceName)	
		   end if
		End if	
	Next
	
End sub

Sub recursiveQueryGenerator (oNextInstance, oLastInstance, strLastInstanceQuery, oRelationshipInstance, topContainer, topContainerView, checkInstanceName)
	Dim oTargetContainer,oTargetContainerCandidate,oTargetContainerCollection, oInstanceFromRepositoryCollection, strNextQuery, oInstance, oStartRel, oPartCandidate
	Dim strQueryZero
	strNextQuery = ""
	Dim oTargetContainerView, alreadyAdded, ifContainer, targetContainerPart, targetContainerCollection
	Dim msgText
	Dim oNextRelFirst
	Dim checkInstanceNameContainer
	Dim topContainerSpecified, topContainerSpecifiedView, topContainerSpecifiedViews, tcView

	if progress > 90 then
	   progress = 50
	   objMetisProgressDialog.appendToLog "(---> Progress Bar Estimate Reset <---)" & VbCrLf
           objMetisProgressDialog.setPercentDone progress
           objMetisProgressDialog.show 
        else 
	   progress = progress + 5
           objMetisProgressDialog.setPercentDone progress
           objMetisProgressDialog.show 
	end if
	objMetisProgressDialog.appendToLog "Performing Query for Component Type '" & oNextInstance.type.title & "' and Children" & VbCrLf
	
	'Getting target container
	Set oTargetContainer = Nothing
	Set oTargetContainer = metis.findInstance(metis.currentModel.url&oNextInstance.name)  'Try the name URI first

	If oTargetContainer is Nothing Then
		On Error Resume Next
		Set oTargetContainerCollection = oCurrentModel.findInstances(metis.findType(topContainerTypeURI),"name",checkInstanceName) ' Then try to find container that mathces name
		For each oTargetContainerCandidate in oTargetContainerCollection 
		   set targetContainerCollection = oTargetContainerCandidate.parts
                   For each targetContainerPart in targetContainerCollection
			if (oNextInstance.name = targetContainerPart.name) Or (oNextInstance.type.title = targetContainerPart.name) Then
				Set oTargetContainer = targetContainerPart
				Exit For
			End if
		   next
		Next
		On Error Goto 0
	End if

	If oTargetContainer is Nothing Then
		           Set topContainerSpecified = Nothing
                           For each oNextRelFirst in oNextInstance.neighbourRelationships	
                              if oNextRelFirst.target.type.title = "Container" then
				 Set oTargetContainerCollection = oCurrentModel.findInstances(metis.findType(topContainerTypeURI),"name",oNextRelFirst.target.getNamedStringValue("name"))
		                 For each oTargetContainerCandidate in oTargetContainerCollection 
				   if oTargetContainerCandidate.name = oNextRelFirst.target.getNamedStringValue("name") then
				        set topContainerSpecified = oTargetContainerCandidate
		  		        set topContainerSpecifiedViews = topContainerSpecified.views
		                        for each tcView in topContainerSpecifiedViews
		  	                     set topContainerSpecifiedView  = tcView
		                        next
		                        set targetContainerCollection = oTargetContainerCandidate.parts
                                        For each targetContainerPart in targetContainerCollection
			                    if (oNextInstance.name = targetContainerPart.name) Or (oNextInstance.type.title = targetContainerPart.name) Then
				                Set oTargetContainer = targetContainerPart
				                Exit For
			                    end if
				        next
				   end if
				 next
				 if topContainerSpecified is Nothing then
                                    checkInstanceName = oNextRelFirst.target.getNamedStringValue("name")
		                    Set topContainerSpecified = highestLevelContainer.newPart(metis.findType(topContainerTypeURI))
	                            Call topContainerSpecified.setNamedStringValue("name", checkInstanceName)
		                    set topContainerSpecifiedView = highestLevelContainerView.newObjectView(topContainerSpecified)
			         end if
                              end if
                           next
		           alreadyAdded = 0
                           for each ifContainer in containersAdded 
                               if oNextInstance.name = ifContainer.name then
				   set oTargetContainer = ifContainer 
				   alreadyAdded = 1
                               end if
		            next
          		    if alreadyAdded = 0 then
                              if topContainerSpecified is Nothing then
			       Set oTargetContainer = topContainer.newPart(metis.findType(targetContainerTypeURI))
			       if oNextInstance.name = "" then
		                    Call oTargetContainer.setNamedStringValue("name",oNextInstance.type.title)
			       else
		                    Call oTargetContainer.setNamedStringValue("name",oNextInstance.name)
		               end if
			       set oTargetContainerView = topContainerView.newObjectView(oTargetContainer)
			       Call containersAdded.AddLast(oTargetContainer)
		              else
                                if oTargetContainer is Nothing then
			          Set oTargetContainer = topContainerSpecified.newPart(metis.findType(targetContainerTypeURI))
			          if oNextInstance.name = "" then
		                       Call oTargetContainer.setNamedStringValue("name",oNextInstance.type.title)
			          else
		                       Call oTargetContainer.setNamedStringValue("name",oNextInstance.name)
		                  end if
			          set oTargetContainerView = topContainerSpecifiedView.newObjectView(oTargetContainer)
			          Call containersAdded.AddLast(oTargetContainer)
			        end if
		              end if
		            end if
	End if

	'Setting up the initial query string
	strQueryZero = ""
	strQueryZero ="(Component.exactType ='"&oNextInstance.type.title&"'" & getAdditionalQueryFromConfig (oNextInstance)&" AND Component.hasRelationship(Relationship.exactType ='"&oRelationshipInstance.type.title&"' AND Relationship.hasComponent("&strLastInstanceQuery&")))" 
	
	' If user has modelled a part or a parent to this object, then ancestor and/or descendants are also part of the query
	For each oPartCandidate in oNextInstance.parts
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE) Then ' Users might model comments
			 strQueryZero = strQueryZero&" OR (Component.hasAncestor("&strQueryZero&"))"
			 Exit For
		End if
	Next
	If Not oNextInstance.parent.isContainer Then 
		 strQueryZero = strQueryZero&" OR (Component.hasDescendant("&strQueryZero&"))"
	End if


	'Execute the query to get the result
	CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
	Set oInstanceFromRepositoryCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer).getCollection
	If oInstanceFromRepositoryCollection.count = 0 Then
	        objMetisProgressDialog.appendToLog "Nothing Returned for '" & oNextInstance.type.title & "'" & VbCrLf
		Exit Sub
	End if

	'Building the query that indentifies the results from the last query to send to the neighbor and also create views
	For each oInstance in oInstanceFromRepositoryCollection
		Call createViewRoutine (oTargetContainer,oInstance)
		 strNextQuery = strNextQuery &"Component.id = '" &  getRepositoryId(oInstance.uri) &"' OR "
	         objMetisProgressDialog.appendToLog "Query Returned '" & oInstance.type.title & "' (" & oInstance.name & ")" & VbCrLf
	Next
	strNextQuery = Left(strNextQuery, Len(strNextQuery) - 4) 
	
'	msgText = "Repository Query Completed for" & Chr(13) & Chr(13)
'	for each oInstance in oInstanceFromRepositoryCollection
'		msgText = msgText + "Object Name Is(" & oInstance.name & ") Object Type Is(" & oInstance.type.name & ")" & Chr(13)
'        next
'	msgText = msgText + Chr(13) & "Please Press OK to Continue" & Chr(13) '	msgbox msgText 
	'Now, get the relationships
	'Msgbox "Relationship.type ='"&oRelationshipInstance.type.title&"' AND Relationship.hasComponent("&strLastInstanceQuery&")" 
	CONST_METHOD_TWO.setArgument1 "Query0", "Relationship.type ='"&oRelationshipInstance.type.title&"' AND Relationship.hasComponent("&strLastInstanceQuery&") AND Relationship.hasComponent("&strNextQuery&")"
	Call oCurrentModel.runMethodOnInst1(CONST_METHOD_TWO,oTargetContainer)

	'Call This method recursively
	For each oStartRel in oNextInstance.neighbourRelationships
	
		if oStartRel.target.uri = oNextInstance.uri AND oStartRel.origin.uri <> oLastInstance.uri Then 'Other end is origin
	           if oStartRel.origin.type.title <> "Container" then
			Call recursiveQueryGenerator(oStartRel.origin, oStartRel.target, strNextQuery, oStartRel, topContainer, topContainerView, checkInstanceName )
		   end if
		Elseif oStartRel.origin.uri = oNextInstance.uri AND oStartRel.target.uri <> oLastInstance.uri  Then
	           if oStartRel.target.type.title <> "Container" then
			Call recursiveQueryGenerator(oStartRel.target, oStartRel.origin, strNextQuery, oStartRel, topContainer, topContainerView, checkInstanceName )
		   end if
		End if	
	Next


End Sub





'-----------------------------------------------------------------------------------------------------
' Function getAdditionalQueryFromConfig
'
'This function tests if an object has comments and read additional TQL queries from the description
'-----------------------------------------------------------------------------------------------------

Function getAdditionalQueryFromConfig (oInstance)

	Dim oPart, strQuery
	strQuery = ""
	For each oPart in oInstance.parts
		If oPart.type.uri = CONST_STR_COMMENT_TYPE_URI Then
			strQuery = strQuery +  " and "&oPart.description
		End if
	Next
	getAdditionalQueryFromConfig = strQuery
End Function



'----------------------------------------------------------------
' Sub createViewRoutine
'
' This view routine is intended for Dashboards. It follows the following
' algorhitm. TODO Update
'
' 1) If oNewInstance has views in this modelview, then do nothing
' 2) If oNewInstanceView doesnt have a view in this modelView, then create it in the views of oTargetInstance IF the parent of oInstanceView
'
'----------------------------------------------------------------
Sub createViewRoutine ( oTargetInstance, oNewInstance)
	Dim oView, oModelView
	If oCurrentModel.currentModelView.findInstanceViews(oNewInstance).count = 0 Then ' If already in modelview do nothing
		if oNewInstance.parent is Nothing Then 'If it doesnt have a parent just create a view in the target container
			For each oView in oTargetInstance.views
				If Not oCurrentModel.currentModelView.findInstanceView(oView.uri) is Nothing Then
					Call oView.newObjectView(oNewInstance)
					oView.doLayout
				End if
			Next
		Elseif Not oNewInstance.parent.isContainer Then ' If it do have a parent and this parent aint no container, do recursive search make sure the parent have a view
			Call recursiveViewCreater (oTargetInstance, oNewInstance.parent) ' Makes sure that we create a view for the parent
				For each oView in oCurrentModel.currentModelView.findInstanceViews(oNewInstance.parent)
					Call oView.newObjectView(oNewInstance)
					oView.doLayout
				Next
		Else ' If the parent is a container, create a view in target container
			For each oView in oTargetInstance.views
				If Not oCurrentModel.currentModelView.findInstanceView(oView.uri) is Nothing Then
					Call oView.newObjectView(oNewInstance)
					oView.doLayout
				End if
			Next
		End if
	End if
End Sub

Sub recursiveViewCreater (oTargetInstance, oNewInstance)
	Dim oView
	If oCurrentModel.currentModelView.findInstanceViews(oNewInstance).count = 0 Then ' If the instance does not have a view in this modelview
		if Not oNewInstance.parent.isContainer Then  'If the parent is not a container
			Call recursiveViewCreater (oTargetInstance, oNewInstance.parent)
			For each oView in oNewInstance.parent.views
				If Not oCurrentModel.currentModelView.findInstanceView(oView.uri) is Nothing Then
					Call oView.newObjectView(oNewInstance)
					oView.doLayout
				End if
			Next
		Else
			For each oView in oTargetInstance.views
				If Not oCurrentModel.currentModelView.findInstanceView(oView.uri) is Nothing Then	
					Call oView.newObjectView(oNewInstance)
					oView.doLayout
				End if
			Next
		End if

	End if
End Sub

'----------------------------------------------------------------
' Function getSelectDialog
'
'This function returns a Metis Select Dialog
'
'----------------------------------------------------------------
        
Function getSelectDialog ( collection, titleString, headerString, singleSelect )
        Dim objListDialogBox
        Dim collContainersInModel
        
        Set collContainersInModel = collection
        Set objListDialogBox = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
        With objListDialogBox
                .title = titleString
                .heading = headerString
                .singleSelect = singleSelect
                .columnLabel = True
                .columnURI = False
                .columnType = False
		.viewTree = True
        End With
        objListDialogBox.addData collContainersInModel
        Set getSelectDialog = objListDialogBox.show   
End Function




'------------------------------------------------------------------------------------------------
' Sub overrideFromMetis
'
' Will check the calling actionButton to see if it has defined a parameter called the value of
' strParameterName and return that value if this is the case
'
'-------------------------------------------------------------------------------------------------
Sub overrideFromMetis(strParameterName, parameter)
	Dim oProperty
	Dim oPropvaluesCollection, oPropInstance
	Dim PARAM_STR_CONFIG_CONTAINER
	
	Set oPropvaluesCollection = oCurrentModel.currentInstance.getNamedValue("variables").getCollection

	For each oPropInstance in oPropvaluesCollection
		if oPropInstance.getValue(oPropInstance.type.getProperty("variableName")).getString = strParameterName Then
			parameter = oPropInstance.getValue(oPropInstance.type.getProperty("variableValue")).getString
			Exit Sub
		End if
	Next
End Sub


'------------------------------------------------------------------------------------------------
' Sub getRepositoryId
'
' Get the repository ID of an instance based on its URI
'-------------------------------------------------------------------------------------------------
Function  getRepositoryId (strInstanceURI)
	Dim shortId

	shortID = Right(strInstanceURI, Len(strInstanceURI)-(InStr (strInstanceURI, "#") +1 ))
	getRepositoryId = shortId	
End Function

'------------------------------------------------------------------------------------------------
' Function instanceIsOfType
'
' Checks if an instance is of type
'
'-------------------------------------------------------------------------------------------------
Public Function instanceIsOfType(oCandidateInstance, oTestType)

	instanceIsOfType = typeIsOfType(oCandidateInstance.type, oTestType)

End Function

'*************************************************************************************************
Public Function typeIsOfType(oCandidateInstance, oTestType)
Dim bolResult
	If oCandidateInstance.uri = oTestType.uri Then
		bolResult = True
	Else
		If oCandidateInstance.basetype Is Nothing Then
			bolResult = False
		Else
			bolResult = typeIsOfType(oCandidateInstance.basetype, oTestType)
		End If
	End If

typeIsOfType = bolResult
End Function

'*************************************************************************************************
