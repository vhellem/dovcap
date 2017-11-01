option explicit

dim model, inst, ccObj
dim ccType, useCCtype, ruleType, hasRuleType, method
dim rule, rules, ruleCode, ruleCodeProperty

set model = metis.currentModel
set inst = model.currentInstance

set ccType         = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
set ruleType       = metis.findType("http://xml.chalmers.se/class/validation_rule.kmd#validation_rule")
set hasRuleType    = metis.findType("http://xml.chalmers.se/class/has_validation_rule.kmd#has_validation_rule")
set method         = metis.findMethod("http://xml.chalmers.se/methods/rule_methods.kmd#evaluateRule")
ruleCodeProperty = "ruleCode"

set ccObj = findModelObject(ccType, model)

set rules = ccObj.getNeighbourObjects(0, hasRuleType, ruleType)
for each rule in rules
    ruleCode = rule.getNamedStringValue(ruleCodeProperty)
    if Len(ruleCode) > 0 then
        model.runMethodOnInst method, rule
    end if
next

    function findModelObject(modelObjectType, model)
        dim inst, instances, obj
        dim part, parts

        set findModelObject = Nothing
        set obj = metis.findInstance(model.uri)
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
            if isEnabled(findModelObject) then
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
                                    if part.type.uri = modelObjectType.uri then
                                        set findModelObject = part
                                        exit for
                                    end if
                                end if
                            next
                            exit for
                        end if
                    end if
                end if
            next
            if isEnabled(findModelObject) then
                exit function
            end if
        end if
        set findModelObject = obj
	end function

