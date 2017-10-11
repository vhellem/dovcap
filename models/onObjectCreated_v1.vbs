option explicit

dim model, modelObject, ownerModel, modelView
dim parentInst, inst, instView, relship
dim context
dim isModel
dim specContainerType, hasViewStrategyType
dim wObject
dim strategyCont, strategyConts
dim cvwViewStrategy, rule
dim i

' Types
set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
set specContainerType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")

' Context
set model     = metis.currentModel
set modelView = model.currentModelView
set inst      = metis.currentModel.currentInstance
set instView  = modelView.currentInstanceView
set parentInst = instView.parent.instance
if parentInst.ownerModel.uri <> model.uri then
    set metis.currentModel = parentInst.ownerModel
end if
set ownerModel = metis.currentModel

'stop

' Is it possible to not relocate a duplicate view !!

' Relocate to model
isModel = false
set context = new EKA_Context
set context.currentModel = model
set context.currentModelView = modelView
if isValid(context) then
    set modelObject = context.contentModel
    if isEnabled(modelObject) then
        set ownerModel = modelObject.ownerModel
        if not isEnabled(ownerModel) then isModel = true
        if isModel then
            if modelObject.uri <> model.uri then
                call relocate(inst, modelObject, instView)
            end if
        else
            call relocate(inst, modelObject, instView)
        end if
    end if
end if

' Find view strategies
set wObject = findWorkWindow(instView)
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

function findWorkWindow(instView)
    dim windowType, window2Type
    dim parentView, parentType

    set findWorkWindow = Nothing
    set windowType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
    set window2Type    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")

    if isEnabled(instView) then
        set parentView = instView.parent
        if hasInstance(parentView) then
            set parentType = parentView.instance.type
            if parentType.uri = windowType.uri then
                set findWorkWindow = parentView.instance
            elseif parentType.uri = window2Type.uri then
                set findWorkWindow = parentView.instance
            else
                set findWorkWindow = findWorkWindow(parentView)
            end if
        end if
    end if
end function

