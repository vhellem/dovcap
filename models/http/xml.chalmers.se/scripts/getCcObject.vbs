    Function getCcObject(inst, instView)
        dim instType
        dim actionType, hasContentModelType, hasInstanceContext2Type
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

        set actionType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
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
                        if instContext.type.inherits(GLOBAL_Type_CC) then
                            set getCcObject = instContext
                        else
                            set contentModel = instContext.ownerModel
                        end if
                    end if
                else
                    set connectors = wObject.getNeighbourObjects(0, hasContentModelType, GLOBAL_Type_AnyObject)
                    if connectors.count > 0 then
                        set connector = connectors(1)
                        set contentModel = getModelFromConnector(connector)
                    end if
                end if
            else
                ' Ask for model
                modelContext = "SubModel"
                modelViewName = "ContentModel"
                set connector = findInstModel2(modelContext, modelViewName)
                if isValid(connector) then
                    set contentModel = getModelFromConnector(connector)
                end if
            end if
            if isValid(contentModel) then
                set parts = contentModel.parts
                for each part in parts
                    if part.type.inherits(GLOBAL_Type_CC) then
                        set getCcObject = part
                        exit for
                    end if
                next
            end if
        end if
    End Function

