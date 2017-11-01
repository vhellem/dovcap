' Calculate method
' contextInst is the CC

    ' Initialize
    set ccGlobals = new CC_Globals
    set ccGlobals = Nothing
    set model = metis.currentModel
    set currentInst  = model.currentInstance
    instUri = currentInst.getNamedStringValue("externalID")
    if Len(instUri) > 0 then
        set inst = metis.findInstance(instUri)
'stop
        set instModel = inst.parent
        set rels = inst.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
        if rels.count > 0 then set reqType = rels(1).target
        if isValid(reqType) then
            set rels = reqType.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
            if rels.count > 0 then set instType = rels(1).target

            ' Get rules on instType
            private ccRuleEngine
            set rules = instType.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
            if rules.count > 0 then
                for each rule in rules
                    if not isValid(ccRuleEngine) then set ccRuleEngine = new CC_RuleEngine
                    if ccRuleEngine.isCalculatingRule(rule) then
                        found = false
                        set rels = inst.getNeighbourRelationships(0, GLOBAL_Type_invokes)
                        for each rel in rels
                            if rel.target.uri = rule.uri then
                                found = true
                                exit for
                            end if 
                        next
                        if not found then
                            ' Connect invokeRel from inst to rule
                            set model = inst.ownerModel
                            set rel = model.newRelationship(GLOBAL_Type_invokes, inst, rule)
                        end if
                    end if
                next
                ruleStatus = true
                for i = 1 to 1
                    for each rule in rules
'stop
                        if not isValid(ccRuleEngine) then set ccRuleEngine = new CC_RuleEngine
                        call ccRuleEngine.executeRule(inst, rule, ccRuleEngine.MODE_EXECUTE)
                        ruleStatus = inst.getNamedValue("ruleStatus").getInteger
                    next
                    if ruleStatus = false then exit for
                next
            end if
        end if

        set ccInstanceType = new CC_InstanceType
        set ccInstanceType.typeModel = model
        set ccInstanceType.instanceModel = instModel
        set ccInstanceType.productType = GLOBAL_Type_CO
        set ccInstanceType.productInstType = GLOBAL_Type_Requirement
        if Len(GLOBAL_CC_CurrentRole) > 0 then
            ccInstanceType.parameterRule = "Refresh"
        end if
        call ccInstanceType.updateViewInstance(ccObject, inst, Nothing, instModel, 0)
    end if

