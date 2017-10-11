option explicit
dim model, modelView
dim rel, relView
dim inst, rule
dim relType, origin, target
dim originView, targetView, view, views
dim workWindow, wObject, objView
dim cvwViewStrategy, strategyCont, strategyConts
dim hasViewStrategyType, specContainerType
dim hasInstanceContextType
dim instanceCont, instanceConts
dim RelationshipViewMode
dim i

set specContainerType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")

set model = metis.currentModel
set modelView = model.currentModelView
set rel = model.currentInstance
set relView = modelView.currentInstanceView

set model = getCVWmodel

'stop
if rel.isRelationship then
    set relType = rel.type
    set origin = rel.origin
    set target = rel.target

    set workWindow = Nothing
    set views = origin.views
    for each view in views
        if view.url = model.url then
            set originView = view
            set workWindow = findWorkWindowView(originView)
        end if
    next
    set views = target.views
    for each view in views
        if view.url = model.url then
            set targetView = view
        end if
    next

    if isEnabled(workWindow) then
        set wObject = workWindow.instance
        ' Get instance context parameters
        set instanceConts = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
        if instanceConts.count > 0 then
            set instanceCont = instanceConts(1)
            RelationshipViewMode = getPropertyValue(instanceCont, "RelationshipViewMode")
        end if

        if RelationshipViewMode = "Hierarchy" then
            set cvwViewStrategy = Nothing ' find view strategy
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
            end if

            ' Find rule about reltype if it exists
            if isValid(cvwViewStrategy) then
                for i = 1 to cvwViewStrategy.noHierarchyRules
                    set rule = cvwViewStrategy.hierarchyRules(i)
                    if rel.type.uri = rule.relType.uri then
                        if rule.relDir = 0 then
                            if isInView(originView, workWindow) and isInView(targetView, workWindow) then
                                if origin.type.uri = rule.parentType.uri then
                                    if target.type.uri = rule.childType.uri then
                                        ' Action
                                        'modelView.deleteRelationshipView(relView)
                                        set targetView.parent = originView
                                        'objView.textScale = 0.25
                                    end if
                                end if
                            end if
                        elseif rule.relDir = 1 then
                            if isInView(originView, workWindow) and isInView(targetView, workWindow) then
                                if target.type.uri = rule.parentType.uri then
                                    if origin.type.uri = rule.childType.uri then
                                        ' Action
                                        'modelView.deleteRelationshipView(relView)
                                        set originView.parent = targetView
                                        'objView.textScale = 0.25
                                    end if
                                end if
                            end if
                        end if
                    end if
                next
            end if
        end if
    end if
    if isEnabled(originView) then
        'call metis.doLayout(originView)
    end if
end if

'-----------------------------------------------------------
    Private Function getPropertyValue(inst, propName)
        dim prop, properties
        dim propertyType, hasPropertyType

        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")

        getPropertyValue = ""
        set properties = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
        if isValid(properties) then
            for each prop in properties
                if prop.title = propName then
                    getPropertyValue = prop.getNamedStringValue("value")
                end if
            next
        end if
    End Function

'-----------------------------------------------------------

