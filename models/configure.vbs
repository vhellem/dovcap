option explicit

public model

dim ccObj, ccType, ccRelType
dim menu
dim rule, rules
dim ruleType, hasRuleType
dim RuleEngineProperty, RuleCodeProperty, RuleEvaluatedToProperty
dim viewStrategyType, useStrategyType
dim viewStrategy, viewStrategies
dim rel, rels
dim test, isValid


set model 		= metis.currentModel
set menu  	    = model.currentInstance

set ccType      = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
set ccRelType   = metis.findType("http://xml.chalmers.se/class/cc_relship.kmd#CC_relship")
set ruleType    = metis.findType("http://xml.chalmers.se/class/configuration_rule.kmd#configuration_rule")
set hasRuleType = metis.findType("http://xml.chalmers.se/class/has_configuration_rule.kmd#has_configuration_rule")
set viewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_strategy.kmd#ObjType_AKM:ViewStrategy_UUID")
set useStrategyType  = metis.findType("http://xml.activeknowledgemodeling.com/akm/languages/view_relships.kmd#UiReltype_AKM:useViewStrategy_UUID")


set ccObj = getCCobject(false, ccType, Nothing, model, menu)

set viewStrategies = menu.getNeighbourObjects(0, useStrategyType, viewStrategyType)
if viewStrategies.count > 0 then
    set viewStrategy = viewStrategies(1)
else
    set viewStrategy = Nothing
end if

'stop

' Validate configuration rules
isValid = true
set rules = ccObj.getNeighbourObjects(0, hasRuleType, ruleType)
for each rule in rules
    test = includeInConfig(rule)
    if not test = 1 then
        isValid = false
    end if
next

'stop

if isValid then
    ' Do the actual configuration
    set rels = ccObj.neighbourRelationships
    for each rel in rels
        if isEnabled(rel) then
            if not rel.target.uri = ccObj.uri then
                call configureObject(rel.target, viewStrategy)
            end if
        end if
    next
end if

