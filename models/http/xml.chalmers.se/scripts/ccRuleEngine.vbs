option explicit

public model, modelView

sub includeInConfiguration
    dim model, inst
    dim propName, intVal

    propName = "ruleEvaluatedTo"

    set model = metis.currentModel
    set inst = model.currentInstance

    set intVal = metis.newValue
    call intVal.setInteger(1)
    call inst.setNamedValue(propName, intVal)

end sub

sub excludeFromConfiguration
    dim model, inst
    dim propName, intVal

    propName = "ruleEvaluatedTo"

    set model = metis.currentModel
    set inst = model.currentInstance
    
    set intVal = metis.newValue
    call intVal.setInteger(0)
    call inst.setNamedValue(propName, intVal)

end sub

function getIncludedInConfiguration
    dim model, inst
    dim propName, intVal

    propName = "ruleEvaluatedTo"

    set model = metis.currentModel
    set inst = model.currentInstance

    set intVal = inst.getNamedValue(propName)
    getIncludedInConfiguration = intVal.getInteger

end function

function getVPV(paramId)
    dim model1
    dim inst, instView
    dim paramIdProperty, valueProperty
    dim ccObj, vpvObj
    dim vp, found

    paramIdProperty    = "paramId"
    valueProperty      = "value"

    set model = metis.currentModel
    set modelView = model.currentModelView
    set instView = modelView.currentInstanceView

    getVPV = ""
    vp = ""
    found = false

    set ccObj = getCCobject(false, GLOBAL_Type_CC, GLOBAL_Type_usesCC)
    if isEnabled(ccObj) then
        set vpvObj = findVPVobject(ccObj, GLOBAL_Type_VP, paramIdProperty, paramId, GLOBAL_Type_EkaValue, GLOBAL_Type_EkaHasDefinition)
        if isEnabled(vpvObj) then
            getVPV = vpvObj.getNamedStringValue(valueProperty)
        end if
    end if
end function

sub setVPV(paramId, paramValue)
    dim model1
    dim inst, instView
    dim paramIdProperty, valueProperty
    dim ccObj, vpvObj
    dim vp, found

    paramIdProperty    = "paramId"
    valueProperty      = "value"

    set model = metis.currentModel
    set modelView = model.currentModelView
    set instView = modelView.currentInstanceView

    vp = ""
    found = false

    set ccObj = getCCobject(true, GLOBAL_Type_CC, GLOBAL_Type_usesCC)
    if isEnabled(ccObj) then
        set vpvObj = findVPVobject(ccObj, GLOBAL_Type_VP, paramIdProperty, paramId, GLOBAL_Type_EkaValue, GLOBAL_Type_EkaHasDefinition)
        if not isEnabled(vpvObj) then
            set vpvObj = newVPV(ccObj, paramId, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_hasVP, GLOBAL_Type_VP, paramIdProperty)
        end if
        if isEnabled(vpvObj) then
            call vpvObj.setNamedStringValue(valueProperty, paramValue)
        end if
    end if
end sub

function newVPV(ccObj, paramId, hasValueType, valueType, definitionType, hasParamType, paramType, paramIdProperty)
    dim model1
    dim vpvObj, vpObj
    dim rel, defRel

    set newVPV = Nothing
    set model1 = ccObj.ownerModel
    set vpvObj = ccObj.newPart(valueType)
    if isEnabled(vpvObj) then
        set rel = model1.newRelationship(hasValueType, ccObj, vpvObj)
        set vpObj = findVPobj(ccObj, paramId, hasParamType, paramType, paramIdProperty)
        if isEnabled(vpObj) then
            set defRel = model1.newRelationship(definitionType, vpvObj, vpObj)
            set newVPV = vpvObj
        end if
    end if

end function

function findVPobj(ccObj, paramId, hasParamType, paramType, paramIdProperty)
    dim vp, vps, vpid

    set findVPobj = Nothing
    set vps = ccObj.getNeighbourObjects(0, hasParamType, paramType)
    for each vp in vps
        vpid = vp.getNamedStringValue(paramIdProperty)
        if vpid = paramId then
            set findVPobj = vp
            exit for
        end if
    next

end function

function findVPVobject(ccObj, paramType, paramIdProperty, paramId, valueType, definitionType)
    dim value, values
    dim vp, vpv, vps, vpid
    dim found

    set findVPVobject = Nothing
    set values = ccObj.neighbourObjects
    for each value in values
        if value.type.inherits(valueType) then
            set vps = value.getNeighbourObjects(0, definitionType, paramType)
            if vps.count > 0 then
                set vp = vps(1)
                vpid = vp.getNamedStringValue(paramIdProperty)
                if vpid = paramId then
                    set findVPVobject  = value
                    found = true
                    exit for
                end if
            end if
        end if
    next
end function

function getCCobject(useSub, ccType, useCCtype)
    dim inst, instView
    dim model1
    dim part, parts, rel, rels

    set getCCobject = Nothing
    set instView = modelView.currentInstanceView
    if instView.hasInstance then
        set inst = instView.instance
        if not useSub then
            set model1 = inst.ownerModel
            set parts = model1.parts
            for each part in parts
                if part.type.uri = ccType.uri then
                    set getCCobject = part
                    exit for
                end if
            next
        elseif isEnabled(useCCtype) then
            set rels = inst.neighbourRelationships
            for each rel in rels
                if isEnabled(rel) then
                    if rel.type.uri = useCCtype.uri then
                        set getCCobject = rel.target
                        exit for
                    end if
                end if
            next
        end if
    end if

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

