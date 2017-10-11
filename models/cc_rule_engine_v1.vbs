option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_RuleEngine

    ' Variant parameters
    Public Title                        ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

    ' Types
    Private anyObjectType
    Private definitionType
    Private valueType
    Private hasDefinitionType
    Private hasValueType

    Private RuleEngineProperty
    Private RuleInitCodeProperty
    Private RuleCodeProperty
    Private RulePostCodeProperty
    Private RuleEvaluatedToProperty
    Private ExprEvaluatedToProperty
    Private CcValueProperty
    Private EkaValueProperty
    Private contextInstance


'-----------------------------------------------------------
    Public Sub includeInConfiguration
        dim myModel, inst
        dim intVal

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "includeInConfiguration => " & inst.title
        set intVal = metis.newValue
        call intVal.setInteger(1)
        call inst.setNamedValue(RuleEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Public Sub excludeFromConfiguration
        dim myModel, inst
        dim intVal

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "excludeFromConfiguration => " & inst.title
        set intVal = metis.newValue
        call intVal.setInteger(0)
        call inst.setNamedValue(RuleEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Public Function getInstanceOf(instUri)
        dim inst

        set getInstanceOf = Nothing
        if Len(instUri) > 0 then
            set inst = metis.findInstance(instUri)
            if isEnabled(inst) then
                set getInstanceOf = inst
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function getValueOf(instUri)
        dim inst

        getValueOf = ""
        if Len(instUri) > 0 then
            set inst = metis.findInstance(instUri)
            if isEnabled(inst) then
                on error resume next
                getValueOf = inst.getNamedStringValue(CcValueProperty)
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function getParameterValue(paramUri)
        dim myModel
        dim inst
        dim ccObj, paramObj
        dim value, values
        dim definition, definitions

        ' Initialization
        getParameterValue = ""
        set myModel     = metis.currentModel
        set inst        = myModel.currentInstance
        set paramObj    = metis.findInstance(paramUri)

        'MsgBox "getParameterValue  => " & inst.title
        ' Main code
        set ccObj = getCCobject(paramObj)
        if isEnabled(ccObj) then
            set values = ccObj.getNeighbourObjects(0, hasValueType, valueType)
            for each value in values
                set definitions = value.getNeighbourObjects(0, hasDefinitionType, anyObjectType)
                for each definition in definitions
                    if definition.uri = paramObj.uri then
                        getParameterValue = value.getNamedStringValue(EkaValueProperty)
                    end if
                next
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub setParameterValue(paramUri, valueUri)
        dim myModel, model
        dim inst
        dim ccObj, paramObj, valueObj
        dim value, values
        dim intVal
        dim definition, definitions
        dim paramValue, newValue
        dim rel
        dim done

        ' Initialization
        set myModel     = metis.currentModel
        set inst        = myModel.currentInstance
        set paramObj    = metis.findInstance(paramUri)
        set valueObj    = metis.findInstance(valueUri)
        newValue        = valueObj.getNamedStringValue(CcValueProperty)

        ' Main code
        set ccObj = getCCobject(paramObj)
        if isEnabled(ccObj) then
            ' MsgBox "setParameterValue  => " & inst.title  & vbCrLf & "ccObj = " & ccObj.title
            done = false
            set values = ccObj.getNeighbourObjects(0, hasValueType, valueType)
            for each value in values
                set definitions = value.getNeighbourObjects(0, hasDefinitionType, anyObjectType)
                for each definition in definitions
                    if definition.uri = paramObj.uri then
                        ' Existing value
                        paramValue = value.getNamedStringValue(EkaValueProperty)
                        if paramValue = newValue then
                            done = true
                            exit for
                        else
                            call value.setNamedStringValue(EkaValueProperty, newValue)
                            done = true
                            exit for
                        end if
                    end if
                next
                if done then exit for
            next
            if not done then
                set value = ccObj.newPart(valueType)
                if isEnabled(value) then
                    call value.setNamedStringValue(EkaValueProperty, newValue)
                    set model = ccObj.ownerModel
                    set rel = model.newRelationship(hasValueType, ccObj, value)
                    set rel = model.newRelationship(hasDefinitionType, value, paramObj)
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Public Function getInputParameter(strName)
        dim inst
        dim myModel
        dim expression, expressions
        dim ccObj, paramObj, paramObjects
        dim paramName
        dim rel, rels
        dim range, ranges
        dim val, sval, value, values
        dim definition, definitions
        dim rmin, rmax, s, text

        ' Initialization
        getInputParameter = 0
        set myModel = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        else
            set expression = inst
        end if
        ' Main code
        if isEnabled(expression) then
            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputTo1)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Parameter object
                    set paramObj = rel.origin
                    set ccObj = getCCobject(paramObj)
                    if isEnabled(ccObj) then
                        set values = ccObj.getNeighbourObjects(0, hasValueType, valueType)
                        for each value in values
                            set definitions = value.getNeighbourObjects(0, hasDefinitionType, anyObjectType)
                            for each definition in definitions
                                if definition.uri = paramObj.uri then
                                    ' Value found, get the value
                                    s = value.getNamedStringValue(EkaValueProperty)
                                    if Len(s) > 0 then
                                        if isNumeric(s) then
                                            val = CDbl(s)
                                            getInputParameter = val
                                        else
                                            getInputParameter = s
                                        end if
                                        exit function
                                    end if
                                    exit for
                                end if
                            next
                        next
                    else
                        ' This is a user input parameter
                        's = paramObj.getNamedStringValue(EkaValueProperty)
                        'if Len(s) > 0 then
                        '    if isNumeric(s) then
                        '        val = CDbl(s)
                        '        getInputParameter = val
                        '    else
                        '        getInputParameter = s
                        '    end if
                        '    exit function
                        'end if
                        ' No value given, ask for it
                        text = "The parameter " & strName & " has no value!" & vbCrLf
                        ' But first check if a range has been defined
                        set ranges = paramObj.parts
                        if ranges.count > 0 then
                            text = text & "The parameter value must be within the range ("
                            for each range in ranges
                                rmin = range.getNamedStringValue("min")
                                text = text & rmin & ", "
                                rmax = range.getNamedStringValue("max")
                                text = text & rmax
                            next
                            text = text & ")" & vbCrLf
                        end if
                        text = text & vbCrLf & "Please enter the value:"
                        sval = InputBox(text)
                        'sval = ""
                        if Len(sval) > 0 then
                            if isNumeric(sval) then
                                val = CDbl(sval)
                                if not isEmpty(rmin) then
                                    if rmin <= val and val <= rmax then
                                        call setParamValue(paramObj, sval)
                                    end if
                                else
                                    call setParamValue(paramObj, sval)
                                end if
                                getInputParameter = val
                            else
                                getInputParameter = sval
                            end if
                        end if
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function getInputParameterValue(strName)
        dim inst
        dim myModel
        dim expression, expressions
        dim ccObj, paramObj, paramObjects
        dim paramName, paramUri
        dim rel, rels, rels2
        dim range, ranges
        dim val, value, values
        dim definition, definitions
        dim rmin, rmax, s, text

        ' Initialization
        getInputParameterValue = 0
        set myModel = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        else
            set expression = inst
        end if
        ' Main code
        if isEnabled(expression) then
            set rels  = expression.getNeighbourRelationships(1, GLOBAL_Type_inputTo2)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Parameter object
                    paramUri = rel.origin.uri
                    s = getValueOf(paramUri)
                    if Len(s) > 0 then
                        if isNumeric(s) then
                            getInputParameterValue = CDbl(s)
                        else
                            getInputParameterValue = s
                        end if
                    end if
                    exit function
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub setOutputParameter(strName, newValue)
        dim myModel, model
        dim inst
        dim expression, expressions
        dim ccObj, paramObj, valueObj
        dim value, values
        dim definition, definitions
        dim paramValue
        dim paramName
        dim rel, rels
        dim done

        ' Initialization
        set myModel     = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        end if
        ' Main code
        if isEnabled(expression) then
            set rels = expression.getNeighbourRelationships(0, GLOBAL_Type_outputTo)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Get value of parameter
                    set paramObj = rel.target
                    call setParamValue(paramObj, newValue)
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub setCondition(cond)
        dim myModel, inst
        dim intVal, ival

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "includeInConfiguration => " & inst.title
        if cond then
            ival = 1
        else
            ival = 0
        end if
        set intVal = metis.newValue
        call intVal.setInteger(ival)
        call inst.setNamedValue(ExprEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Private Sub setParamValue(paramObj, newValue)
        dim model
        dim ccObj, valueObj
        dim value, values
        dim definition, definitions
        dim paramValue
        dim paramName
        dim rel
        dim done

        ' Main code
        if isEnabled(paramObj) then
            set ccObj = getCCobject(paramObj)
            if isEnabled(ccObj) then
                done = false
                set values = ccObj.getNeighbourObjects(0, hasValueType, valueType)
                for each value in values
                    set definitions = value.getNeighbourObjects(0, hasDefinitionType, anyObjectType)
                    for each definition in definitions
                        if definition.uri = paramObj.uri then
                            ' There is an existing value - replace it with the new value
                            paramValue = value.getNamedStringValue(EkaValueProperty)
                            if paramValue = newValue then
                                done = true
                                exit for
                            else
                                call value.setNamedStringValue(EkaValueProperty, newValue)
                                done = true
                                exit for
                            end if
                        end if
                    next
                    if done then exit for
                next
                if not done then
                    set value = ccObj.newPart(valueType)
                    if isEnabled(value) then
                        call value.setNamedStringValue(EkaValueProperty, newValue)
                        set model = ccObj.ownerModel
                        set rel = model.newRelationship(hasValueType, ccObj, value)
                        set rel = model.newRelationship(hasDefinitionType, value, paramObj)
                    end if
                end if
            else
                call paramObj.setNamedStringValue(EkaValueProperty, newValue)
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Function getCCobject(inst)
        dim model
        dim part, parts
        dim typeUri
        dim paramObj
        dim hasValueType, hasParamType
        dim rel, rels, paramRels
        dim ccRule1

        set getCCobject = Nothing
        if inst.isRelationship then
            set inst = inst.origin
        end if
        if inst.type.uri = GLOBAL_Type_CC.uri then
            set getCCobject = inst
        elseif inst.type.uri = GLOBAL_Type_Rule.uri then
            set rels = inst.getNeighbourRelationships(1, GLOBAL_Type_subjectOf)
            if rels.count > 0 then
                set getCCobject = rels(1).origin
            else
                ' Find the relship that is the subject of the rule
                set ccRule1 = new CC_Rule
                set rel = ccRule.getSubjectOf(inst)
                set ccRule1 = Nothing
                if isEnabled(rel) then
                    set getCCobject = rel.origin
                end if
            end if
        else
            typeUri = inst.type.uri
            if typeUri = GLOBAL_Type_VP.uri or typeUri = GLOBAL_Type_VPV.uri then
                set hasValueType = GLOBAL_Type_hasVPV
                set hasParamType = GLOBAL_Type_hasVP
            elseif typeUri = GLOBAL_Type_FP.uri or typeUri = GLOBAL_Type_FPV.uri then
                set hasValueType = GLOBAL_Type_hasFPV
                set hasParamType = GLOBAL_Type_hasFP
            elseif typeUri = GLOBAL_Type_DP.uri or typeUri = GLOBAL_Type_DPV.uri then
                set hasValueType = GLOBAL_Type_hasDPV
                set hasParamType = GLOBAL_Type_hasDP
            elseif typeUri = GLOBAL_Type_CP.uri or typeUri = GLOBAL_Type_CPV.uri then
                set hasValueType = GLOBAL_Type_hasCPV
                set hasParamType = GLOBAL_Type_hasCP
            elseif typeUri = GLOBAL_Type_PP.uri or typeUri = GLOBAL_Type_PPV.uri then
                set hasValueType = GLOBAL_Type_hasPPV
                set hasParamType = GLOBAL_Type_hasPP
            end if
            if isValid(hasValueType) then
                set paramRels = inst.getNeighbourRelationships(1, hasValueType)
                if paramRels.count > 0 then
                    set paramObj = paramRels(1).origin
                    set rels = paramObj.getNeighbourRelationships(1, hasParamType)
                    if rels.count > 0 then
                        set getCCobject = rels(1).origin
                    end if
                else
                    set rels = inst.getNeighbourRelationships(1, hasParamType)
                    if rels.count > 0 then
                        set getCCobject = rels(1).origin
                    end if
                end if
            end if
            'set model = inst.ownerModel
            'set parts = model.parts
            'for each part in parts
            '    if part.type.uri = ccType.uri then
            '        set getCCobject = part
            '        exit for
            '    end if
            'next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub executeRules(inst, mode)
        dim ccRule1
        dim rule, rules
        dim includeInConfig
        dim included
        dim test

        ' Initialize
        included = true
        test = 1
        ' Execute rules
        set includeInConfig = metis.newValue
        set ccRule1 = new CC_Rule
        set rules = ccRule1.getRules(inst)
        if rules.count > 0 then
            call includeInConfig.setInteger(0)
        end if
        for each rule in rules
            test = executeRule(inst, rule, mode)
            if test = 0 then
                included = false
            end if
        next
        if included then
            call includeInConfig.setInteger(1)
        end if
        call inst.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
        set ccRule1 = Nothing
    End Sub

'-----------------------------------------------------------
    Public Function executeRule(context, ruleObject, mode)
        on error resume next

        dim model
        dim intVal
        dim prop
        dim rule, ruleEngine, ruleKind
        dim includeInConfig
        dim evaluatedTo
        dim text, text1, text2, text3
        dim expression, expressions
        dim isExpression

        ' Initialization
        executeRule = true
        set model = ruleObject.ownerModel
        ruleKind = ruleObject.getNamedStringValue("ruleKind")
        if mode = 1 then ' Configure
            if ruleKind = "Service" then
                exit function
            end if
        elseif mode = 2 then ' Execute service
            if not ruleKind = "Service" then
                exit function
            end if
        end if
        isExpression = false
        if ruleKind = "Expression" or ruleKind = "Service" then
            set expressions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
                isExpression = true
            end if
        end if
        ' Rule execution
        set prop = ruleObject.type.getProperty(RuleEngineProperty)
        if isEnabled(prop) then
            ruleEngine = ruleObject.getNamedValue(RuleEngineProperty).getInteger
            select case ruleEngine
            case 0
                exit function
            case 1
                set includeInConfig = metis.newValue
                if isExpression then
                    call includeInConfig.setInteger(1)
                    call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                    text = "set contextInst = ccRuleEngine.getInstanceOf(" & Chr(34) & context.uri & Chr(34) & ")" & vbCrLf
                    text1 = expression.getNamedValue(RuleInitCodeProperty).getString
                    text2 = expression.getNamedValue(RuleCodeProperty).getString
                    text3 = expression.getNamedValue(RulePostCodeProperty).getString
                    rule = text1 & text & text2 & text3
                    if Len(rule) > 0 then
                        call ruleObject.setNamedStringValue(RuleCodeProperty, rule)
                        call model.runMethodOnInst(GLOBAL_Method_RuleExecute, ruleObject)
                    end if
                else
                    rule = ruleObject.getNamedValue(RuleCodeProperty).getString
                    if Len(rule) > 0 then
                        call includeInConfig.setInteger(0)
                        call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                        call model.runMethodOnInst(GLOBAL_Method_RuleExecute, ruleObject)
                        executeRule = ruleObject.getNamedValue(RuleEvaluatedToProperty).getInteger
                    else
                        call includeInConfig.setInteger(1)
                        call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                    end if
                end if
            end select
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        ' Initialize local variables
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        ' Types
        set definitionType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")
        set valueType         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        set hasDefinitionType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")
        set hasValueType      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set anyObjectType     = metis.findType("metis:stdtypes#oid1")

        ' Model

        ' Variables
        RuleEngineProperty      = "ruleEngine"
        RuleInitCodeProperty    = "ruleInitCode"
        RuleCodeProperty        = "ruleCode"
        RulePostCodeProperty    = "rulePostCode"
        RuleEvaluatedToProperty = "ruleEvaluatedTo"
        ExprEvaluatedToProperty = "expressionEvaluatedTo"
        CcValueProperty         = "name"
        EkaValueProperty        = "value"
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

