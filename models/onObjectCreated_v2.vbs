option explicit

dim model, modelObject, ownerModel, modelView
dim parentInst, inst, instView, obj, relship
dim context, contextObj
dim isModel
dim specContainerType, hasViewStrategyType, isTopType
dim hasInstanceContextType, hasInstanceContext2Type
dim specObject, specObjects
dim wObject, wObjectView
dim strategyCont, strategyConts
dim cvwViewStrategy, rule
dim instContext, instContexts
dim rel, rels, relType
dim i

' Types
set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
set specContainerType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
set isTopType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

' Context
set model      = metis.currentModel
set modelView  = model.currentModelView
set inst       = metis.currentModel.currentInstance
set instView   = modelView.currentInstanceView
set parentInst = instView.parent.instance
if parentInst.ownerModel.uri <> model.uri then
    set metis.currentModel = parentInst.ownerModel
end if
set wObject     = findWorkWindow(instView)
set wObjectView = findWorkWindowView(instView)
set ownerModel  = metis.currentModel

'stop

' Relocate to model
isModel = false
set context = new EKA_Context
set context.currentModel        = model
set context.currentModelView    = modelView
set context.currentInstance     = wObject
set context.currentInstanceView = wObjectView
if isValid(context) then
    set modelObject = context.modelObject
    if isEnabled(modelObject) then
        set ownerModel = modelObject.ownerModel
        if not isEnabled(ownerModel) then isModel = true
        if isModel then
            if modelObject.uri <> model.uri then
                set inst =  relocate(inst, modelObject, instView)
                'set inst = instView.instance
            end if
        else
            set inst = relocate(inst, modelObject, instView)
            'set inst = instView.instance
        end if
    end if
end if

'stop
' Find instance context
if isEnabled(wObject) then
    set instContexts = wObject.getNeighbourRelationships(0, hasInstanceContext2Type)
    if instContexts.count > 0 then
        set rel = instContexts(1)
        if isEnabled(rel) then
            set instContext = rel.target
        end if
    end if
    if isEnabled(instContext) then
        set specObjects = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
        if specObjects.count > 0 then
            set specObject = specObjects(1)
            set rels = specObject.getNeighbourRelationships(0, isTopType)
            if rels.count > 0 then
                for each rel in rels
                    set obj = rel.target
                    if obj.type.uri = instContext.type.uri then
                        set contextObj = obj
                        exit for
                    end if
                next
            end if
            if isEnabled(contextObj) then
                set rels = contextObj.neighbourRelationships
                for each rel in rels
                    if rel.origin.type.uri = instContext.type.uri then
                        if rel.target.type.uri = inst.type.uri then
                            ' Create relationship
                            set relType = rel.type
                            set relship = ownerModel.newRelationship(relType, instContext, inst)
                            exit for
                        end if
                    elseif rel.target.type.uri = instContext.type.uri then
                        if rel.origin.type.uri = inst.type.uri then
                            ' Create relationship
                            set relType = rel.type
                            set relship = ownerModel.newRelationship(relType, inst, instContext)
                            exit for
                        end if
                    end if
                next
            end if
        end if
    end if
end if

' Find view strategies
if isEnabled(wObject) then
    set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
    if strategyConts.count > 0 then
        set strategyCont = strategyConts(1)
        set cvwViewStrategy = new CVW_ViewStrategy
        call cvwViewStrategy.build(strategyCont)
    end if
end if

if isValid(cvwViewStrategy) then
    for i = 1 to cvwViewStrategy.noHierarchyRules
        set rule = cvwViewStrategy.hierarchyRules(i)
        if rule.parentType.uri = parentInst.type.uri then
            if rule.childType.uri = inst.type.uri then
                set relship = ownerModel.newRelationship(rule.relType, parentInst, inst)
            end if
        end if
    next
end if

