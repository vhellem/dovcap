'cc_utilities.vbs

option explicit

'---------------------------------------------------------------------------------------------------
    Function getCcParameterValue(obj, paramName)
        dim valueType, hasValueType, hasDefinitionType
        dim defObj, valObj, valObjects
        dim rel, defRels

        set valueType         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        set hasValueType      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set hasDefinitionType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")

        getCcParameterValue = ""
        set valObjects = obj.getNeighbourObjects(0, hasValueType, valueType)
        for each valObj in valObjects
            set defRels = valObj.getNeighbourRelationships(0, hasDefinitionType)
            for each rel in defRels
                set defObj = rel.target
                if defObj.title = paramName then
                    getCcParameterValue = valObj.getNamedStringValue("value")
                    exit function
                end if
            next
        next
    End Function

'---------------------------------------------------------------------------------------------------
    Function getCcObject(inst, instView)
        dim instType
        dim anyObjectType, hasContentModelType, hasInstanceContext2Type
        dim parentView
        dim view, views
        dim workarea, workareas
        dim wObject, workWindow
        dim indx
        dim instContext, instContexts, context
        dim connector, connectors
        dim contentModel
        dim part, parts
        dim rel

        set getCcObject = Nothing

        set anyObjectType       = metis.findType("metis:stdtypes#oid1")
        set hasContentModelType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext2_UUID")
        set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

        set instType = inst.type
        if instType.inherits(actionType) then
            set workWindow = getWorkWindowView(inst, instView)
            ' Find configurable component
            if isValid(workWindow) then
                set wObject = workWindow.instance
                set instContexts = wObject.getNeighbourRelationships(0, hasInstanceContext2Type)
                if instContexts.count > 0 then
                    set rel = instContexts(1)
                    if isEnabled(rel) then
                        set instContext = rel.target
                        if instContext.type.inherits(ccType) then
                            set getCcObject = instContext
                        else
                            set contentModel = instContext.ownerModel
                        end if
                    end if
                else
                    set connectors = wObject.getNeighbourObjects(0, hasContentModelType, anyObjectType)
                    if connectors.count > 0 then
                        set connector = connectors(1)
                        set contentModel = getModelFromConnector(connector)
                    end if
                end if
                if isValid(contentModel) then
                    set parts = contentModel.parts
                    for each part in parts
                        if part.type.inherits(ccType) then
                            set getCcObject = part
                            exit for
                        end if
                    next
                end if
            end if
        end if
    End Function

'---------------------------------------------------------------------------------------------------

