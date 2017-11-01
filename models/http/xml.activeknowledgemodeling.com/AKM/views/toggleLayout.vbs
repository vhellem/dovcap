option explicit

'------------------------------------------------------------------------------------------------------------
' [0] Dim Variable
'------------------------------------------------------------------------------------------------------------


dim model, object, modelView
dim analysisContainerType, cAnalysisContainer 
dim mainCont
dim verticalLayout, horizontalLayout, currentLayout
dim InputTopObjType, InputRelObjType
dim InputVerticalLayout, InputHorizontalLayout
dim InputTreeVerticalLayout, InputTreeHorizontalLayout

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

 	  InputTopObjType	   	= Split(InputArray(0), "=", -1, 1)(1)
 	  InputRelObjType	   	= Split(InputArray(1), "=", -1, 1)(1)
	  InputVerticalLayout 	   	= Split(InputArray(2), "=", -1, 1)(1)
	  InputHorizontalLayout	   	= Split(InputArray(3), "=", -1, 1)(1)
	  InputTreeVerticalLayout 	= Split(InputArray(4), "=", -1, 1)(1)
	  InputTreeHorizontalLayout	= Split(InputArray(5), "=", -1, 1)(1)



	'------------------------------------------------------------------------------------------------------------
	' [1e] INPUT PARAMETERS - Example
	'------------------------------------------------------------------------------------------------------------
	 '
	'InputTopObjType=http://xml.troux.it/itppm/object_types/aggregazione_costi.kmd#oid1;
	'InputRelObjType=http://xml.troux.it/itppm/object_types/aggregazione_fondi.kmd#oid1;
	'InputVerticalLayout=http://xml.troux.it/itppm/layout_strategies/management windows vertical.kmd#oid1;
	'InputHorizontalLayout=http://xml.troux.it/itppm/layout_strategies/matrix layout for management windows.kmd#oid1;
	'InputTreeVerticalLayout=http://xml.computas.com/xml/interfaces/common/layouts/attribute.kmd#oid8;
	'InputTreeHorizontalLayout=http://xml.troux.it/itppm/layout_strategies/layout finanziamenti itppm.kmd#oid=1;

'------------------------------------------------------------------------------------------------------------
' [2] Set GLOBAL VARIABLES
'------------------------------------------------------------------------------------------------------------



'------------------------------------------------------------------------------------------------------------
' [3] ASSIGN Values
'------------------------------------------------------------------------------------------------------------

set analysisContainerType = metis.findType(InputTopObjType)
set mainCont = modelView.children(1).instance




'------------------------------------------------------------------------------------------------------------
' [4] Main (A)
'------------------------------------------------------------------------------------------------------------




if StrComp(mainCont.type.name,"Container") = 0 then
	for each cAnalysisContainer in mainCont.parts
		if StrComp(cAnalysisContainer.type.name,InputTopObjTypeName) = 0 then
			set verticalLayout = metis.findLayoutStrategy(InputVerticalLayout)
			set horizontalLayout = metis.findLayoutStrategy(InputHorizontalLayout)

			set currentLayout = cAnalysisContainer.views(1).layoutStrategy 

			if StrComp(currentLayout.URI,verticalLayout.URI) = 0 then 			
				set cAnalysisContainer.views(1).layoutStrategy = horizontalLayout
				if cAnalysisContainer.views(1).children(1).children.count > 0 THEN
					set cAnalysisContainer.views(1).children(1).children(1).layoutStrategy = metis.findLayoutStrategy(InputTreeHorizontalLayout) 
				end if						
			else
				set cAnalysisContainer.views(1).layoutStrategy = verticalLayout
				if cAnalysisContainer.views(1).children(1).children.count > 0 THEN
					set cAnalysisContainer.views(1).children(1).children(1).layoutStrategy = metis.findLayoutStrategy(InputTreeVerticalLayout) 
				end if
			end if

			call metis.doLayout(cAnalysisContainer.views(1))
		end if
	next
end if
