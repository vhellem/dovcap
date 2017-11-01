' Select Excel file
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
            i = 1
            for each rule in rules
                filename = ""
                if not ccRuleEngine.isExcelRule(rule, filename) then
                    call rules.removeAt(i)
                else
                    i = i + 1
                end if
            next
            set cvwSelectDialog = new CVW_SelectDialog
            cvwSelectDialog.singleSelect = true
            cvwSelectDialog.title = "Select Excel rule"
            cvwSelectDialog.heading = "Select Excel rule"
            set rules = cvwSelectDialog.show(rules)
        end if
        if rules.count = 1 then
            set rule = rules(1)
            filename = ""
            call ccRuleEngine.isExcelRule(rule, filename) 
            if Len(filename) > 0 then
                filename = metis.urlMakeAbsolute(filename, reqType)
                set cvwExcel = new CVW_Excel
                if not cvwExcel.open(filename, true) then
                    set cvwExcel = Nothing
                end if
            end if
        end if
    end if

