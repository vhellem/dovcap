option explicit

    dim currentModel, currentInstance
    dim ccRuleEngine

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

'stop

    ' Execute rule
    set ccRuleEngine = new CC_RuleEngine
    call ccRuleEngine.executeRules(currentInstance, 1)
    set ccRuleEngine = Nothing


