option explicit

dim model, modelView
dim obj, objView
dim apply_rule
dim ccType, ccObj, contextType, contextObject
dim action, actions1, actionType
dim viewStrategy, viewStrategies
dim viewStrategyType, useStrategyType
dim value
dim pv, parentView

set model = metis.currentModel
set modelView = model.currentModelView
set objView = modelView.currentInstanceView

set ccType      = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
set actionType  = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:MenuAction_UUID")
set contextType = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:ViewContext_UUID")
set viewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_strategy.kmd#ObjType_AKM:ViewStrategy_UUID")
set useStrategyType  = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_relships.kmd#UiReltype_AKM:useViewStrategy_UUID")

set parentView = objView.parent
set pv = parentView
while isEnabled(pv)
    set pv = parentView.parent
    if isEnabled(pv) then
        set parentView = pv
    end if
wend

set model = parentView.children(1).instance.ownerModel

set actions1 = model.findInstances(actionType, "name", "CS is_implementation_of")
'set actions1 = model.findInstances(actionType, "name", "CS is_composed_of")
set action = actions1(1)

' Apply rules ?
apply_rule = 0
set contextObject = getContextObject(contextType)
if isEnabled(contextObject) then
    set value = contextObject.getNamedValue("option")
    apply_rule = value.getInteger
end if

' Find view strategy
set viewStrategies = action.getNeighbourObjects(0, useStrategyType, viewStrategyType)
if viewStrategies.count > 0 then
    set viewStrategy = viewStrategies(1)
else
    set viewStrategy = Nothing
end if

' Remove old stuff
call removeChildren(modelView, objView)
set obj = Nothing
call createTreeView(obj, objView, viewStrategy, apply_rule)

' end


    function createTreeView(obj, parentView, viewStrategy, apply_rule)
        dim model1
        dim childInst, objView, childInstView
        dim instList, objType, relType, rel, relList
        dim doIt, test, textScale, parentAbsScale, objAbsScale
        dim partOfRules, typeUri
        dim part, parts
        dim prop, rule, ruleEngine, RuleEvaluatedToProperty
        dim isInConfig
'stop
        RuleEvaluatedToProperty = "ruleEvaluatedTo"

        textScale = parentView.textScale
        parentAbsScale = parentView.absTextScale

        if isEnabled(obj) then
            set objView = parentView.newObjectView(obj)
            objView.close
        else
            set objView = parentView
            set obj = objView.instance
            objView.open
            call metis.zoomInstanceView(modelView, objView)
        end if

        if isEnabled(viewStrategy) then
            ' Get partOf rule
            set partOfRules = viewStrategy.parts
            for each rule in partOfRules
                if StrComp(rule.type.name,"partOfRule") = 0 then
                    typeUri = rule.getNamedStringValue("PartType")
                    set objType = metis.findType(typeUri)
                    typeUri = rule.getNamedStringValue("RelType")
                    if not typeUri = "part-rule" then
                        set relType = metis.findType(typeUri)
                    end if
                end if
                if isEnabled(obj) then
                    ' Get neighbours
                    set relList = obj.getNeighbourRelationships(0, relType)
                    for each rel in relList
'stop
                        if apply_rule then
                            isInConfig = rel.getNamedValue(RuleEvaluatedToProperty).getInteger
                        else
                            isInConfig = 1
                        end if
                        if isInConfig = 1 then
                            set childInst = rel.target
                            set childInstView = createTreeView(childInst, objView, viewStrategy, apply_rule)
                        end if
                    next
                end if
            next
        end if
        parentView.absTextScale = parentAbsScale
        set createTreeView = objView
	end function

sub removeChildren(modelView, objView)
    dim child, children

    set children = objView.children
    for each child in children
        call removeChildren(modelView, child)
        modelView.deleteObjectView(child)
    next

end sub

    function getContextObject(contextType)
        dim contexts, context

        set getContextObject = Nothing
        set contexts = model.findInstances(contextType, "", "")
        for each context in contexts
            if isEnabled(context) then
                set getContextObject = context
                exit for
            end if
        next

    end function





