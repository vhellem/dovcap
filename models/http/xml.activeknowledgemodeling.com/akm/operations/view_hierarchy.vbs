'------------------------------------------------------------------------------------------------------------

option explicit
'-- Public Section
public model, modelObj, modelview
public consistsOfType, modelType, workareaType

dim InputContainerType, InputWorkareaType
dim InputModelType, InputObjectType
dim InputProductType, InputPropertyType
dim InputHasPartType, InputHasPropertyType
dim InputFuncReqType, InputDesignSoluType
dim InputHasFuncReqType, InputHasDesSolType
dim InputConstraintType, InputInterfaceType, InputPortType, InputHasPortType

dim objType, childType, parentType
dim childObj, parentObj, childObjView, parentObjView
dim parentView, objView
dim consistsOfRel, consistsOfRels
dim modelObject, modelObjects
dim consistsOfRelView, consistsOfRelViews
dim rel, rels
dim behavior, isTop, test

'-- Initialization
set model     = metis.currentModel
set modelView = model.currentModelView

InputContainerType   = "metis:stdtypes#oid3"
InputWorkareaType    = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"
InputModelType       = "http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID"
InputObjectType      = "http://xml.activeknowledgemodeling.com/eka/languages/eka_element.kmd#ObjType_EKA:Element_UUID"

InputProductType     = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID"
InputPropertyType    = "http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID"
InputHasPartType     = "http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Part_UUID"
InputHasPropertyType = "http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID"

InputFuncReqType     = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/fm_objects.kmd#ObjType_CPPD:FunctionalRequirement_UUID"
InputDesignSoluType  = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/fm_objects.kmd#ObjType_CPPD:DesignSolution_UUID"
InputHasFuncReqType  = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/fm_relships.kmd#RelType_CPPD:RequiresFunction_UUID"
InputHasDesSolType   = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/fm_relships.kmd#RelType_CPPD:IsSolvedBy_UUID"

InputPortType        = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/port.kmd#ObjType_CPPD:Port_UUID"
InputHasPortType     = "http://xml.activeknowledgemodeling.com/cppd new/product/languages/has_port.kmd#RelType_CPPD:HasPort_UUID"

set modelType      = metis.findType(InputModelType)
set objType        = metis.findType(InputObjectType)
set workareaType   = metis.findType(InputWorkareaType)

' Find model object
set modelObjects = model.findInstances(modelType, "", "")
if modelObjects.count>0 then
    set modelObject = modelObjects(1)
end if

'-- Main action
'-- Find parent and child objects
set childObj  = model.currentInstance
set childObjView = modelView.currentInstanceView
set parentObjView = childObjView.parent
set parentObj = parentObjView.instance
set modelObj = metis.findInstance(model.uri)

' Get the correct consistsOfType
stop
set parentType = parentObj.type
set childType = childObj.type
if childType.uri = InputProductType and parentType.uri = InputProductType then
    set consistsOfType = metis.findType(InputHasPartType)
elseif childType.uri = InputPropertyType and parentType.uri = InputProductType then
    set consistsOfType = metis.findType(InputHasPropertyType)
elseif childType.uri = InputFuncReqType then
    if parentObj.type.uri = workareaType.uri then
        set consistsOfType = Nothing
    elseif parentObj.type.uri = InputContainerType then
        set consistsOfType = Nothing
    else
        set consistsOfType = metis.findType(InputHasFuncReqType)
    end if
elseif childType.uri = InputDesignSoluType then
    set consistsOfType = metis.findType(InputHasDesSolType)
elseif childType.uri = InputPortType then
    set consistsOfType = metis.findType(InputHasPortType)
else
    set consistsOfType = Nothing
end if

if isEnabled(consistsOfType) then
    '-- Check if this is a relocation
    set consistsOfRels = childObj.getNeighbourRelationships(1, consistsOfType)
    if consistsOfRels.count > 0 then
        ' Relocate
        set consistsOfRel = consistsOfRels(1)
        consistsOfRel.origin = parentObj
        set consistsOfRelViews = consistsOfRel.views
        if consistsOfRelViews.count > 0 then
            set consistsOfRelView = consistsOfRelViews(1)
            set consistsOfRelView.origin = parentObjView
        end if
    else
        ' This is a new object
        set consistsOfRel = model.newRelationship(consistsOfType, parentObj, childObj)
        set childObj.parent = modelObject
    end if
elseif isEnabled(modelObject) then
    set childObj.parent = modelObject
end if

' Fix text factor
behavior = "tree"
isTop = true
'stop
set rels = childObj.neighbourRelationships
for each rel in rels
    if rel.target.uri = childObj.uri then
        isTop = false
        exit for
    end if
next
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

' Do automatic layout
set parentView = modelView.currentInstanceView
do while isEnabled(parentView)
    set parentType = parentView.instance.type
    if parentType.uri = InputWorkareaType then
        'call metis.doLayout(parentView)
        exit do
    end if
    set parentView = parentView.parent
loop

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

