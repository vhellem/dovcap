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
' This is a script that reads a configuration container. The configuration container should be populated with object types and relationships between them.
' Based on the types found in the configuration container, the scripts prompts the user for types to import and based on this selection the scripts queries the repository
' for these types. Based on the types returned, the script also prompts the user for importing relationships between these types
'
' GUIDE FOR CONFIGURING THIS SCRIPT

' Uses one parameter: 
' PARAM_STR_CONFIG_CONTAINER_OID The oid of the container which contains the configuration of the query.

'----------------------------------------------------------------
' Declare your parameters here
'----------------------------------------------------------------
Dim PARAM_STR_CONFIG_CONTAINER_OID
Dim  CONST_STR_METHOD_ONE_URI, CONST_STR_METHOD_TWO_URI, CONST_METHOD_ONE,CONST_METHOD_TWO, CONST_STR_CONTAINER_TYPE_URI, CONST_STR_COMMENT_TYPE_URI,CONST_MER_TYPE
Dim CONST_STR_GENERAL_OBJECT_URI, CONST_STR_GENERAL_REL_URI
Dim ME_QUERY_TYPE_URI

Dim CONST_O_INSTANCE_LIST

Dim oCurrentModel


'----------------------------------------------------------------
' Set your parameters default here
'----------------------------------------------------------------
PARAM_STR_CONFIG_CONTAINER_OID = ""


'----------------------------------------------------------------
'Constants and global variables 
'----------------------------------------------------------------

'Initialize global variables. metis is already set
ME_QUERY_TYPE_URI = "metis:troux#TrouxQuery"
Set oCurrentModel = metis.currentModel
CONST_STR_GENERAL_OBJECT_URI = "http://metadata.troux.info/meaf/objecttypes/general_object.kmd#CompType_MEAF:GeneralObject_UUID"
CONST_STR_GENERAL_REL_URI = "http://metadata.troux.info/meaf/relationshiptypes/general_relationship.kmd#Reltype_generic_component_general_relationship_generic_component_UUID"


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
Call overrideFromMetis("PARAM_STR_CONFIG_CONTAINER_OID",PARAM_STR_CONFIG_CONTAINER_OID)

Dim MEQuery, MEQueries, testString, queryMethod

'#################### PROGRESS BAR SETUP
Dim oMetisProgressBar
Set oMetisProgressBar = CreateObject("Metis.ProgressBar." & metis.versionMajor & "." & metis.versionMinor)
oMetisProgressBar.title = "Repository Query Progress Indicator"
oMetisProgressBar.interactive = True
oMetisProgressBar.logVisible = True
oMetisProgressBar.logExpanded = True


Call getConfig

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

Sub getConfig
	
	Dim oConfigContainer, oTargetContainer, selectedQueries, oQuery, strObjectQuery, oInstance, oInstanceFromRepositoryCollection
	Dim oDummyRelationshipType, oRelationshipQuery, oSelectedRelationshipTypesDummyInstanceCollection, oSelectedRelationship, oTargetContainerCollection, oTargetContainerCandidate
	Dim oRepositoryCandidateInstances, strRelQuery, oDummyParentContainer
	
	Set oConfigContainer = Nothing



	Set oConfigContainer = metis.findInstance(metis.currentModel.url&PARAM_STR_CONFIG_CONTAINER_OID)
	
	
	If oConfigContainer is Nothing or PARAM_STR_CONFIG_CONTAINER_OID = "" Then '
		Msgbox "Configuration not complete, each action button using this script has to specify a configuration container oid in the variables field with name PARAM_STR_CONFIG_CONTAINER_OID"
		oMetisProgressBar.interactive = False
		oMetisProgressBar.hide
		Exit Sub
	End if
	' Ok, I have the config container, no lets pop up a select dialog with all its repositoryCandidates'
	Set CONST_O_INSTANCE_LIST = metis.newInstanceList
	Call findRepositoryCandidatesRecursively (oConfigContainer)


	Set selectedQueries = getSelectDialog (CONST_O_INSTANCE_LIST,"Repository Query","Select Queries to Run", False, True, False )
	if selectedQueries.count < 1 Then
		oMetisProgressBar.interactive = False
		oMetisProgressBar.hide
		Exit Sub
	ENd if
	'#################### Calculate how Metis Progress Dialog should be shown ##############################	
	Dim intStepSize, intProgress
	
	intProgress = 0
	intStepSize = 100/ (selectedQueries.count + 1)
	oMetisProgressBar.show

	oMetisProgressBar.setProgressStatus "Performing Object Queries"
	For each oQuery in 	selectedQueries
		Set oTargetContainer = Nothing
		
		'################################ GETTING TARGET CONTAINER #############################################
		Set oDummyParentContainer = getParentContainer(oQuery)
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
		If oTargetContainer is Nothing Then
				Msgbox "Could not find target container for "& oQuery.type.title& ". Creating new container in current ModelView", vbCritical,"Could not find target container"
				Set oTargetContainer = oCurrentModel.newObject (metis.findType(CONST_STR_CONTAINER_TYPE_URI))
			    Call oTargetContainer.setNamedStringValue("name",oQuery.name)
				
				oCurrentModel.currentModelView.newObjectView(oTargetContainer)
		End if

		'############################## TRANSLATE VISUAL OBJECTS TO A QUERY STRING AND RUN #########################################################

		' Ok, I have an object, meaning I have the object type, meaning I can ask the server for each object of this type
		strObjectQuery = ""
		strObjectQuery = getQueryFromVisualization (oQuery)
		oMetisProgressBar.appendToLog "Performing Query for  "& oQuery.type.title & VbCrLf
		CONST_METHOD_ONE.setArgument1 "Query0", strObjectQuery
		CONST_METHOD_ONE.setArgument1 "AllowCreateViews", 0
		
		Set oInstanceFromRepositoryCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_ONE,oTargetContainer).getCollection
		oMetisProgressBar.appendToLog "Returned "& oInstanceFromRepositoryCollection.count&" instances" & VbCrLf &VbCrLf
		intProgress = intProgress+intStepSize
	 	oMetisProgressBar.setPercentDone intProgress
		
		For each oInstance in oInstanceFromRepositoryCollection
			Call createViewRoutine (oTargetContainer,oInstance)
		Next
	Next

	'############################ FINDING OUT WHAT RELATIONSHIPS THE USER CAN SELECT FROM #####################################################
	Set oRelationshipQuery = metis.newInstanceList
	For each oQuery in selectedQueries 
		For each oDummyRelationshipType in oQuery.neighbourRelationships		
			If (oDummyRelationshipType.origin.uri = oQuery.uri AND selectedQueries.contains(oDummyRelationshipType.target)  )	Then				
				oRelationshipQuery.addLast oDummyRelationshipType
			End if
		Next
	Next
	' ########################## BASED ON THE USER SELECTION OF RELS CONSTRUCT A QUERY FOR RELS TAKING INTO ACCOUNT THE OBJECT QUERIES ##############################
	If oRelationshipQuery.Count > 0 Then
		Set oSelectedRelationshipTypesDummyInstanceCollection = getSelectDialog (oRelationshipQuery,"Relationship Type","Select Relationship Types to import", False,False, True)
		
		if oSelectedRelationshipTypesDummyInstanceCollection.count > 0 Then
	
			For each oSelectedRelationship in oSelectedRelationshipTypesDummyInstanceCollection
				if oSelectedRelationship.type.uri = CONST_STR_GENERAL_REL_URI Then
					strRelQuery = "Relationship.type ='Generic Relationship' AND Relationship.hasComponent("& getQueryFromVisualization (oSelectedRelationship.target)&") AND Relationship.hasComponent("& getQueryFromVisualization (oSelectedRelationship.origin)&") OR " 	
				Else
					strRelQuery = strRelQuery &"Relationship.type ='"&oSelectedRelationship.type.title&"' AND Relationship.hasComponent("& getQueryFromVisualization (oSelectedRelationship.target)&") AND Relationship.hasComponent("&getQueryFromVisualization (oSelectedRelationship.origin)&") OR " 
				End if
			Next
			
			strRelQuery = Left(strRelQuery, Len(strRelQuery) - 4) 
			oMetisProgressBar.setProgressStatus "Performing Relationship Queries"
			oMetisProgressBar.appendToLog "Performing Query for Relationships" & VbCrLf
			CONST_METHOD_TWO.setArgument1 "Query0", strRelQuery 
			Set oInstanceFromRepositoryCollection = oCurrentModel.runMethodOnInst1(CONST_METHOD_TWO, oTargetContainer).getCollection
			oMetisProgressBar.appendToLog "Returned "& oInstanceFromRepositoryCollection.count&" relationships" & VbCrLf &VbCrLf
			intProgress = intProgress+intStepSize
	 	oMetisProgressBar.setPercentDone intProgress
		End if
	End if
	
	

End Sub

'-----------------------------------------------------------------------------------------------------
' Function getConfigFromVisualization
'
'This function tests if an object has comments and read additional TQL queries from the description
'-----------------------------------------------------------------------------------------------------

Function getQueryFromVisualization (oInstance)

	Dim oPart, strQuery
	strQuery = ""
	if oInstance.type.uri = CONST_STR_GENERAL_OBJECT_URI Then
		strQuery = "Component.type ='Generic Component' "
	Else
		strQuery = "Component.type ='"&oInstance.type.title&"'"	
	End if
	For each oPart in oInstance.parts
		If oPart.type.uri = CONST_STR_COMMENT_TYPE_URI Then
			strQuery = strQuery +  " AND "&oPart.description
		End if
	Next
	getQueryFromVisualization = strQuery
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
		Elseif oNewInstance.parent.type.uri <> CONST_STR_CONTAINER_TYPE_URI Then ' If it do have a parent and this parent aint no container, do recursive search make sure the parent have a view
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
	If oCurrentModel.currentModelView.findInstanceViews(oNewInstance).count = 0 Then ' If the parent does not have a view in this modelview
		if oNewInstance.parent.type.uri <> CONST_STR_CONTAINER_TYPE_URI Then  'If the parent of the parent is not a container
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
        
Function getSelectDialog ( collection, titleString, headerString, singleSelect, showLabel, showType )
        Dim objListDialogBox
        Dim collContainersInModel
        
        Set collContainersInModel = collection
        Set objListDialogBox = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
        With objListDialogBox
                .title = titleString
                .heading = headerString
                .singleSelect = singleSelect
                .columnLabel = showLabel
                .columnURI = False
                .columnType = showType
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
' Function makeURIAbsolute
'
'Creates an absoluteURI from a relativeURI and a reference
'
'-------------------------------------------------------------------------------------------------
Public Function makeURIAbsolute(strRelativeURI, oReferenceInstance)
'Makes the URI absolute with respect to the oReferenceInstance
Dim poundPosition
Dim strRelativeURL, strOID, strAbsoluteURL

	If ((Not IsNull(strRelativeURI) ) And  strRelativeURI <> "") Then 
		poundPosition = inStrRev(strRelativeURI, "#oid")
		If poundPosition > 0 Then
			strRelativeURL = Left(strRelativeURI, poundPosition-1)
			strOID = Right(strRelativeURI, len(strRelativeURI)-poundPosition+1)
		Else
			strRelativeURL = strRelativeURI
			strOID = ""
		End If
	End If
	
	strAbsoluteURL = metis.urlMakeAbsolute(strRelativeURL, oReferenceInstance)

makeURIAbsolute = strAbsoluteURL & strOID
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
