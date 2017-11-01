'------------------------------------------------------------------------------------------------------------
'ClearWorkArea
'    Input: ParentContainerType        (= RightPane type)
'    Input: WorkAreaType               (= WorkArea type)
'
'    Output: None
'
'CreateWorkArea
'    Input: ParentContainerType        (= RightPane type)
'    Input: WorkAreaType               (= WorkArea type)
'    Input: WorkAreaName               (= WorkArea name)
'
'    Output: WorkArea
'
'GetInstances
'    Input: DataSourceKind             (= MCT|MER)
'    Input: ModelObject                (= Space (EKA) object)
'    Input: Criteria                   (= findObjectStructure)
'        Argument:   StartObject
'    Input: Filter
'        Argument:   Name
'       Argument:   Description
'
'   Output: Instances
'
'PopulateWorkArea
'    Input: WorkArea
'    Input: Instances
'    Input: ViewStrategy
'    Input: LayoutStrategy

'------------------------------------------------------------------------------------------------------------

option explicit
'-- Public Section
public model, modelObj, modelview, contentModel, contentModels
public workplaceType, leftPaneType, rightPaneType, workareaType, contextType, actionType, valueType, baseRelType
public workplaceView, leftpaneView, rightpaneView, leftpane, rightpane
public ruleEngineProperty, ruleCodeProperty, RuleEvaluatedToProperty, ruleMethod
public pi

dim viewStrategyType, useStrategyType
dim modelType, pType, metamodelMethod

'-- Dim Section [1]
dim menu, action, actions, instList, menuView
dim instView, view, views
dim InputString, InputArray, InputKind, InputMetamodelMethod, InputDClickMethod
dim InputWorkplaceType, InputLeftpaneType, InputRightpaneType, InputWorkareaType
dim InputModelType, InputContextType, InputActionType, InputBaseRelshipType
dim InputValueType, InputViewStrategyType, InputUseStrategyType
dim InputRuleMethod, InputCcViewstyle, InputNeighbourViewstyle
dim InputConfigure
dim method, apply_rule, test

'------------------------------------------------------------------------------------------------------------
' [1] INPUT section
'------------------------------------------------------------------------------------------------------------

pi = 3.1415926535897932

'stop

'----------------------------------------------------------------------------------------------------
' [1a] Current Model and Instances
'----------------------------------------------------------------------------------------------------
set model 			= metis.currentModel
set modelView 		= model.currentModelView

set menu  		    = model.currentInstance
set menuView        = modelView.currentInstanceView

'------------------------------------------------------------------------------------------------------------
' [1b] Setting global values
'------------------------------------------------------------------------------------------------------------
InputWorkplaceType    = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workplace_UUID"
InputLeftpaneType     = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Leftpane_UUID"
InputRightpaneType    = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Rightpane_UUID"
InputWorkareaType     = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"
InputViewStrategyType = "http://xml.activeknowledgemodeling.com/akm/languages/view_strategy.kmd#ObjType_AKM:ViewStrategy_UUID"
InputUseStrategyType  = "http://xml.activeknowledgemodeling.com/akm/languages/view_relships.kmd#UiReltype_AKM:useViewStrategy_UUID"
InputBaseRelshipType  = "http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Relationship_UUID"    ' Abstract reltype used as base type
InputActionType       = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:MenuAction_UUID"
InputContextType      = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:ViewContext_UUID"
InputValueType        = "http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:Value_UUID"
InputRuleMethod       = "http://xml.chalmers.se/methods/rule_methods.kmd#evaluateRule"
InputCcViewstyle      = "http://xml.chalmers.se/viewstyles/cc_viewstyle.kmd#CC_Viewstyle"
InputNeighbourViewstyle = "http://xml.chalmers.se/viewstyles/cc_viewstyle.kmd#CC_Neighbours_Viewstyle"

RuleEngineProperty = "ruleEngine"
RuleCodeProperty = "ruleCode"
RuleEvaluatedToProperty = "ruleEvaluatedTo"

'------------------------------------------------------------------------------------------------------------

'------------------------------------------------------------------------------------------------------------
' [1c] Parsing Input Variable
'------------------------------------------------------------------------------------------------------------
InputString 	 	  = menu.description     ' From action button
InputArray			  = Split(InputString, ";", -1, 1)
InputKind             = Split(InputArray(0), "=", -1, 1)(1)
InputModelType        = Split(InputArray(1), "=", -1, 1)(1)
InputDClickMethod     = Split(InputArray(2), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(3), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(4), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(5), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(6), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(7), "=", -1, 1)(1)
InputMetamodelMethod  = Split(InputArray(8), "=", -1, 1)(1)
InputConfigure        = Split(InputArray(9), "=", -1, 1)(1)

if InputConfigure = true then 
    apply_rule = true
else
    apply_rule = false
end if

'stop

if InputModelType = "Nothing" then
    InputModelType    = "http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID"
end if
set workplaceType     = metis.findType(InputWorkplaceType)
set leftPaneType      = metis.findType(InputLeftpaneType)
set rightPaneType     = metis.findType(InputRightpaneType)
set workareaType      = metis.findType(InputWorkareaType)
set viewStrategyType  = metis.findType(InputViewStrategyType)
set useStrategyType   = metis.findType(InputUseStrategyType)
set modelType         = metis.findType(InputModelType)
set valueType         = metis.findType(InputValueType)
set contextType       = metis.findType(InputContextType)
set baseRelType       = metis.findType(InputBaseRelshipType)
set actionType        = metis.findType(InputActionType)

' Set doubleclick action
set method = metis.findMethod(InputDClickMethod)
if isEnabled(method) then
    model.runMethod(method)
end if

' Set rule engine method
set ruleMethod = metis.findMethod(InputRuleMethod)

set modelObj = findModelObject(modelType, model)
set contentModels = getContentModels

if Len(InputMetamodelMethod) = 0 then
    InputMetamodelMethod = "Nothing"
end if
if not InputMetamodelMethod = "Nothing" then
    set metamodelMethod = metis.findMethod(InputMetamodelMethod)
end if

'stop
set views = modelView.children
for each view in views
    if view.hasInstance then
        if view.instance.type.uri = workplaceType.uri then
            set workplaceView = view
            exit for
        end if
    end if
next

if isEnabled(workplaceView) then
    set views = workplaceView.children
    for each view in views
        if view.instance.type.uri = leftpaneType.uri then
            set leftpaneView = view
            set leftpane = leftpaneView.instance
        elseif view.instance.type.uri = rightpaneType.uri then
            set rightpaneView = view
            set rightpane = rightpaneView.instance
        end if
    next
end if

'------------------------------------------------------------------------------------------------------------
' [4] Action!!
'------------------------------------------------------------------------------------------------------------

'stop

set instList = metis.newInstanceList
select case InputKind
case "ObjectAction"
    call removeWorkArea(model, rightpaneType, workareaType)
    modelView.setViewStyle InputCcViewstyle
    call executeObjectAction(modelView, model, menu, instList, apply_rule)

case "RelshipAction"
    'call removeWorkArea(model, rightpaneType, workareaType)
    call executeRelshipAction(modelView, model, menu, apply_rule)

case "SelectObjectAction"
    call removeWorkArea(model, rightpaneType, workareaType)
    modelView.setViewStyle InputCcViewstyle
    call executeSelectObjectAction(modelView, model, menu, apply_rule)

case "ShowSelected"
    if modelView.selection.count > 0 then
        set instView = modelView.primarySelection
        if isEnabled(instView) then
            call removeWorkArea(model, rightpaneType, workareaType)
            modelView.setViewStyle InputNeighbourViewstyle
            call showSelectedAction(model, rightpaneType, workareaType, menu, instView, apply_rule)
        end if
    end if

case "Structure"
    modelView.setViewStyle InputCcViewstyle
    call removeWorkArea(model, rightpaneType, workareaType)
    set actions = menu.neighbourObjects
    for each action in actions
        if isEnabled(action) then
            if action.type.uri = actionType.uri then
                call executeObjectAction(modelView, model, action, instList, apply_rule)
            end if
        end if
    next
    for each action in actions
        if isEnabled(action) then
            if action.type.uri = actionType.uri then
                call executeRelshipAction(modelView, model, action, apply_rule)
            end if
        end if
    next
    if isEnabled(metamodelMethod) then
        model.runMethodByUri(metamodelMethod.uri)
    end if

case "AppendStructure"
    modelView.setViewStyle InputCcViewstyle
    set actions = menu.neighbourObjects
    for each action in actions
        if isEnabled(action) then
            if action.type.uri = actionType.uri then
                call executeObjectAction(modelView, model, action, instList, apply_rule)
            end if
        end if
    next
    for each action in actions
        if isEnabled(action) then
            if action.type.uri = actionType.uri then
                call executeRelshipAction(modelView, model, action, apply_rule)
            end if
        end if
    next
    if isEnabled(metamodelMethod) then
        model.runMethodByUri(metamodelMethod.uri)
    end if
end select

'------------------------------------------------------------------------------------------------------------
'   End of script
'------------------------------------------------------------------------------------------------------------

sub executeAction(modelView, model, menu, instList)

    dim InputString, InputArray, InputKind

    '------------------------------------------------------------------------------------------------------------
    ' [1b] Parsing Input Variable
    '------------------------------------------------------------------------------------------------------------
    InputString 		= menu.description     ' From menu object
    InputArray			= Split(InputString, ";", -1, 1)
    InputKind           = Split(InputArray(0), "=", -1, 1)(1)

'stop
    if InputKind = "ObjectAction" then
        call executeObjectAction(modelView, model, menu, instList)
    elseif InputKind = "RelshipAction" then
        call executeRelshipAction(modelView, model, menu)
    end if

end sub

'------------------------------------------------------------------------------------------------------------
' SUB EXECUTERELSHIPACTION
'------------------------------------------------------------------------------------------------------------
sub executeRelshipAction(modelView, model, object, apply_rule)

'------------------------------------------------------------------------------------------------------------
' [0] Dim Variables
'------------------------------------------------------------------------------------------------------------
	'-- Dim Section [1]
	dim InputString, InputArray, InputKind
    dim InputRelshipType
    dim InputCriteria

	'-- Dim Section [1]
    dim relshipType, relship, relships, relshipView
    dim origin, originView, originViews
    dim target, targetView, targetViews
    dim parts, mObj, model1
    dim test, done

	'------------------------------------------------------------------------------------------------------------
	' [1b] Input values
	'------------------------------------------------------------------------------------------------------------

    InputCriteria = ""

    'Debug
'stop
	'------------------------------------------------------------------------------------------------------------
	' [1c] Parsing Input Variable
	'------------------------------------------------------------------------------------------------------------
	InputString 		= object.description     ' From action button
	InputArray			= Split(InputString, ";", -1, 1)

	'------------------------------------------------------------------------------------------------------------
	' [1d] Assign Input Variable
	'------------------------------------------------------------------------------------------------------------

    InputKind = Split(InputArray(0), "=", -1, 1)(1)
    if not InputKind = "RelshipAction" then
        exit sub
    end if

    InputModelType     = Split(InputArray(1), "=", -1, 1)(1)
    InputDClickMethod  = Split(InputArray(2), "=", -1, 1)(1)
 	InputRelshipType   = Split(InputArray(3), "=", -1, 1)(1)
	InputCriteria 	   = Split(InputArray(4), "=", -1, 1)(1)

	set relshipType = metis.findType(InputRelshipType)



'------------------------------------------------------------------------------------------------------------
' [4] MAIN section
'------------------------------------------------------------------------------------------------------------

'stop
    for each mObj in contentModels
        test = mObj.name
        set model1 = mObj.ownerModel
        if not model1 is Nothing then
            set relships = model1.relationships
            for each relship in relships
                done = false
                if isEnabled(relshipType) then
                    if relship.type.inherits(relshipType) then
                        set origin = relship.origin
                        set originViews = modelView.findInstanceViews(origin)
                        set target = relship.target
                        set targetViews = modelView.findInstanceViews(target)
                        for each originView in originViews
                            for each targetView in targetViews
                                set relshipView = modelView.newRelationshipView(relship, originView, targetView)
                                done = true
                                exit for
                            next
                            if done then exit for
                        next
                    end if
                end if
            next
        end if
    next

end sub

'------------------------------------------------------------------------------------------------------------
' Sub executeSelectObjectAction
'------------------------------------------------------------------------------------------------------------
sub executeSelectObjectAction(modelView, model, object, apply_rule)

    dim InputString, InputArray, InputKind
    dim InputDialogTitle, InputDialogHeading, InputSingleSelect, InputTopObjType, InputTopObjRelType, InputCriteria, InputModelType
    dim singleSelect, topObjectType, topObjectRelType, relType, typeUri
    dim criteria, typeParameter
    dim inst, instances, instList, name
    dim action, actions
    dim rel, rels, isTop
  	dim viewStrategy, viewStrategies
    dim partOfRules, rule
    dim ifDialog1, selection1, dialogSel1
    dim test, cnt

	'------------------------------------------------------------------------------------------------------------
	' [1c] Parsing Input Variable
	'------------------------------------------------------------------------------------------------------------
'stop
	InputString 		 = object.description     ' From action button
	InputArray			 = Split(InputString, ";", -1, 1)

    InputKind            = Split(InputArray(0), "=", -1, 1)(1)
    if not InputKind = "SelectObjectAction" then
        exit sub
    end if

    InputModelType        = Split(InputArray(1), "=", -1, 1)(1)
    InputDClickMethod     = Split(InputArray(2), "=", -1, 1)(1)
	InputDialogTitle 	  = Split(InputArray(3), "=", -1, 1)(1)
 	InputDialogHeading 	  = Split(InputArray(4), "=", -1, 1)(1)
 	InputSingleSelect 	  = Split(InputArray(5), "=", -1, 1)(1)
 	InputTopObjType	   	  = Split(InputArray(6), "=", -1, 1)(1)
 	InputTopObjRelType    = Split(InputArray(7), "=", -1, 1)(1)
    InputCriteria         = Split(InputArray(8), "=", -1, 1)(1)

    '----------------------------------------------------------------------------------------------------
    ' [2a] Dialog parameters
    '----------------------------------------------------------------------------------------------------
    if LCase(InputSingleSelect) = "true" then
        singleSelect = true
    else
        singleSelect = false
    end if

    '----------------------------------------------------------------------------------------------------
    ' [2b] Object type
    '----------------------------------------------------------------------------------------------------
    if InputTopObjType = "Nothing" then
        set topObjectType = Nothing
    else
	   set topObjectType  = metis.findType(InputTopObjType)
	end if
    if InputTopObjRelType = "Nothing" then
        set topObjectRelType = Nothing
    else
	   set topObjectRelType  = metis.findType(InputTopObjRelType)
	end if

    '----------------------------------------------------------------------------------------------------
    ' [2c] Criteria
    '----------------------------------------------------------------------------------------------------
    if StrComp(InputCriteria, "Nothing") = 0 then
        set criteria = Nothing
    else
        on error resume next
        set criteria = metis.findCriteria(InputCriteria)
        if isEnabled(criteria) then
            set typeParameter = metis.newValue
            call typeParameter.setPointer(topObjectType)
            call criteria.setArgument("type",typeParameter)
        end if
    end if
    '----------------------------------------------------------------------------------------------------
    ' [2d] View strategy
    '----------------------------------------------------------------------------------------------------
    set viewStrategies = object.getNeighbourObjects(0, useStrategyType, viewStrategyType)
    if viewStrategies.count > 0 then
        set viewStrategy = viewStrategies(1)
    else
        set viewStrategy = Nothing
    end if

    '----------------------------------------------------------------------------------------------------
    ' [4a] Main action
    '----------------------------------------------------------------------------------------------------
'stop
    if isEnabled(criteria) then
        set instances = metis.runCriteria(criteria)
    else
        set instances = metis.newInstanceList
    end if
    if instances.count = 0 and isEnabled(topObjectType) then
        set instList = metis.newInstanceList
        set instances = modelObj.parts
        cnt = 0
        for each inst in instances
            cnt = cnt + 1
            if isEnabled(inst) then
                if topObjectType.uri = inst.type.uri then
                    test = inst.name
                    set rels = inst.neighbourRelationships
                    isTop = false
                    for each rel in rels
                        if isEnabled(topObjectRelType) then
                            if rel.type.inherits(topObjectRelType) then
                                if rel.target.uri = inst.uri then
                                    isTop = true
                                end if
                            end if
                        end if
                    next
                    if not isTop and not isEnabled(topObjectRelType) then
                        isTop = true
                        for each rel in rels
                            if rel.type.inherits(baseRelType) then
                                if rel.target.uri = inst.uri then
                                    isTop = false
                                end if
                            end if
                        next
                    end if
                    if isTop then
                        instList.addLast inst
                    end if
                end if
            end if
        next
        set instances = instList
    end if
    if instances.count > 0 then
		Set ifDialog1 = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
		With ifDialog1
				.title = InputDialogTitle
				.heading = InputDialogHeading
				.singleSelect = singleSelect
				.columnLabel = True
				.columnURI = False
				.columnType = False
		End With
'stop
		ifDialog1.addData instances
		Set dialogSel1 = ifDialog1.show
		if dialogSel1.count > 0 then
            set actions = object.neighbourObjects
            for each action in actions
                if isEnabled(action) then
                    if action.type.uri = actionType.uri then
                        call executeObjectAction(modelView, model, action, dialogSel1, apply_rule)
                    end if
                end if
            next
            for each action in actions
                if isEnabled(action) then
                    if action.type.uri = actionType.uri then
                        call executeRelshipAction(modelView, model, action, apply_rule)
                    end if
                end if
            next
        end if
    end if
end sub

'------------------------------------------------------------------------------------------------------------
' SUB EXECUTEOBJECTACTION
'------------------------------------------------------------------------------------------------------------
sub executeObjectAction(modelView, model, object, selection, apply_rule)

'------------------------------------------------------------------------------------------------------------
' [0] Dim Variables
'------------------------------------------------------------------------------------------------------------
	'-- Dim Section [1]
	dim InputString, InputArray, InputKind, InputWorkareaTitle
    dim InputTopObjType, InputTopObjRelType, InputTopObject, InputMetamodelMethod, InputModelType
    dim InputCriteria, InputFilter, InputViewStrategy, InputLayoutStrategyWorkarea, InputLayoutStrategyTopObject

  	'-- Dim Section [2]
    dim criteria, filter
  	dim viewStrategy, viewStrategies, lMatrixStrategy, lHierarchyStrategy
  	dim partOfRules, metamodelMethod

  	'-- Dim Section [3]
  	dim cWorkplace, cLeftpane, cRightpane, cWorkarea
  	dim workplaceViews, cWorkplaceView, cLeftpaneView, cRightpaneView, cWorkareaView
  	dim modelType, topObjectType, topObjectRelType, topObject, isTop
  	dim selected, instances, inst, instList, rel, rels, obj, objects

  	'-- Dim Section [4]
	dim buttonType, buttons
	dim views, view, instview
	dim pType, typeParameter
	dim test

'------------------------------------------------------------------------------------------------------------
' [1] INPUT section
'------------------------------------------------------------------------------------------------------------

	'----------------------------------------------------------------------------------------------------
	' [1a] Current Model and Instances
	'----------------------------------------------------------------------------------------------------
	'------------------------------------------------------------------------------------------------------------
	' [1b] Input values
	'------------------------------------------------------------------------------------------------------------
    'InputModelType     = "metis:stdtypes#oid3"

    InputCriteria = ""

    'Debug
'stop
	'------------------------------------------------------------------------------------------------------------
	' [1c] Parsing Input Variable
	'------------------------------------------------------------------------------------------------------------
	InputString 		 = object.description     ' From action button
	InputArray			 = Split(InputString, ";", -1, 1)

	'------------------------------------------------------------------------------------------------------------
	' [1d] Assign Input Variable
	'------------------------------------------------------------------------------------------------------------
'stop
    InputKind            = Split(InputArray(0), "=", -1, 1)(1)
    if not InputKind = "ObjectAction" then
        exit sub
    end if
    InputModelType       = Split(InputArray(1), "=", -1, 1)(1)
    InputDClickMethod    = Split(InputArray(2), "=", -1, 1)(1)

 	InputWorkareaTitle 	 = Split(InputArray(3), "=", -1, 1)(1)
 	InputTopObjType	   	 = Split(InputArray(4), "=", -1, 1)(1)
 	InputTopObjRelType   = Split(InputArray(5), "=", -1, 1)(1)
 	InputTopObject	   	 = Split(InputArray(6), "=", -1, 1)(1)
	InputCriteria 	   	 = Split(InputArray(7), "=", -1, 1)(1)
	InputMetamodelMethod = Split(InputArray(8), "=", -1, 1)(1)

'------------------------------------------------------------------------------------------------------------
' [2] Set GLOBAL VARIABLES
'------------------------------------------------------------------------------------------------------------
	'----------------------------------------------------------------------------------------------------
	' [2a] Method
	'----------------------------------------------------------------------------------------------------
'stop
    if Len(InputMetamodelMethod) = 0 then
        InputMetamodelMethod = "Nothing"
    end if
    if not InputMetamodelMethod = "Nothing" then
        set metamodelMethod = metis.findMethod(InputMetamodelMethod)
    end if

    '----------------------------------------------------------------------------------------------------
    ' [2b] Object type
    '----------------------------------------------------------------------------------------------------
    if not InputModelType = "Nothing" then
        set modelType = metis.findType(InputModelType)
    end if
    if InputTopObjType = "Nothing" then
        set topObjectType = Nothing
    else
	   set topObjectType  = metis.findType(InputTopObjType)
	end if
    if InputTopObjRelType = "Nothing" then
        set topObjectRelType = Nothing
    else
	   set topObjectRelType  = metis.findType(InputTopObjRelType)
	end if

    '----------------------------------------------------------------------------------------------------
    ' [2c] Criteria, filter, layout strategies, ...
    '----------------------------------------------------------------------------------------------------
    'Criteria
    if StrComp(InputCriteria, "Nothing") = 0 then
        set criteria = Nothing
    else
        set criteria = metis.findCriteria(InputCriteria)
        if isEnabled(criteria) then
            on error resume next
            set typeParameter = metis.newValue
            call typeParameter.setPointer(topObjectType)
            call criteria.setArgument("type",typeParameter)
        end if
    end if
    ' Filter
    set filter             = Nothing
    'Layout strategies
    set lMatrixStrategy    = Nothing
    set lHierarchyStrategy = Nothing
'stop
    set viewStrategies = object.getNeighbourObjects(0, useStrategyType, viewStrategyType)
    if viewStrategies.count > 0 then
        set viewStrategy = viewStrategies(1)
    else
        set viewStrategy = Nothing
    end if

    '----------------------------------------------------------------------------------------------------
    ' [2d] Instances
    '----------------------------------------------------------------------------------------------------
    set instList = metis.newInstanceList
    'call clearList(instList)

    ' Top object
    if InputTopObject = "Nothing" then
        set topObject = Nothing
    elseif InputTopObject = "Selected" then
        ' Get selected
        set selected = metis.selection
        for each instview in selected
            if instview.hasInstance then
                set inst = instview.instance
                instList.addLast inst
            end if
        next
        InputTopObject = "Nothing"
        set topObject = Nothing
    elseif InputTopObject = "InputSelection" then
        set instList = selection
    end if
    if not InputTopObject = "Nothing" then
        ' Find instance based on type and name
        set topObject = findTopObject(modelObj, topObjectType, viewStrategy, InputTopObject)
    end if

'------------------------------------------------------------------------------------------------------------
' [3] ASSIGN Values
'------------------------------------------------------------------------------------------------------------

'------------------------------------------------------------------------------------------------------------
' [4] MAIN section
'------------------------------------------------------------------------------------------------------------

    ' Input parameters:
    '                   Rightpane type
    '                   Workarea type
    '                   Workarea name
    '                   Top object
    '                   Criteria
    '                   Filter
    '                   View strategy
    '                   Workarea layout strategy
    '                   Top object layout strategy
    '
    ' Procedure:
    '                   Delete work area (if it exists)
    '                   Find instances based on criteria
    '                   Create work area
    '                   If any instances
    '                       Populate work area
    '                   End if
    ' Done


    set cWorkareaView = createWorkArea(model, rightpaneType, workareaType, InputWorkareaTitle)
    set instances = Nothing
'stop
    if isEnabled(criteria) then
        set instances = getMCTinstances(topObject, criteria, filter)
    elseif isEnabled(topObjectType) and not isEnabled(topObject) and not InputTopObject = "InputSelection" then
        set instances = modelObj.parts
        for each inst in instances
            if isEnabled(inst) then
                if topObjectType.uri = inst.type.uri then
                    test = inst.name
                    set rels = inst.neighbourRelationships
                    isTop = false
                    for each rel in rels
                        if isEnabled(topObjectRelType) then
                            if rel.type.inherits(topObjectRelType) then
                                if rel.target.uri = inst.uri then
                                    isTop = true
                                end if
                            end if
                        end if
                    next
                    if not isTop and not isEnabled(topObjectRelType) then
                        isTop = true
                        for each rel in rels
                            if rel.type.inherits(baseRelType) then
                                if rel.target.uri = inst.uri then
                                    isTop = false
                                end if
                            end if
                        next
                    end if
                    if isTop then
                        instList.addLast inst
                    end if
                end if
            end if
        next
        set instances = Nothing
    end if

    if isEnabled(cWorkareaView) then
        if instList.count > 0 then
            set instances = instList
        end if
        call populateWorkArea(cWorkareaView, topObject, instances, modelType, viewStrategy, lMatrixStrategy, lHierarchyStrategy, apply_rule)
        set instList = Nothing
    end if
    if isEnabled(rightpaneView) then
        call metis.doLayout(rightpaneView)
    end if
    ' Set metamodel
    if isEnabled(metamodelMethod) then
        model.runMethodByUri(metamodelMethod.uri)
    end if

end sub

'------------------------------------------------------------------------------------------------------------
' SUB SHOWSELECTEDACTION
'------------------------------------------------------------------------------------------------------------
sub showSelectedAction(model, rightpaneType, workareaType, object, instView, apply_rule)

    dim InputString, InputArray, InputKind
    dim InputModelType, InputWorkareaTitle, InputMode
    dim inst, obj, objects
    dim objView, workareas, workarea, workareaView
    dim relship, relships, relView
    dim origin, originView, originViews
    dim target, targetView, targetViews
    dim instViewList, iv, view, views
    dim mObj, model1
    dim contextObject, value
    dim contGeo, objGeo, pnt1, size1, ts, sf
    dim w, h, x0, y0, radius, distance_ratio
    dim no_levels, done

	'------------------------------------------------------------------------------------------------------------
	' [1c] Parsing Input Variable
	'------------------------------------------------------------------------------------------------------------
'stop
	InputString 		 = object.description     ' From action button
	InputArray			 = Split(InputString, ";", -1, 1)

    InputKind            = Split(InputArray(0), "=", -1, 1)(1)
    if not InputKind = "ShowSelected" then
        exit sub
    end if

    InputModelType       = Split(InputArray(1), "=", -1, 1)(1)
    InputDClickMethod    = Split(InputArray(2), "=", -1, 1)(1)
 	InputWorkareaTitle 	 = Split(InputArray(3), "=", -1, 1)(1)
 	InputMode 	         = Split(InputArray(4), "=", -1, 1)(1)

    ' Create workarea view
    set workareaView = createWorkArea(model, rightpaneType, workareaType, InputWorkareaTitle)
    if isEnabled(rightpaneView) then
        call metis.doLayout(rightpaneView)
    end if
    ' Create object view
    if instView.hasInstance then
        set inst = instView.instance
        set objView = workareaView.newObjectView(inst)
        'objView.textScale = 0.5
    else
        set objView = Nothing
    end if
    if InputMode = "AddNeighbours" and isEnabled(objView) then
        ' Circular layout
        set contextObject = getContextObject(contextType)
        no_levels = 2
        if isEnabled(contextObject) then
            set value = contextObject.getNamedValue("neighbourLevels")
            no_levels = value.getInteger
            if no_levels = 0 then no_levels = 1
        end if

        ' Calculate size and position of center object
        set contGeo = workareaView.geometry
        set objGeo = objView.geometry
        h =  contGeo.height/12 * no_levels
        objView.scale(objGeo.height / h)
        ts = objView.textScale * 1.5
        objView.textScale = ts
        set objGeo = objView.geometry
        x0 = objGeo.x
        y0 = objGeo.y
        'set objView.geometry = objGeo1
        ' Calculate radius
        select case no_levels
        case 1      distance_ratio = 1 / 4
        case 2      distance_ratio = 1 / 8
        case 3      distance_ratio = 1 / 12
        case else
                    distance_ratio = 1 / 15
        end select
        radius = contGeo.height * distance_ratio
        call addCLobjectViews(workareaView, objView, radius, 0, 0, 2*pi, x0, y0, 1, no_levels)

    end if

    if InputMode = "AddNeighbours2" and isEnabled(objView) then
        set inst = instView.instance
        set objects = inst.neighbourObjects
        for each obj in objects
            if isEnabled(obj) then
                if not modelObj.uri = obj.uri then
                    if not viewExists(obj) then
                        ' Create object view
                        set objView = workareaView.newObjectView(obj)
                        objView.textScale = 0.5
                    end if
                end if
            end if
        next
    end if
'stop
    if InputMode = "AddNeighbours" and isEnabled(objView) then
        set objects = inst.neighbourObjects
        for each mObj in objects
            set model1 = mObj.ownerModel
            if not model1 is Nothing then
                set relships = model1.relationships
                for each relship in relships
                    done = false
                    set origin = relship.origin
                    set originViews = modelView.findInstanceViews(origin)
                    set target = relship.target
                    set targetViews = modelView.findInstanceViews(target)
                    for each originView in originViews
                        for each targetView in targetViews
                            set relView = modelView.newRelationshipView(relship, originView, targetView)
                            done = true
                            exit for
                        next
                        if done then exit for
                    next
                next
            end if
        next
    end if
    if InputMode = "AddNeighbours2" then
        if isEnabled(rightpaneView) then
            call metis.doLayout(rightpaneView)
        end if
    end if
    if isEnabled(objView) then
        set instViewList = metis.newInstanceViewList
        set views = inst.views
        for each view in views
            set iv = modelView.findInstanceView(view.uri)
            if isEnabled(iv) then
                instViewList.addLast iv
            end if
        next
        modelView.selection = instViewList
    end if
end sub

'-------------------------------------------------------------------------------------------------------------
' [5] and [6] FUNCTIONS and SUBRoutines
'-------------------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [5a] Utility Function - isEnabled
	'-----------------------------------------------------------------------------------------------------
'    function isEnabled(inst)
'        isEnabled = true
'        if isEmpty(inst) then
'            isEnabled = false
'        elseif isNull(inst) then
'            isEnabled = false
'        elseif inst is Nothing then
'            isEnabled = false
'        elseif not inst.isValid then
'            isEnabled = false
'        end if
'    end function
	'-----------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [5b] Utility Function - instanceInList
	'-----------------------------------------------------------------------------------------------------

	  function instanceInList(instance, list)
		dim item
		instanceInList = false

		for each item in list
			if StrComp(instance.URI,item.URI) = 0 then instanceInList = true
		next
	  end function

	'-----------------------------------------------------------------------------------------------------
	' [5c] Utility Function - isTopObject
	'-----------------------------------------------------------------------------------------------------

    function isTopObject(inst, relType)
		dim item, rels
		dim partOfRules, rule

		isTopObject = false

        set rels = inst.getNeighbourRelationships(1, relType)
        if rels.count = 0 then
            isTopObject = true
        end if
	end function

	'-----------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [5d] Utility Function - create Tree View
	'-----------------------------------------------------------------------------------------------------

    function createTreeView(obj, isTop, instances, parentView, modelType, viewStrategy, apply_rule)
        dim childInst, objView, childInstView
        dim instList, objType, relType, rel, relList
        dim doIt, test
        dim partOfRules, rule, typeUri
'stop
        set objView = parentView.newObjectView(obj)
        if isTop then
            objView.textScale = 0.5
        else
            objView.textScale = 0.125
        end if

        for each childInst in obj.parts
            doIt = true
            if isEnabled(objType) then
                if not childInst.type.inherits(objType) then
                    doIt = false
                end if
            end if
            if not instances is Nothing then
                if not instanceInList(childInst,instances) then
                    doIt = false
                end if
            end if
            if doIt then
	            if childInst.parts.count > 0 then
                    if not childInst.isConnectorType then
                        set childInstView = createTreeView(childInst, false, instances, objView, modelType, viewStrategy, apply_rule)
                    end if
                else
				    set childInstView = objView.newObjectView(childInst)
				    childInstView.textScale = 0.125
				end if
    	    end if
        next
        if isEnabled(viewStrategy) then
'stop
            ' Get partOf rule
            test = viewStrategy.name
            test = viewStrategy.uri
            set partOfRules = viewStrategy.parts
            for each rule in partOfRules
                if StrComp(rule.type.name,"partOfRule") = 0 then
                    typeUri = rule.getNamedStringValue("PartType")
                    set objType = metis.findType(typeUri)
                    typeUri = rule.getNamedStringValue("RelType")
                    set relType = metis.findType(typeUri)
                end if
                ' Get neighbours
                set relList = obj.getNeighbourRelationships(0, relType)
                for each rel in relList
                    if includeInConfig(rel, RuleEngineProperty, RuleCodeProperty, apply_rule) then
                        set childInst = rel.target
                        if not instances is Nothing then
                            if instanceInList(childInst,instances) then
                                set childInstView = createTreeView(childInst, false, instances, objView, modelType, viewStrategy, apply_rule)
                            end if
                        else
                            set childInstView = createTreeView(childInst, false, instances, objView, modelType, viewStrategy, apply_rule)
                        end if
                    end if
                next
            next
        end if
        set createTreeView = objView
	end function

	'-----------------------------------------------------------------------------------------------------
	' [5e] Function&Sub - createObjectViews
	'-----------------------------------------------------------------------------------------------------
    sub createObjectViews(isTop, instances, parentView, modelType, viewStrategy, apply_rule)
        dim inst, instview, rels
        dim parentType, containerType

        for each inst in instances
            set rels = inst.getNeighbourRelationships(1, baseRelType)
            if rels.count = 0 then
                set instview = createTreeView(inst, isTop, Nothing, parentView, modelType, viewStrategy, apply_rule)
            end if
        next

    end sub

	'-----------------------------------------------------------------------------------------------------
	' [5f] Function&Sub - clearList
	'-----------------------------------------------------------------------------------------------------
    sub clearList(list)
        do until list.Count = 0
            call list.removeAt(1)
        loop
    end sub

	'-----------------------------------------------------------------------------------------------------
	' [5g] Function&Sub - viewExists
	'-----------------------------------------------------------------------------------------------------
    function viewExists(inst)
        dim v, view, views

        viewExists = false
        set views = inst.views
        for each view in views
            set v = modelView.findInstanceView(view.uri)
            if isEnabled(v) then
                viewExists = true
            end if
        next
    end function

	'-----------------------------------------------------------------------------------------------------
	' [5h] Function&Sub - getModel
	'-----------------------------------------------------------------------------------------------------
    function getModel(modelObj)
        dim inst, instances
        set getModel = modelObj.ownerModel
        set instances = modelObj.parts
        for each inst in instances
            if isEnabled(inst) then
                set getModel = inst.ownerModel
                exit for
            end if
        next
    end function

	'-----------------------------------------------------------------------------------------------------
	' [5i] Utility Function - findTopObject
	'-----------------------------------------------------------------------------------------------------
    function findTopObject(modelObj, topObjectType, viewStrategy, objName)
        dim inst, instances
        set findTopObject = Nothing
        if isEnabled(topObjectType) then
            set instances = modelObj.parts
            for each inst in instances
                if isEnabled(inst) then
                    if inst.type.uri = topObjectType.uri then
                        if inst.name = objName then
                           set findTopObject = inst
                        end if
                    end if
                end if
            next
        end if
	end function

	'-----------------------------------------------------------------------------------------------------
	' [5j] Utility Function - findModelObject
	'-----------------------------------------------------------------------------------------------------
    function findModelObject(modelObjectType, model)
        dim inst, instances, obj

        set findModelObject = Nothing
        set obj = metis.findInstance(model.uri)
        if isEnabled(modelObjectType) then
            set instances = obj.parts
            for each inst in instances
                if isEnabled(inst) then
                    if inst.type.uri = modelObjectType.uri then
                        set findModelObject = inst
                        exit for
                    end if
                end if
            next
            if isEnabled(findModelObject) then
                exit function
            end if
            for each inst in instances
                if isEnabled(inst) then
                    if inst.isConnectorType then
                        set findModelObject = inst.parts(1)
                        exit for
                    end if
                end if
            next
            if isEnabled(findModelObject) then
                exit function
            end if
        end if
        set findModelObject = obj
	end function

	'-----------------------------------------------------------------------------------------------------
	' [5k] Utility Function - getContentModels
	'-----------------------------------------------------------------------------------------------------
    function getContentModels
        dim modelList, models
        dim obj, parts, mObj
        dim child, children
'stop
        set modelList = metis.newInstanceList
        set obj = metis.findInstance(model.uri)
        modelList.addLast obj
        ' Find sub-models
        set parts = obj.parts
        for each obj in parts
            if obj.isConnectorType then
                set models = obj.parts
                for each mObj in models
                    if isEnabled(mObj) then
                        set children = mObj.parts
                        for each child in children
                            if isEnabled(child) then
                                modelList.addLast child
                                exit for
                            end if
                        next
                    end if
                next
            end if
        next
        set getContentModels = modelList
    end function

	'-----------------------------------------------------------------------------------------------------
	' [5l] Function&Sub - includeInConfig
	'-----------------------------------------------------------------------------------------------------
    function includeInConfig(rel, RuleEngineProperty, RuleCodeProperty, apply_rule)
        dim applyRule
        dim prop
        dim ruleEngine, rule

        on Error resume next

        if isEnabled(rel) then
            includeInConfig = true
        else
            includeInConfig = false
        end if

        if not applyRule then exit function

        ' Get rule engine
        set prop = rel.type.getProperty(RuleEngineProperty)
        if isEnabled(prop) then
            ruleEngine = rel.getNamedValue(RuleEngineProperty).getInteger
            select case ruleEngine
            case 0
                        exit function
            case 1
                        rule = rel.getNamedValue(RuleCodeProperty).getString
                        if Len(rule) > 0 then
'stop
                            call model.runMethodOnInst(ruleMethod, rel)
                            includeInConfig = rel.getNamedValue(RuleEvaluatedToProperty).getInteger
                        end if
            end select
        end if

    end function

	'-----------------------------------------------------------------------------------------------------
	' [6a] Function&Sub - findWorkArea
	'-----------------------------------------------------------------------------------------------------
    function findWorkArea(model, parentContainerType, workAreaType)
        dim parentContainers, parentCont
        dim workAreas, workArea

        set findWorkArea = Nothing
        set parentContainers = model.findInstances(parentContainerType,"","")
        if parentContainers.Count > 0 then
            set parentCont = parentContainers(1)
            set workAreas = parentCont.parts
            for each workArea in workAreas
		        set findWorkArea = workAreas(1)
		        exit for
            next
        end if
    end function

	'-----------------------------------------------------------------------------------------------------
	' [6b] Function&Sub - removeWorkArea
	'-----------------------------------------------------------------------------------------------------
    sub removeWorkArea(model, parentContainerType, workAreaType)
        dim parentContainers, parentCont
        dim workAreas, workArea

        set parentContainers = model.findInstances(parentContainerType,"","")
        if parentContainers.Count > 0 then
            set parentCont = parentContainers(1)
            set workAreas = parentCont.parts
            for each workArea in workAreas
		        call model.deleteObject(workArea)
            next
        end if

    end sub
	'-----------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [6c] Function&Sub - createWorkArea
	'-----------------------------------------------------------------------------------------------------
    function createWorkArea(model, parentContainerType, workAreaType, workAreaName)
        dim parentContainers, parentCont
        dim workAreas, workArea, workAreaView

        set createWorkArea = Nothing
        set parentContainers = model.findInstances(parentContainerType, "", "")
        if parentContainers.Count > 0 then
            set parentCont = parentContainers(1)
            set workArea = parentCont.newPart(workAreaType)
	        call workArea.setNamedStringValue("name", workAreaName)
	        set workAreaView = parentCont.Views(1).newObjectView(workArea)
            if isEnabled(workAreaView) then
                set createWorkArea = workAreaView
            end if
        end if

    end function
	'-----------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [6d] Function&Sub - getMCTinstances
	'-----------------------------------------------------------------------------------------------------
    function getMCTinstances(startObject, criteria, filter)

        set getMCTinstances = Nothing
        if isEnabled(criteria) then
            if isEnabled(filter) then
                call criteria.setArgument("name", filter.getNamedValue("name"))
                call criteria.setArgument("description", filter.getNamedValue("description"))
            end if
            if not isEnabled(startObject) then
                set getMCTinstances = metis.runCriteria(criteria)
            else
                set getMCTinstances = metis.runCriteriaOnInstance(criteria, startObject)
            end if
        end if

    end function
	'-----------------------------------------------------------------------------------------------------

	'-----------------------------------------------------------------------------------------------------
	' [6e] Function&Sub - populateWorkArea
	'-----------------------------------------------------------------------------------------------------
    sub populateWorkArea(workAreaView, topObject, instances, modelType, viewStrategy, workareaLayoutStrategy, treeLayoutStrategy, apply_rule)
        dim topObjectView
        dim objType, relType, relDir, typeUri
        dim partOfRules, rule
        dim instList

        if not isEnabled(topObject) then
            if instances is Nothing then
                exit sub
            elseif instances.Count = 0 then
                exit sub
            end if
        end if
        '
        ' Create the views
'stop
        if isEnabled(topObject) then
            set topObjectView = createTreeView(topObject, true, instances, workAreaView, modelType, viewStrategy, apply_rule)
        elseif instances.Count > 0 then
            call createObjectViews(true, instances, workAreaView, modelType, viewStrategy, apply_rule)
        end if

        ' Set layout strategy on workarea
        if isEnabled(workareaLayoutStrategy) then
            set workAreaView.layoutStrategy = workareaLayoutStrategy
        end if
        ' Do the layout on workarea
        call metis.doLayout(workAreaView)

        ' Set layout strategy on topObject
        if isEnabled(treeLayoutStrategy) and isEnabled(topObject) then
            set topObjectView.layoutStrategy = treeLayoutStrategy
        end if
        if isEnabled(topObjectView) then
            ' Do the layout on topObject
            call metis.doLayout(topObjectView)
        end if

    end sub


	'-----------------------------------------------------------------------------------------------------
	' [6f] Function&Sub - addCLobjectViews
	'-----------------------------------------------------------------------------------------------------

    sub addCLobjectViews(parentView, instView, radius, a0, a1, a2, x0, y0, level, no_levels)
        dim pnt, size, size1, geo1, objGeo
        dim da, a, x, y, dx, dy, sf, ts
        dim inst, objView
        dim obj, objects
        dim i, no, no1
 'stop
        set inst = instView.instance
        ts = parentView.textScale
        select case level
        case 1      sf = 0.5
                    if no_levels = 1 then
                        ts = 1.25
                    else
                        ts = 1.8
                    end if
        case 2      sf = 1.0
                    ts = 2.15 'ts * (no_levels + 16)
        case 3      sf = 1.2
                    ts = 2.25 'ts * (no_levels + 20)
        case else   sf = 1.5
                    ts = 2.25 'ts * (no_levels + 24)
        end select

        set objects = inst.neighbourObjects
        no = 0
        for each obj in objects
            if not obj.type.inherits(valueType) then
                no = no + 1
            end if
        next
        if no > 0 then
            set geo1 = instView.geometry
            set size1 = geo1.size
            set pnt = modelView.newPoint(x0, y0)
            set size = modelView.newSize(size1.width * sf, size1.height * sf)
            dx = size.width / 2
            dy = size.height / 2
            set objGeo = modelView.newRect(pnt, size)
            da = (a2 - a1) / no
        end if
        i = 1
        for each obj in objects
            if isEnabled(obj) then
                if not modelObj.uri = obj.uri then
                    if not obj.type.inherits(valueType) then
                        if not viewExists(obj) then
                            ' Create object view
                            a = a0 -pi/2 + a1 + da*(i-0.5)
                            'a = a0 + a1 + da*(i-1)
                            x = x0 + (radius) * cos(a) + dx
                            y = y0 + (radius) * sin(a) + dy
                            pnt.x = x
                            pnt.y = y
                            set objGeo.point = pnt
                            set objView = parentView.newObjectView(obj)
                            objView.textScale = ts
                            set objView.geometry = objGeo
                            i = i + 1
                            ' Recursive call
                            if level < no_levels then
                                call addCLobjectViews(parentView, objView, radius, a, 0, 7*pi/8, x, y, level+1, no_levels)
                            end if
                        end if
                    end if
                end if
            end if
        next
    end sub

    function getContextObject(contextType)
        dim contexts, context

        set getContextObject = Nothing
        set contexts = model.findInstances(contextType, "", "")
        for each context in contexts
            if isEnabled(context) then
                set getContextObject = context
                exit for
            end if
        next

    end function


