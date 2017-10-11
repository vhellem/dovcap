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
' Date: October, 2005
' Author:  Joachim Lund
'
' Copyright (C) 2005 Troux Technologies . All rights reserved.
'
'
' GUIDE FOR USING THIS SCRIPT
'
' This script tackles visual modelling of a TQL query traversing paths. It is similar to a path search criteria. Objects and relationships represents different parts of the query. 
'
' This scripts purpose is to do path traversal between different queries to the repository. It reads a configuration container. The config container should be populated with objects
' representing queries. An object of a particular type symbolizes a query for all objects of that type. You can also add additional TQL by adding comments to the object  
'
' As a start the script needs to have one relationship from the config container to an object. This object is the startQuery and will populate a select dialog of instances matching this query
' If this object is connected to other objects of different types, queries will be executed to get the results of these queries as well.
' EXAMPLE: A config container can be a container with two containers within it, In these two containers are an "Application" and an "Application Function". 
' They are connected via a "Provides" relationship. The config container has a general relationship to the Application object
'
'  When this config container is referenced from an action button, the user will be prompted to select from all Applications in the Repository. He can select multiple, and from the ones he select
' the script will ask the repository for Application Functions that are connected via a "Provides" relationship
' 
' Each query(object representing a query) needs to have a destination container. The script will try to find a container in the current model view that matches with the name of the parent container
' of the query. IF that cannot be found, it will create a container and give it the name of the query itself OR the object type (for the object representing the query)
' It is also possible to use UUIDs instead of name on the parent containers (in case the name is not unique) A UUID is the last part of the URI and can look like this #dasdadsa123
'
'
' Model View behaviour: The script work in context of the current ModelView. If instances exist in the model, this script WILL CREATE new views.See the Sub CreateViewRoutine for detailed
' behaviour
'
' GUIDE FOR CONFIGURING THIS SCRIPT

' Uses one parameter: 
' PARAM_STR_CONFIG_CONTAINER_OID The oid of the container which contains the configuration of the query.
' 
'----------------------------------------------------------------
' Declare your parameters here
'----------------------------------------------------------------
Dim PARAM_STR_CONFIG_CONTAINER_OID, PARAM_STR_HIGH_LEVEL_CONTAINER_OID, PARAM_STR_CHECK_EXISTING_CONTAINER_OID
Dim CONST_STR_METHOD_ONE_URI, CONST_STR_METHOD_TWO_URI, CONST_METHOD_ONE,CONST_METHOD_TWO, CONST_STR_CONTAINER_TYPE_URI, CONST_STR_COMMENT_TYPE_URI, CONST_MER_TYPE
Dim CONST_STR_GENERAL_OBJECT_URI, CONST_STR_GENERAL_REL_URI
Dim CONST_O_INSTANCE_LIST
Dim oCurrentModel
Dim oHighLevelContainer
Dim ME_QUERY_TYPE_URI

'----------------------------------------------------------------
' Set your parameters default here
'----------------------------------------------------------------
PARAM_STR_CONFIG_CONTAINER_OID = ""
PARAM_STR_CHECK_EXISTING_CONTAINER_OID = ""


'----------------------------------------------------------------
'Constants and global variables 
'----------------------------------------------------------------
Dim checkInstanceContainerParts

'Initialize global variables. metis is already set
Set oCurrentModel = metis.currentModel
Set checkInstanceContainerParts = metis.newInstanceList()

ME_QUERY_TYPE_URI = "metis:troux#TrouxQuery"
CONST_STR_METHOD_ONE_URI = "http://metadata.troux.info/serviceutilities/tqlmodeler/methods/extra_tql_methods.kmd#QueryUsingParameters_from_script"
CONST_STR_METHOD_TWO_URI = "http://metadata.troux.info/serviceutilities/tqlmodeler/methods/extra_tql_methods.kmd#RelationshipOnlyQuery"
CONST_STR_CONTAINER_TYPE_URI = "metis:stdtypes#oid3"
CONST_STR_COMMENT_TYPE_URI = "metis:stdtypes#oid22"
CONST_STR_GENERAL_OBJECT_URI = "http://metadata.troux.info/meaf/objecttypes/general_object.kmd#CompType_MEAF:GeneralObject_UUID"
CONST_STR_GENERAL_REL_URI = "http://metadata.troux.info/meaf/relationshiptypes/general_relationship.kmd#Reltype_generic_component_general_relationship_generic_component_UUID"

Set CONST_METHOD_ONE = metis.findMethod(CONST_STR_METHOD_ONE_URI)
Set CONST_METHOD_TWO = metis.findMethod(CONST_STR_METHOD_TWO_URI)
Set CONST_MER_TYPE = metis.findType("metis:mer#MerObjectProp")
CONST_METHOD_TWO.setArgument1 "EnsureRelationshipEndObjects", 0

'----------------------------------------------------------------
' Enable users to override from Metis here
'----------------------------------------------------------------
Call overrideFromMetis("PARAM_STR_CONFIG_CONTAINER_OID",PARAM_STR_CONFIG_CONTAINER_OID)
Call overrideFromMetis("PARAM_STR_HIGH_LEVEL_CONTAINER_OID",PARAM_STR_HIGH_LEVEL_CONTAINER_OID)
Call overrideFromMetis("PARAM_STR_CHECK_EXISTING_CONTAINER_OID",PARAM_STR_CHECK_EXISTING_CONTAINER_OID)

'#################### PROGRESS BAR SETUP
Dim oMetisProgressBar, INT_STATUS_PROGRESS, CONST_STATUS_STEP_SIZE
Dim MEQueries, testString, queryMethod, MeQuery

Set oMetisProgressBar = CreateObject("Metis.ProgressBar." & metis.versionMajor & "." & metis.versionMinor)
oMetisProgressBar.title = "Repository Query Progress Indicator"
oMetisProgressBar.interactive = True
oMetisProgressBar.logVisible = True
oMetisProgressBar.logExpanded = False
Call getConfigAndInitialCollection
oMetisProgressBar.setPercentDone 100	

Set MEQueries = oCurrentModel.findInstances(metis.findType(ME_QUERY_TYPE_URI),"","")
testString = 0
for each MEQuery in MEQueries
   queryMethod = MEQuery.getNamedStringValue("queryMethod")
   testString = inStr(queryMethod,"tqlmodeler") 
   if testString > 0 then
     oCurrentModel.deleteObject(MEQuery)
   end if
next

Sub getConfigAndInitialCollection
	Dim oConfigContainer, oObjectToQuery, oStartQuery, oPossibleContainerChild, oResultFromRepository, oSelectedObjectCollection, strQueryZero
	Dim oSelectedQuery ,oStartRel, oInstance, oView, oTargetContainer, oTargetContainerCollection,oTargetContainerCandidate, oPartCandidate, bolExtraQuery, strNextQuery
	Dim oDummyParentContainer, tempContainer, selectedObject
	Dim checkInstanceContainer, existingInstance, returnedInstance, checkInstanceResults

Set checkInstanceResults = metis.newInstanceList()
	
	'#################### PROGRESS BAR
	Dim objMetisProgressDialog
	Set objMetisProgressDialog = CreateObject("Metis.ProgressBar." & metis.versionMajor & "." & metis.versionMinor)
	objMetisProgressDialog.title = "Repository Query Progress Indicator"
	objMetisProgressDialog.interactive = False
	objMetisProgressDialog.logVisible = True
	objMetisProgressDialog.logExpanded = True



	'############## GET CONFIG CONTAINER #################################
	Set oConfigContainer = Nothing
	Set oConfigContainer = metis.findInstance(metis.currentModel.url&PARAM_STR_CONFIG_CONTAINER_OID)
	If oConfigContainer is Nothing or PARAM_STR_CONFIG_CONTAINER_OID = "" Then '
		Msgbox "Configuration not complete, each action button using this script has to specify a configuration container oid in the variables field with name PARAM_STR_CONFIG_CONTAINER_OID"
		oMetisProgressBar.interActive = False
		oMetisProgressBar.hide
		Exit Sub
	End if

	'###### POOR ATTEMPT TO CALCULATE WORK EFFORT
	INT_STATUS_PROGRESS = 0
	Set CONST_O_INSTANCE_LIST = metis.newInstanceList 
	Call findRepositoryCandidatesRecursively (oConfigContainer)
	CONST_STATUS_STEP_SIZE = 100 / (CONST_O_INSTANCE_LIST.count * 2) 'This will update CONST_O_INSTANCE_LIST
	oMetisProgressBar.setPercentDone INT_STATUS_PROGRESS
	oMetisProgressBar.setProgressStatus "Performing Intitial Query"

	' ################### GET START QUERY AND TARGET CONTAINER ##############################

	Set oStartQuery = Nothing
	If oConfigContainer.neighbourObjects.Count <> 1  Then
		Msgbox "Configuration not complete, each Config Container should have one and only one start object. Create a general relationship from the config to the start object", vbError,"Model misconfiguration"	
		oMetisProgressBar.interActive = False
		oMetisProgressBar.hide
		Exit Sub
	End if

	Set oStartQuery = oConfigContainer.neighbourObjects.Item(1)
	
	Set oTargetContainer = Nothing
	Set oDummyParentContainer = getParentContainer(oStartQuery	)
	' Users are allowed to input the UUID of the destination container in the parent container
 	Set oTargetContainer =  metis.findInstance(metis.currentModel.url&oDummyParentContainer.name)  

	If oTargetContainer is Nothing then 
		'Will then try to find a container that matches the name of the parent of the dummyType
		Set oTargetContainerCollection = metis.currentModel.findInstances(metis.findType(CONST_STR_CONTAINER_TYPE_URI),"name",oDummyParentContainer.name)  'Try finding a container based on the name of the container the type instance is in
		'If there is a container called the same as the type in this modelview, then use this container as target
		On Error Resume Next
		For each oTargetContainerCandidate in oTargetContainerCollection 
			if oCurrentModel.currentModelView.findInstanceViews(oTargetContainerCandidate).count > 0 Then
				Set oTargetContainer = oTargetContainerCandidate
				Exit For
			End if
		Next
		On Error Goto 0
	End if

	'DB Update - Users are allowed to specify where to build a dynamic set of containers
	if oTargetContainer is Nothing Then
	   Set oHighLevelContainer = Nothing
	   Set oHighLevelContainer = metis.findInstance(metis.currentModel.url&PARAM_STR_HIGH_LEVEL_CONTAINER_OID)
	   if oHighLevelContainer is Nothing then
	   else
              Set oTargetContainer = oHighLevelContainer.newPart(metis.findType(CONST_STR_CONTAINER_TYPE_URI))
	      Call oTargetContainer.setNamedStringValue("name",oDummyParentContainer.name)
              oHighLevelContainer.views.Item(1).newObjectView(oTargetContainer)
	   End if
	End if

	If oTargetContainer is Nothing Then
			Msgbox "Could not find target container for "& oStartQuery.type.title& ". Creating new container in current ModelView", vbCritical,"Could not find target container"
			Set oTargetContainer = oCurrentModel.currentInstance.views.Item(1).parent.instance.newPart(metis.findType(CONST_STR_CONTAINER_TYPE_URI))'oCurrentModel.newObject (metis.findType(CONST_STR_CONTAINER_TYPE_URI))
			if oStartQuery.name <> "" Then
		    	Call oTargetContainer.setNamedStringValue("name",oStartQuery.name)
			Else
				Call oTargetContainer.setNamedStringValue("name",oStartQuery.type.title)
			End if
			oCurrentModel.currentInstance.views.Item(1).parent.newObjectView(oTargetContainer)
	End if


  '#################### TRANSFORM THE VISUALIZATION TO A QUERY STRING AND RUN IT #########################################
	strQueryZero = ""
	strQueryZero = getQueryFromVisualization (oStartQuery)	
	CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
	CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0 
	oMetisProgressBar.show
	oMetisProgressBar.appendToLog "Performing Query for  "& oStartQuery.type.title&"..."  & VbCrLf	
        if PARAM_STR_CHECK_EXISTING_CONTAINER_OID = "" then
	else
          Set checkInstanceContainer =  metis.findInstance(metis.currentModel.url&PARAM_STR_CHECK_EXISTING_CONTAINER_OID)  
          'Set checkInstanceContainerParts = checkInstanceContainer.parts
	  'Set checkInstanceContainerParts = Nothing
	  discoverInstancesInContainerStructure checkInstanceContainer
        end if
	Set oResultFromRepository = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer)
	oMetisProgressBar.appendToLog "Returned "& oResultFromRepository.getCollection.count&" instances" & VbCrLf	& VbCrLf
	INT_STATUS_PROGRESS = INT_STATUS_PROGRESS+CONST_STATUS_STEP_SIZE
	oMetisProgressBar.setPercentDone INT_STATUS_PROGRESS

	'Add check for existing here'
        if PARAM_STR_CHECK_EXISTING_CONTAINER_OID = "" then
	else
	    if checkInstanceContainerParts.count > 0 then
	      for each returnedInstance in oResultFromRepository.getCollection
	         for each existingInstance in checkInstanceContainerParts
	             if existingInstance.uri = returnedInstance.uri then
	                Call checkInstanceResults.AddLast(returnedInstance)
	             end if
	         next
	      next
            end if
	    Set checkInstanceContainerParts = Nothing
	end if

	'End Add check for existing here'

        if PARAM_STR_CHECK_EXISTING_CONTAINER_OID = "" then
            Set oSelectedObjectCollection = getSelectDialog (oResultFromRepository.getCollection, "Repository Query", "Select Objects", False)
        else
            Set oSelectedObjectCollection = getSelectDialog (checkInstanceResults, "Repository Query", "Select Objects", False)
        end if

	If oSelectedObjectCollection.count < 1 Then
          MsgBox "Nothing was selected"
		oMetisProgressBar.interactive = False
		oMetisProgressBar.hide
	        'Deleting the ones that we originally got back and didnt choose (if they dont have views) 
	        For each oInstance in oResultFromRepository.getCollection
	    	   If oInstance.views.count = 0 Then
			oCurrentModel.deleteObject(oInstance)
		   End if
	        Next
                Exit Sub
	End If	

	' Add information about structures to the query string
	strQueryZero = ""
	For each oSelectedQuery in oSelectedObjectCollection
		strQueryZero = strQueryZero &"Component.id = '" &  getRepositoryId(oSelectedQuery.uri) &"' OR " 'This query is the TQL represenation of the Result from the Select Dialog
	Next
	strQueryZero = Left (strQueryZero, Len(strQueryZero) - 4) 
	bolExtraQuery = false
	For each oPartCandidate in oStartQuery.parts
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE)AND oPartCandidate.neighbourObjects.count = 0  Then ' Users might model comments
			 strQueryZero = strQueryZero&" OR (Component.hasAncestor("&strQueryZero&"))"
			 bolExtraQuery = true
			 Exit For
		End if
	Next
	If Not oStartQuery.parent.isContainer Then 
		 strQueryZero = strQueryZero&" OR (Component.hasDescendant("&strQueryZero&"))"
		 bolExtraQuery = true
	End if
	' Run a new query asking for the objects from the select dialog (unncessesary) but also objects that are descendants and/or ancestors of these objects
	if bolExtraQuery Then
		CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
		CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0 
		Set oSelectedObjectCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer).getCollection
		INT_STATUS_PROGRESS = INT_STATUS_PROGRESS+CONST_STATUS_STEP_SIZE
		oMetisProgressBar.setPercentDone INT_STATUS_PROGRESS

	End if

	'Building the query that indentifies the results from the last query to send to the neighbor and also create views
	strNextQuery =""
	For each oInstance in oSelectedObjectCollection
		 	Call createViewRoutine (oTargetContainer,oInstance)
		 strNextQuery = strNextQuery &"Component.id = '" &  getRepositoryId(oInstance.uri) &"' OR "
	Next
	strNextQuery = Left(strNextQuery, Len(strNextQuery) - 4) 
	
	'Deleting the ones that we originally got back and didnt choose (if they dont have views) 
	For each oInstance in oResultFromRepository.getCollection
		If oInstance.views.count = 0 Then
			oCurrentModel.deleteObject(oInstance)
		End if
	Next


	'############################# SEND THE RELAY PIN TO NEIGHBORS AND/OR PARENT AND/OR CHILDREN
	
	For each oStartRel in oStartQuery.neighbourRelationships	
		if oStartRel.target.uri = oStartQuery.uri  AND instanceIsOfType(oStartRel.origin,CONST_MER_TYPE)  Then 'Other end is origin
			Call recursiveQueryGenerator(oStartRel.origin, oStartRel.target, strNextQuery, oStartRel.type.uri, oStartRel.type.title)
		Elseif oStartRel.origin.uri = oStartQuery.uri  AND instanceIsOfType(oStartRel.target,CONST_MER_TYPE) Then
			Call recursiveQueryGenerator(oStartRel.target,oStartRel.origin, strNextQuery, oStartRel.type.uri, oStartRel.type.title)	
		End if	
	Next
	'Sending to Parts
	For each oPartCandidate in oStartQuery.parts
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE) AND oPartCandidate.neighbourObjects.count > 0 Then ' If users models parts with relationships we want to follow that path
			 	Call recursiveQueryGenerator(oPartCandidate, oStartQuery, strNextQuery, "WASPARENT", "" )
		End if
	Next
	if instanceIsOfType(oStartQuery.parent,CONST_MER_TYPE) AND oStartQuery.parent.neighbourObjects.count > 0 Then ' If users models parts with relationships we want to follow that path
			 	Call recursiveQueryGenerator(oStartQuery.parent, oStartQuery, strNextQuery, "WASCHILD", "" )
	End if
	
	
End sub















Sub recursiveQueryGenerator (oNextQuery, oLastQuery, strLastInstanceQuery, strRelationshipInstanceURI, strRelationshipInstanceTitle)
	Dim oTargetContainer,oTargetContainerCandidate,oTargetContainerCollection, oInstanceFromRepositoryCollection, strNextQuery, oInstance, oStartRel, oPartCandidate
	Dim strQueryZero, strQueryZeroPartOne, strQueryZeroPartTwo, oDummyParentContainer
	strNextQuery = ""


	
	'######################## GETTING TARGET CONTAINER FOR THIS QUERY ######################################
	Set oDummyParentContainer = getParentContainer(oNextQuery)
	' Users are allowed to input the UUID of the destination container in the parent container
        Set oTargetContainer =  metis.findInstance(metis.currentModel.url&oDummyParentContainer.name)  

	If oTargetContainer is Nothing Then
		'Will then try to find a container that matches the name of the parent of the dummyType
		Set oTargetContainerCollection = metis.currentModel.findInstances(metis.findType(CONST_STR_CONTAINER_TYPE_URI),"name",oDummyParentContainer.name)  'Try finding a container based on the name of the container the type instance is in
		'If there is a container called the same as the type in this modelview, then use this container as target
		On Error Resume Next
		For each oTargetContainerCandidate in oTargetContainerCollection 
			if oCurrentModel.currentModelView.findInstanceViews(oTargetContainerCandidate).count > 0 Then
				Set oTargetContainer = oTargetContainerCandidate
				Exit For
			End if
		Next
		On Error Goto 0
	End if
	
	'DB Update - Users are allowed to specify where to build a dynamic set of containers
	if oTargetContainer is Nothing Then
	   Set oHighLevelContainer = Nothing
	   Set oHighLevelContainer = metis.findInstance(metis.currentModel.url&PARAM_STR_HIGH_LEVEL_CONTAINER_OID)
	   if oHighLevelContainer is Nothing then
	   else
              Set oTargetContainer = oHighLevelContainer.newPart(metis.findType(CONST_STR_CONTAINER_TYPE_URI))
	      Call oTargetContainer.setNamedStringValue("name",oDummyParentContainer.name)
              oHighLevelContainer.views.Item(1).newObjectView(oTargetContainer)
	   End if
	End if

	If oTargetContainer is Nothing Then
			Msgbox "Could not find target container for "& oNextQuery.type.title& ". Creating new container in current ModelView", vbCritical,"Could not find target container"
			Set oTargetContainer = oCurrentModel.currentInstance.views.Item(1).parent.instance.newPart(metis.findType(CONST_STR_CONTAINER_TYPE_URI))'oCurrentModel.newObject (metis.findType(CONST_STR_CONTAINER_TYPE_URI))
		    if oNextQuery.name <> "" Then
		    	Call oTargetContainer.setNamedStringValue("name",oNextQuery.name)
			Else
				Call oTargetContainer.setNamedStringValue("name",oNextQuery.type.title)
			End if
			oCurrentModel.currentInstance.views.Item(1).parent.newObjectView(oTargetContainer)
	End if

 '#################### TRANSFORM THE VISUALIZATION TO A QUERY STRING AND RUN IT #########################################

	strQueryZeroPartOne = ""
	strQueryZeroPartOne = "("&getQueryFromVisualization (oNextQuery)

	' Based on the way we came to this query (From parent, child or neighbor) adding some extra stuff
	if strRelationshipInstanceURI = "WASPARENT" Then
		strQueryZeroPartTwo = " AND Component.hasParent("&strLastInstanceQuery&")) "
	Elseif 	 strRelationshipInstanceURI = "WASCHILD" Then
		strQueryZeroPartTwo = " AND Component.hasDescendant("&strLastInstanceQuery&")) " 
	Elseif strRelationshipInstanceURI = CONST_STR_GENERAL_REL_URI Then
			strQueryZeroPartTwo = " AND Component.hasRelationship(Relationship.type ='Generic Relationship' AND Relationship.hasComponent("&strLastInstanceQuery&"))) " 
	Else
			strQueryZeroPartTwo = " AND Component.hasRelationship(Relationship.type ='"&strRelationshipInstanceTitle&"' AND Relationship.hasComponent("&strLastInstanceQuery&"))) " 	
	End if
	strQueryZero = ""
	strQueryZero = strQueryZeroPartOne&strQueryZeroPartTwo

	' If user has modelled a part or a parent to this object, then ancestor and/or descendants are also part of the query
	For each oPartCandidate in oNextQuery.parts
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE) AND oPartCandidate.neighbourObjects.count = 0  Then ' Users might model comments
			 strQueryZero = strQueryZero&" OR (Component.hasAncestor("&strQueryZero&"))"
			 Exit For
		End if
	Next
	If Not oNextQuery.parent.isContainer AND oNextQuery.parent.uri <> oLastQuery.uri  Then  
		 strQueryZero = strQueryZero&" OR (Component.hasDescendant("&strQueryZero&"))"
	End if



	'Execute the query to get the result
	'########### UPDATING STATUS BAR
	oMetisProgressBar.setProgressStatus "Performing Object Queries"
	oMetisProgressBar.appendToLog "Performing Query for  "& oNextQuery.type.title &"..." & VbCrLf 
	'
	CONST_METHOD_ONE.setArgument1 "Query0", strQueryZero
	Set oInstanceFromRepositoryCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer).getCollection
	oMetisProgressBar.appendToLog "Returned "& oInstanceFromRepositoryCollection.count&" instances" & VbCrLf &VbCrLf
	INT_STATUS_PROGRESS = INT_STATUS_PROGRESS+CONST_STATUS_STEP_SIZE
	oMetisProgressBar.setPercentDone INT_STATUS_PROGRESS
	If oInstanceFromRepositoryCollection.count = 0 Then
		Exit Sub
	End if



	'###################### Building the query that indentifies the results from the last query to send to the neighbor and also create views##########################

	For each oInstance in oInstanceFromRepositoryCollection
		Call createViewRoutine (oTargetContainer,oInstance)
		 strNextQuery = strNextQuery &"Component.id = '" &  getRepositoryId(oInstance.uri) &"' OR "
	Next
	strNextQuery = Left(strNextQuery, Len(strNextQuery) - 4) 
	
	' ########################## QUERYING FOR THE RELATIONSHIPS (ONLY IF WE DID NOT COME FROM PARENT OR CHILD) ########################################
	if strRelationshipInstanceURI <> "WASPARENT" AND strRelationshipInstanceURI <> "WASCHILD"  Then
		strQueryZero = ""
		if strRelationshipInstanceURI = CONST_STR_GENERAL_REL_URI Then
			strQueryZero = "Relationship.type ='Generic Relationship' AND Relationship.hasComponent("&strLastInstanceQuery&") AND Relationship.hasComponent("&strNextQuery&")" 	
		Else
			strQueryZero = "Relationship.type ='"&strRelationshipInstanceTitle&"' AND Relationship.hasComponent("&strLastInstanceQuery&") AND Relationship.hasComponent("&strNextQuery&")" 	
		End if
		oMetisProgressBar.setProgressStatus "Performing Relationship Queries"
		oMetisProgressBar.appendToLog "Performing Query for Relationship:  " &strRelationshipInstanceTitle&"..."& VbCrLf
		CONST_METHOD_TWO.setArgument1 "Query0", strQueryZero
		INT_STATUS_PROGRESS = INT_STATUS_PROGRESS+CONST_STATUS_STEP_SIZE
		oMetisProgressBar.setPercentDone INT_STATUS_PROGRESS
		Set oInstanceFromRepositoryCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_TWO,oTargetContainer).getCollection
		oMetisProgressBar.appendToLog "Returned "& oInstanceFromRepositoryCollection.count&" relationships" & VbCrLf & VbCrLf	

	End if


'	############################# SEND THE RELAY PIN TO NEIGHBORS AND/OR PARENT AND/OR CHILDREN RECURSIVELY
	For each oStartRel in oNextQuery.neighbourRelationships
	
		if oStartRel.target.uri = oNextQuery.uri AND oStartRel.origin.uri <> oLastQuery.uri AND instanceIsOfType(oStartRel.origin,CONST_MER_TYPE)  Then 'Other end is origin
			Call recursiveQueryGenerator(oStartRel.origin, oStartRel.target, strNextQuery, oStartRel.type.uri, oStartRel.type.title )
		Elseif oStartRel.origin.uri = oNextQuery.uri AND oStartRel.target.uri <> oLastQuery.uri  AND instanceIsOfType(oStartRel.target,CONST_MER_TYPE)  Then
			Call recursiveQueryGenerator(oStartRel.target, oStartRel.origin, strNextQuery, oStartRel.type.uri ,oStartRel.type.title )
		End if	
	Next
	For each oPartCandidate in oNextQuery.parts 
		if instanceIsOfType(oPartCandidate,CONST_MER_TYPE) AND oPartCandidate.neighbourObjects.count > 0 AND oPartCandidate.uri <> oLastQuery.uri Then ' If users models parts with relationships we want to follow that path
			 	Call recursiveQueryGenerator(oPartCandidate, oNextQuery, strNextQuery, "WASPARENT", "" )
		End if
	Next
	if oLastQuery.uri <> oNextQuery.parent.uri AND instanceIsOfType(oNextQuery.parent,CONST_MER_TYPE) AND oNextQuery.parent.neighbourObjects.count > 0 Then ' If users models parts with relationships we want to follow that path
			 	Call recursiveQueryGenerator(oNextQuery.parent, oNextQuery, strNextQuery, "WASCHILD", "" )
	End if
	

End Sub

'-----------------------------------------------------------------------------------------------------
' Function getQueryFromVisualization
'
'This function tests if an object has comments and read additional TQL queries from the description
'-----------------------------------------------------------------------------------------------------

Function getQueryFromVisualization (oInstance)

	Dim oPart, strQuery, strInputValue
	strQuery = ""
	
	if oInstance.type.uri = CONST_STR_GENERAL_OBJECT_URI Then
		strQuery = "Component.type ='Generic Component' "
	Else
		strQuery = "Component.type ='"&oInstance.type.title&"'"	
	End if
	For each oPart in oInstance.parts
		If oPart.type.uri = CONST_STR_COMMENT_TYPE_URI Then
			if Left(oPart.description,1) = "?" Then ' If users put in e.g ?name in the description field it means that they want to be prompted for objects called something like this
				strInputValue = transformWildcardToTQL( Mid(oPart.description,2),InputBox ("Type in the "&Mid(oPart.description,2)&" of the "&oInstance.type.title))
				strQuery = strQuery +  " AND "&strInputValue
			Else 
				strQuery = strQuery +  " AND "&oPart.description
			End if
		End if
	Next
'	Msgbox strQuery
	getQueryFromVisualization = strQuery
End Function


'-----------------------------------------------------------------------------------------------------
' Function transformWildcardToTQL
'
'This function tests if an object has comments and read additional TQL queries from the description
'-----------------------------------------------------------------------------------------------------

Function transformWildcardToTQL (strPropertyName,strPropertyValue)
Dim strQueryZero, strQueryOne 

if strPropertyValue = "*" Then
 strQueryZero = " contains ''"
elseif Left(strPropertyValue,1) = "*" AND Right(strPropertyValue,1) = "*"  Then
		strPropertyValue = Mid(strPropertyValue,2,Len(strPropertyValue)-2)
		strQueryZero = " contains '"&strPropertyValue&"'"
elseif Left(strPropertyValue,1) = "*"  Then
	strPropertyValue = Mid(strPropertyValue,2)
	strQueryZero = " endsWith '"&strPropertyValue&"'"

elseif Right(strPropertyValue,1) = "*"  Then
		strPropertyValue = Mid(strPropertyValue,1,Len(strPrpertyValue)-1)
		strQueryZero = " startsWith '"&strPropertyValue&"'"
else
		strQueryZero = " = '"&strPropertyValue&"'"
End if

if strPropertyName = "name" Then
	strQueryOne ="Component.name "&strQueryZero
Else
	strQueryOne = "component.property("""&strPropertyName&""",string,"&strQueryZero&")" 'Doesnt work yet
End if
transformWildcardToTQL = strQueryOne
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


'----------------------------------------------------------------
' Function getParentContainer
'
'Will return the (grand)parent container of an object 
'
'----------------------------------------------------------------
        
Function getParentContainer ( oObject )
Dim oParentContainer

If (oObject.parent.isContainer) Then
	Set oParentContainer = oObject.parent
Else
	Set oParentContainer = getParentContainer (oObject.parent)
End if
Set getParentContainer = oParentContainer
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

'------------------------------------------------------------------------------------------------
' Sub findRepositoryCandidatesRecursively
'
' Finds repository objects recursively in an object structure
'
'-------------------------------------------------------------------------------------------------
Sub findRepositoryCandidatesRecursively  (oStartInstance)
	Dim oRepositoryCandidate, oMerType
	Set oMerType =  CONST_MER_TYPE
	
	For each oRepositoryCandidate in oStartInstance.parts
		if instanceIsOfType(oRepositoryCandidate, CONST_MER_TYPE) Then
			CONST_O_INSTANCE_LIST.addLast oRepositoryCandidate
			if oRepositoryCandidate.name = "" Then
				oRepositoryCandidate.name = oRepositoryCandidate.type.title
			End if
			Call findRepositoryCandidatesRecursively  (oRepositoryCandidate)
		Elseif oRepositoryCandidate.isContainer Then
			Call findRepositoryCandidatesRecursively  (oRepositoryCandidate)
		End if
	Next
End Sub

Sub discoverInstancesInContainerStructure(checkContainer)
    Dim checkContainerParts, instanceFound
    set checkContainerParts = checkContainer.parts
    for each instanceFound in checkContainerParts
         Call checkInstanceContainerParts.AddLast(instanceFound)
         discoverInstancesInContainerStructure(instanceFound)
    next
End Sub
