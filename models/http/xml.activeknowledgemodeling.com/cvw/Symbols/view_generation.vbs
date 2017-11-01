option explicit

'------------------------------------------------------------------------------------------------------------
' [0] Dim Variables
'------------------------------------------------------------------------------------------------------------
  	'-- Dim Section [1]
  	dim model, modelview
	dim object, objectView, InputString, InputArray

	'-- Dim Section [2]
	dim InputTopObjType, InputTopObjCriteria, InputRelObjType, InputRelType
	dim InputMainContainerType, InputMenuContainerType

  	'-- Dim Section [3]
  	dim cAnalysisContainer, cMainContainer, mainContainer
    dim analysisContainerType, mainContainerType

  	'-- Dim Section [4]
	dim topAggregationType
	dim buttonType, buttons

'------------------------------------------------------------------------------------------------------------
' [1] INPUT section
'------------------------------------------------------------------------------------------------------------
	'------------------------------------------------------------------------------------------------------------
	' [1a] Current Model and iInstances
	'------------------------------------------------------------------------------------------------------------
	  set model 			= metis.currentModel
  	  set modelView 		= model.currentModelView

 	  Set object  			= model.currentInstance
	  Set objectView 		= modelView.currentInstanceView

	'------------------------------------------------------------------------------------------------------------
	' [1b] Parsing Input Variables
	'------------------------------------------------------------------------------------------------------------
	  InputString 			= objectView.instance.description
	  InputArray			= Split(InputString, ";", -1, 1)

	'------------------------------------------------------------------------------------------------------------
	' [1c] Assign Input Variables
	'------------------------------------------------------------------------------------------------------------

 	  InputMainContainerType   = Split(InputArray(0), "=", -1, 1)(1)
 	  InputTopObjType	   	   = Split(InputArray(1), "=", -1, 1)(1)

	'------------------------------------------------------------------------------------------------------------
	' [1d] INPUT PARAMETERS - Example
	'------------------------------------------------------------------------------------------------------------
	 'InputMainContainerType   = http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workplace_UUID;
	 'InputTopObjType	       = http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID;

'------------------------------------------------------------------------------------------------------------
' [2] Set GLOBAL VARIABLES
'------------------------------------------------------------------------------------------------------------
	'----------------------------------------------------------------------------------------------------
	' [2a] Container types
	'----------------------------------------------------------------------------------------------------
	  Set mainContainerType = metis.findType(InputMainContainerType)

    '----------------------------------------------------------------------------------------------------
    ' [2b] Object types
    '----------------------------------------------------------------------------------------------------
	  '[A***]  <---
	  set topAggregationType = metis.findType(InputTopObjType)
	  set buttonType = metis.findType("metis:stdtypes#oid23")

'------------------------------------------------------------------------------------------------------------
' [3] ASSIGN Values
'------------------------------------------------------------------------------------------------------------
	'----------------------------------------------------------------------------------------------------
	' [3a] SET Workareas (Origin and Target view of Objects)
	'----------------------------------------------------------------------------------------------------

	'----------------------------------------------------------------------------------------------------
	' [3b] SET other Parameters
	'----------------------------------------------------------------------------------------------------

'------------------------------------------------------------------------------------------------------------
' [4] Main (A)
'------------------------------------------------------------------------------------------------------------

    if cMainContainer.count = 0 or cAnalysisContainer.count = 0 then
	    msgbox "Data not found"

    else


	'-----------------------------------------------------------------------------------------------------
	' [4A] Main(A) -- cancel any other container view
	'-----------------------------------------------------------------------------------------------------

        for each mContainer in cAnalysisContainer(1).parts
		    call model.deleteObject(mContainer)
	    next

	'-----------------------------------------------------------------------------------------------------
	' [4b] Main(A) -- store values of filter
	'-----------------------------------------------------------------------------------------------------

	  Set cLevel2Container = model.findInstances(menuContainerType, "description" ,"m4.1")
	  countLoop=0
	  for each filter in cLevel2Container(1).parts
		countLoop=countLoop+1
        if countLoop=2 THEN
            if StrComp(filter.type.name,"Filter") = 0 then
				'msgbox filter.name & filter.description
				call topCriteria.setArgument("name",filter.getNamedValue("name"))
				call topCriteria.setArgument("description",filter.getNamedValue("description"))

				call topInViewCriteria.setArgument("name",filter.getNamedValue("name"))
				call topInViewCriteria.setArgument("description",filter.getNamedValue("description"))

				filterName=filter.name
	  			FilterDescription=filter.description
			end if
		end if
	  next

	'-----------------------------------------------------------------------------------------------------
	' [4c] Main(A) -- create top container
	'-----------------------------------------------------------------------------------------------------
	  set topContainerObj = cAnalysisContainer(1).newPart(analysisInnerContType)
	  '[H**] <--
	  call topContainerObj.setNamedStringValue("name",InputLabelTopContainer)
	  set topContainer = cAnalysisContainer(1).Views(1).newObjectView(topContainerObj)

	'-----------------------------------------------------------------------------------------------------
	' [4d] Main(A) -- Do automatic layout on top container
	'-----------------------------------------------------------------------------------------------------
	  call metis.doLayout(cAnalysisContainer(1).views(1))

	'-----------------------------------------------------------------------------------------------------
	' [4e] Main(A) -- Find Root Top Tree
	'-----------------------------------------------------------------------------------------------------
	  set topAggregations = model.findInstances(topAggregationType,"","")
	  set topRoot=nothing
          for each topObj in topAggregations
	        if StrComp(topObj.parent.type.name,"Container_Level_4")=0 then set topBaseRoot = topObj
		if StrComp(topObj.name,FilterName)=0 OR StrComp(topObj.description,FilterDescription)=0  then set topRoot = topObj
	        'msgbox topObj.name &"--"& FilterName & StrComp(topObj.name,FilterName) &"++"& topObj.Description &"--"& FilterDescription & StrComp(topObj.Description,FilterDescription)
	  next
	  'msgbox topAggregations.count  &"--"& topBaseRoot.name
          if  topRoot is nothing or not HasFilterTop THEN set topRoot = topBaseRoot

	  'msgbox topRoot.name

	'-----------------------------------------------------------------------------------------------------
	' [4f] Main(A) -- Create All Top Tree View
	'-----------------------------------------------------------------------------------------------------
	  call createTreeView(topRoot,topContainer)

	'-----------------------------------------------------------------------------------------------------
	' [4h] Main(A) -- Purge filtered View
	'-----------------------------------------------------------------------------------------------------
	 
     call modelView.clearSelection

     set selection = metis.runCriteriaOnInstance(topCriteria,mainContainer)
	 set topInView = model.runCriteriaOnInstance(topInViewCriteria,topContainer.instance)
	 call modelView.select(topInView)
	 for each instView in metis.selection
		if not instanceInList(instView.instance,selection) then 
			call modelView.deleteObjectView(instView)
		    'msgbox instView.instance.name
		end if
	 next
	
	'-----------------------------------------------------------------------------------------------------
	' [4i] Main(A) -- call metis.doLayout(metis.selection)
	'-----------------------------------------------------------------------------------------------------

	call metis.doLayout(topContainer)
	cAnalysisContainer(1).views(1).children(1).absTextScale = 1.1
	call modelView.clearSelection


