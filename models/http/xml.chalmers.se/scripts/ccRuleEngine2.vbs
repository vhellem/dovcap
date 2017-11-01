msgbox getVPV2("Heated area")

function getVPV2(paramId)
    dim myModel, model1, myModelView
    dim inst, instView
    dim ccType, useCCtype, paramType, strValType, hasParamType, hasValueType, definitionType
    dim paramIdProperty, valueProperty
    dim ccObj, vpvObj
    dim vp, found

    set ccType         = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
    set useCCtype      = metis.findType("http://xml.chalmers.se/class/uses_configurable_component.kmd#uses_configurable_component")
    set paramType      = metis.findType("http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter")
    set hasParamType   = metis.findType("http://xml.chalmers.se/class/has_variant_parameter.kmd#has_variant_parameter")
    set definitionType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")
    set strValType     = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
    paramIdProperty    = "name"
    valueProperty      = "value"

    set myModel = metis.currentModel
    set myModelView = myModel.currentModelView
    set inst = myModel.currentInstance
    set instView = myModelView.currentInstanceView

    getVPV2 = ""
    vp = ""
    found = false
    set ccObj = getCCobject2(false, ccType, useCCtype, myModel, inst)
    if isEnabled2(ccObj) then
        set vpvObj = findVPVobject2(ccObj, paramType, paramIdProperty, paramId, strValType, definitionType)
        if isEnabled2(vpvObj) then
            getVPV2 = vpvObj.getNamedStringValue(valueProperty)
        end if
    end if
end function

function findVPVobject2(ccObj, paramType, paramIdProperty, paramId, valueType, definitionType)
    dim value, values
    dim vp, vpv, vps, vpid
    dim found

    set findVPVobject2 = Nothing
    set values = ccObj.neighbourObjects
    for each value in values
        if value.type.inherits(valueType) then
            set vps = value.getNeighbourObjects(0, definitionType, paramType)
            if vps.count > 0 then
                set vp = vps(1)
                vpid = vp.getNamedStringValue(paramIdProperty)
                if vpid = paramId then
                    set findVPVobject2  = value
                    found = true
                    exit for
                end if
            end if
        end if
    next
end function

function getCCobject2(useSub, ccType, useCCtype, model1, inst2)
    'dim model1
    dim part, parts, rel, rels
    dim obj, inst, instances

stop

    set getCCobject2 = Nothing

    set obj = metis.findInstance(model1.uri)
    if not useSub and isEnabled2(ccType) then
        set instances = obj.parts
        for each inst in instances
            if isEnabled(inst) then
                if inst.type.uri = ccType.uri then
                    set getCCobject2 = inst
                    exit for
                end if
            end if
        next
        if isEnabled2(getCCobject2) then
            exit function
        end if
        for each inst in instances
            if isEnabled(inst) then
                if inst.isConnectorType then
                    set obj = inst.parts(1)
                    if not obj.type.uri = ccType.uri then
                        set parts = obj.parts
                        for each part in parts
                            if isEnabled(part) then
                                if part.type.uri = ccType.uri then
                                    set getCCobject2 = part
                                    exit for
                                end if
                            end if
                        next
                        exit for
                    end if
                end if
            end if
        next
        if isEnabled(getCCobject2) then
            exit function
        end if
    elseif useSub and isEnabled2(inst2) then
        if isEnabled2(useCCtype) then
            set rels = inst.neighbourRelationships
            for each rel in rels
                if isEnabled2(rel) then
                    if rel.type.uri = useCCtype.uri then
                        set getCCobject2 = rel.target
                        exit for
                    end if
                end if
            next
        end if
    end if

end function

function isEnabled2(inst)
    isEnabled2 = true
    if isEmpty(inst) then
        isEnabled2 = false
    elseif isNull(inst) then
        isEnabled2 = false
    elseif inst is Nothing then
        isEnabled2 = false
    elseif not inst.isValid then
        isEnabled2 = false
    end if
end function

