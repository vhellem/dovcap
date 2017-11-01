
option explicit

'------------------------------------------------------------------------------------------------------------
' [0] Dim Variable
'------------------------------------------------------------------------------------------------------------


	'-- Dim Section [1]
	dim p, found1
	dim InputTopObjType, InputTopObjCriteria, InputRelObjType, InputRelType
	dim InputLabelTopContainer, InputLabelTargetContainer, InputLabelOriginContainer, InputLabelRelContainer
	dim HasRelView, HasFilterTop, HasFilterRel

	dim object, objectView, InputString, InputArray

	dim cAnalysisContainer, analysisContainerType

	'-- Dim Section [4]	
	dim topContainer, rel, relType, allRels, selection, selectedInstanceViews


'------------------------------------------------------------------------------------------------------------
' [1] INPUT 
'------------------------------------------------------------------------------------------------------------
	'------------------------------------------------------------------------------------------------------------
	' [1a] Current Model and iInstances
	'------------------------------------------------------------------------------------------------------------  
	  set model 			= metis.currentModel
  	  set modelView 		= model.currentModelView
 
 	  Set object  			= model.currentInstance
	  Set objectView 		= modelView.currentInstanceView

	'------------------------------------------------------------------------------------------------------------
	' [1b] Parsing Input Variable
	'------------------------------------------------------------------------------------------------------------  
	  InputString 			= objectView.instance.description
	  InputArray			= Split(InputString, ";", -1, 1)

	'------------------------------------------------------------------------------------------------------------
	' [1c] Assign Input Variable
	'------------------------------------------------------------------------------------------------------------  
	
 	  InputTopObjType	   	= Split(InputArray(1), "=", -1, 1)(1)
	  InputTopObjCriteria 	   	= Split(InputArray(2), "=", -1, 1)(1)
	  InputRelObjType	   	= Split(InputArray(3), "=", -1, 1)(1)
	  InputRelType		   	= Split(InputArray(4), "=", -1, 1)(1)
	  InputLabelTargetContainer 	= Split(InputArray(5), "=", -1, 1)(1)
	  InputLabelOriginContainer 	= Split(InputArray(6), "=", -1, 1)(1)
	  InputLabelTopContainer    	= Split(InputArray(7), "=", -1, 1)(1) 
	  InputLabelRelContainer	= Split(InputArray(8), "=", -1, 1)(1)
	
	'------------------------------------------------------------------------------------------------------------
	' [1e] INPUT PARAMETERS - Example
	'------------------------------------------------------------------------------------------------------------
	 'InputTopObjType	   	= "http://xml.troux.it/itppm/object_types/aggregazione_costi.kmd#oid1"
	 'InputTopObjCriteria 	   	= "http://xml.troux.it/itppm/criteria/itppm_criteria.kmd#oid76"
	 'InputRelObjType	   	= "http://xml.metis.no/xml/object_types/attribute.kmd#oid1"
	 'InputRelType		   	= "metis:stdtypes#oid114"
	 'InputLabelTargetContainer 	= "Gestione Climatizzazione"
	 'InputLabelOriginContainer 	= "Modello Virtual Car"
	 'InputLabelTopContainer    	= "Albero Requisiti Climatizzazione" 
	 'InputLabelRelContainer 	= "Grandezze Fisiche"
	



'------------------------------------------------------------------------------------------------------------
' [2] Set GLOBAL VARIABLES
'------------------------------------------------------------------------------------------------------------
	
      set analysisContainerType = metis.findType(InputTopObjType)


'------------------------------------------------------------------------------------------------------------
' [3] ASSIGN Values
'------------------------------------------------------------------------------------------------------------
	'----------------------------------------------------------------------------------------------------
	' [3a] SET Working Container (Origin and Target view of Objects) 
	'----------------------------------------------------------------------------------------------------
   	  Set cAnalysisContainer = model.findInstances(analysisContainerType, "name" ,InputLabelTargetContainer)


'------------------------------------------------------------------------------------------------------------
' [4] Main (A)
'------------------------------------------------------------------------------------------------------------


	for each p in cAnalysisContainer(1).parts 
		if StrComp(p.getNamedStringValue("name"),InputLabelTopContainer)=0 then 
			set topContainer = p.views(1)
			found1 = true
		end if
	next
	if not found1 then 
		msgbox "Errore"
	else
		'find objects
		Set relType = metis.findType(InputTopObjType)

		set allRels = model.findInstances(relType,"","")
		set selection = metis.newInstanceViewList
		'find relationships views
		for each rel in allRels
			set selectedInstanceViews = modelView.findInstanceViews(rel)
			if selectedInstanceViews.count > 0 then call selection.AddLast(selectedInstanceViews(1))
		next
		set modelView.selection = selection
		if selection.count > 0 then call metis.runCommand("sel-object-property-list")

	end if

'----------------------------------------------------------------------

