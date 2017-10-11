'------------------------------------------------------------------------------------------------------------

option explicit
'-- Public Section
public model, modelview
public consistsOfType, modelType, ccType

dim InputModelType, InputObjectType
dim InputCCType, InputCSType, InputCEType, InputCRType, InputFRType, InputDSType, InputFMType, InputCOType
dim InputDPType, InputDPVType, InputIAType, InputIFType, InputPOType, InputVPType, InputVPVType, InputVRType
dim InputFRPType, InputFRPVType, InputCPType, InputCPVType
dim InputHasCSType, InputHasCEType, InputHasCOType, InputHasCRType, InputHasFRType, InputHasDSType, InputHasFMType, InputHasVRType
dim InputHasDPType, InputHasDPVType, InputHasIAType, InputHasIFType, InputHasPOType, InputHasVPType, InputHasVPVType
dim InputHasFRPType, InputHasFRPVType, InputHasCPType, InputHasCPVType
dim InputWorkareaType

dim objType, childType, parentType, workareaType
dim childObj, parentObj, childObjView, parentObjView
dim parentView, objView
dim modelObjects, modelObj, ccObj
dim consistsOfRels, consistsOfRel
dim consistsOfRelViews, consistsOfRelView
dim isTop, behavior, test, connectToParentView

'-- Initialization
set model     = metis.currentModel
set modelView = model.currentModelView
test = model.title

InputCCType    = "http://xml.chalmers.se/class/configurable_component.kmd#configurable_component"
InputCSType    = "http://xml.chalmers.se/class/composition_set.kmd#composition_set"
InputCEType    = "http://xml.chalmers.se/class/composition_element.kmd#composition_element"
InputCRType    = "http://xml.chalmers.se/class/composition_request.kmd#composition_request"
InputFRType    = "http://xml.chalmers.se/class/functional_requirement.kmd#functional_requirement"
InputDSType    = "http://xml.chalmers.se/class/design_solution.kmd#design_solution"
InputCOType    = "http://xml.chalmers.se/class/constraint.kmd#constraint"
InputCPType    = "http://xml.chalmers.se/class/constraint_parameter.kmd#constraint_parameter"
InputCPVType   = "http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value"
InputIAType    = "http://xml.chalmers.se/class/interaction.kmd#interaction"
InputIFType    = "http://xml.chalmers.se/class/interface.kmd#interface"
InputPOType    = "http://xml.chalmers.se/class/port.kmd#port"
InputVPType    = "http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter"
InputVPVType   = "http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value"
InputDPType    = "http://xml.chalmers.se/class/design_parameter.kmd#design_parameter"
InputDPVType   = "http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value"
InputFRPType   = "http://xml.chalmers.se/class/functional_requirement_parameter.kmd#functional_requirement_parameter"
InputFRPVType  = "http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value"
InputVRType    = "http://xml.chalmers.se/class/validation_rule.kmd#validation_rule"

InputHasCSType = "http://xml.chalmers.se/class/is_composed_using.kmd#is_composed_using"
InputHasCEType = "http://xml.chalmers.se/class/has_composition_element.kmd#has_composition_element"
InputHasCOType = "http://xml.chalmers.se/class/is_constrained_by.kmd#Is_constrained_by"
InputHasCPType = "http://xml.chalmers.se/class/has_constraint_parameter.kmd#has_constraint_parameter"
InputHasCPVType = "http://xml.chalmers.se/class/has_constraint_parameter_value.kmd#has_constraint_parameter_value"
InputHasCRType = "http://xml.chalmers.se/class/has_composition_request.kmd#has_composition_request"
InputHasFRType = "http://xml.chalmers.se/class/requires_function.kmd#requires_function"
InputHasDSType = "http://xml.chalmers.se/class/is_solved_by.kmd#is_solved_by"
InputHasFMType = "http://xml.chalmers.se/class/has_forklaringsmodell.kmd#has_forklaringsmodell"
InputHasIAType = "http://xml.chalmers.se/class/has_interaction.kmd#has_interaction"
InputHasIFType = "http://xml.chalmers.se/class/has_interface.kmd#has_interface"
InputHasPOType = "http://xml.chalmers.se/class/has_port.kmd#has_port"
InputHasVPType  = "http://xml.chalmers.se/class/has_variant_parameter.kmd#has_variant_parameter"
InputHasVPVType = "http://xml.chalmers.se/class/has_variant_parameter_value.kmd#has_variant_parameter_value"
InputHasDPType  = "http://xml.chalmers.se/class/has_design_parameter.kmd#has_design_parameter"
InputHasDPVType = "http://xml.chalmers.se/class/has_design_parameter_value.kmd#has_design_parameter_value"
InputHasFRPType = "http://xml.chalmers.se/class/has_functional_requirement_parameter.kmd#has_functional_requirement_parameter"
InputHasFRPVType = "http://xml.chalmers.se/class/has_functional_requirement_parameter_value.kmd#has_functional_requirement_parameter_value"
InputHasVRType = "http://xml.chalmers.se/class/has_validation_rule.kmd#has_validation_rule"

InputWorkareaType     = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"

'-- Main action
'-- Find parent and child objects
'stop
set ccType = metis.findType(InputCCType)
set workareaType  = metis.findType(InputWorkareaType)

set childObj  = model.currentInstance
set childObjView = modelView.currentInstanceView
set parentObjView = childObjView.parent
test = parentObjView.uri
set parentObj = parentObjView.instance
test = parentObj.uri
set modelObj = metis.findInstance(model.uri)

set ccObj = getModelObj(modelObj)
set modelType = modelObj.type

' Get the correct consistsOfType
set parentType = parentObj.type
set childType = childObj.type

isTop = true
behavior = "tree"
connectToParentView = true
if childType.uri = InputCSType then
    set consistsOfType = metis.findType(InputHasCSType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    isTop = true 'false
    behavior = "nested"
elseif childType.uri = InputCEType then
    set consistsOfType = metis.findType(InputHasCEType)
    isTop = false
elseif childType.uri = InputCRType then
    set consistsOfType = metis.findType(InputHasCRType)
    isTop = false
elseif childType.uri = InputFRType then
    if parentType.uri = ccType.uri then
        set consistsOfType = metis.findType(InputHasFMType)
    elseif parentType.uri = workareaType.uri then
        set consistsOfType = metis.findType(InputHasFMType)
        set parentObj = ccObj
    else
        set consistsOfType = metis.findType(InputHasFRType)
        isTop = false
    end if
elseif childType.uri = InputDSType then
    set consistsOfType = metis.findType(InputHasDSType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    if ccIsParent(parentObj, ccObj) then
        connectToParentView = false
    else
        isTop = false
    end if
elseif childType.uri = InputCOType then
    if parentType.uri = ccType.uri then
        set consistsOfType = metis.findType(InputHasFMType)
    elseif parentType.uri = workareaType.uri then
        set consistsOfType = metis.findType(InputHasFMType)
        set parentObj = ccObj
    else
        set consistsOfType = metis.findType(InputHasCOType)
    end if
elseif childType.uri = InputCPType then
    set consistsOfType = metis.findType(InputHasCPType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    if ccIsParent(parentObj, ccObj) then
        connectToParentView = false
    end if
elseif childType.uri = InputCPVType then
    set consistsOfType = metis.findType(InputHasCPVType)
elseif childType.uri = InputDPType then
    set consistsOfType = metis.findType(InputHasDPType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    if ccIsParent(parentObj, ccObj) then
        connectToParentView = false
    else
        isTop = false
    end if
elseif childType.uri = InputDPVType then
    set consistsOfType = metis.findType(InputHasDPVType)
elseif childType.uri = InputFRPType then
    set consistsOfType = metis.findType(InputHasFRPType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    if ccIsParent(parentObj, ccObj) then
        connectToParentView = false
    end if
elseif childType.uri = InputFRPVType then
    set consistsOfType = metis.findType(InputHasFRPVType)
elseif childType.uri = InputIAType then
    set consistsOfType = metis.findType(InputHasIAType)
elseif childType.uri = InputIFType then
    set consistsOfType = metis.findType(InputHasIFType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
elseif childType.uri = InputPOType then
    set consistsOfType = metis.findType(InputHasPOType)
    isTop = false
elseif childType.uri = InputVPType then
    set consistsOfType = metis.findType(InputHasVPType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
    if not ccIsParent(parentObj, ccObj) then
        isTop = false
    end if
elseif childType.uri = InputVPVType then
    set consistsOfType = metis.findType(InputHasVPVType)
elseif childType.uri = InputVRType then
    set consistsOfType = metis.findType(InputHasVRType)
    if parentType.uri = workareaType.uri then
        set parentObj = ccObj
    end if
else
    set consistsOfType = Nothing
end if

'stop

' Set text area
if isTop then
    set objView = getParallelTopObjectView(parentObjView, behavior) ' mode = nested or tree
    if isEnabled(objView) then
        test = objView.absTextScale
    else
        test = parentObjView.absTextScale
    end if
    childObjView.absTextScale = test
else
    test = parentObjView.absTextScale
    childObjView.absTextScale = test
end if

'stop
if isEnabled(consistsOfType) then
    '-- Check if this is a relocation
    set consistsOfRels = childObj.getNeighbourRelationships(1, consistsOfType)
    if consistsOfRels.count = 0 then
        ' This is a new object
        if connectToParentView then
            set consistsOfRel = model.newRelationship(consistsOfType, parentObj, childObj)
            if isEnabled(consistsOfRel) then
                test = consistsOfRel.uri
            end if
        end if
        set childObj.parent = modelObj
        'if isTop then
        '    childObjView.textScale = 0.5
        'else
        '    childObjView.textScale = 0.125
        'end if
    else
        ' Relocate
        set consistsOfRel = consistsOfRels(1)
        consistsOfRel.origin = parentObj
        set consistsOfRelViews = consistsOfRel.views
        if consistsOfRelViews.count > 0 then
            set consistsOfRelView = consistsOfRelViews(1)
            set consistsOfRelView.origin = parentObjView
        end if
    end if
end if
' Do automatic layout
set parentView = modelView.currentInstanceView
do while isEnabled(parentView)
    set parentType = parentView.instance.type
    if parentType.uri = InputWorkareaType then
        call metis.doLayout(parentView)
        exit do
    end if
    set parentView = parentView.parent
loop

function isEnabled(inst)
    isEnabled = true
    if isEmpty(inst) then
        isEnabled = false
    elseif isNull(inst) then
        isEnabled = false
    elseif inst is Nothing then
        isEnabled = false
    elseif not inst.isValid then
        isEnabled = false
    end if
end function

function ccIsParent(obj, ccObj)
    ccIsParent = false
    if obj.uri = ccObj.uri then
        ccIsParent = true
    end if
end function


function getModelObj(modelObj)
    dim objects, obj
    dim models, parts, part

    set getModelObj = Nothing
    set objects = modelObj.parts
    for each obj in objects
        if isEnabled(obj) then
            if obj.type.uri = ccType.uri then
                set getModelObj = obj
                exit for
            end if
        end if
    next
    if getModelObj is Nothing then
        for each obj in objects
            if isEnabled(obj) then
                if obj.type.isConnectorType then
                    set models = obj.parts
                    if models.count > 0 then
                        set modelObj = models(1)
                        set parts = modelObj.parts
                        for each part in parts
                            if isEnabled(part) then
                                if part.type.uri = ccType.uri then
                                    set getModelObj = part
                                    exit for
                                end if
                            end if
                        next
                    end if
                end if
            end if
        next
    end if
end function

function getParallelTopObjectView(parentView, behavior)
    dim view, views

    set getParallelTopObjectView = Nothing
    set views = parentView.children
    for each view in views
        if view.hasInstance then
            if behavior="tree" and view.isTree then
                set getParallelTopObjectView = view
                exit for
            elseif behavior="nested" and view.isNested then
                set getParallelTopObjectView = view
                exit for
            end if
        end if
    next
end function

