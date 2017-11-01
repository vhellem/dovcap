' Calculate method
' contextInst is the CC

    ' Initialize
    set ccGlobals = new CC_Globals
    set ccGlobals = Nothing
    set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

    set model  = metis.currentModel

    set currentObj = Nothing
    set workWindow = getWorkareaView(getCVWmodel, "Workplace")
    set currentInst = workWindow.children(1).instance

'stop
    set instModel = currentInst.parent
    set rels = currentInst.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
    if rels.count > 0 then set reqType = rels(1).target
    if isValid(reqType) then
        set rels = reqType.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
        if rels.count > 0 then set instType = rels(1).target

        ' Get rules on instType
        set ccRuleEngine = new CC_RuleEngine
        set rules = instType.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
        if rules.count > 0 then
            for each rule in rules
                if ccRuleEngine.isCalculatingRule(rule) then
                        found = false
                        set rels = currentInst.getNeighbourRelationships(0, GLOBAL_Type_invokes)
                        for each rel in rels
                            if rel.target.uri = rule.uri then
                                found = true
                                exit for
                            end if 
                        next
                        if not found then
                            ' Connect invokeRel from currentInst to rule
                            set model1 = currentInst.ownerModel
                            set rel = model1.newRelationship(GLOBAL_Type_invokes, currentInst, rule)
                        end if
                end if
            next
            ruleStatus = true
            for i = 1 to 5
                for each rule in rules
                    call ccRuleEngine.executeRule(currentInst, rule, ccRuleEngine.MODE_EXECUTE)
                    ruleStatus = currentInst.getNamedValue("ruleStatus").getInteger
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
        call ccInstanceType.updateViewInstance(ccObject, currentInst, Nothing, instModel, 0)

