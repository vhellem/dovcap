option explicit

dim model, object, parentObj
dim InputModelType, InputSpecificationContainerType
dim modelType, modelObjects, modelObject
dim specificationContainerType, isSpecification

set model     = metis.currentModel
set object    = model.currentInstance
set parentObj = object.parent

' Find model object
InputModelType  = "http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID"
set modelType   = metis.findType(InputModelType)
set modelObject = findModelObject(modelType, model)
' Check if specification
isSpecification = false
InputSpecificationContainerType  = "http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID"
set specificationContainerType   = metis.findType(InputSpecificationContainerType)
if isEnabled(specificationContainerType) then
    if parentObj.type.uri = specificationContainerType.uri then
        isSpecification = true
    end if
end if
' Relocate to model
if not isSpecification and parentObj.isContainer then
    set object.parent = modelObject
end if

'-----------------------------------------------------------------
function findModelObject(modelObjectType, model)
    dim inst, instances, obj

    if isEnabled(modelObjectType) then
        set obj = metis.findInstance(model.uri)
        set findModelObject = Nothing
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
        end if
    end if
    if not isEnabled(findModelObject) then
        set findModelObject = metis.findInstance(model.uri)
    end if
end function

'-----------------------------------------------------------------
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

