option explicit

on error resume next

dim currentModel, currentInstance
dim rule
dim i, lineNo
dim script(), text
dim action, condition
dim actions, ifThens
dim operator, operation
dim outputs
dim inputRel, inputRels
dim paramObj, paramType
dim conditionObj
dim actionType, conditionType
dim hasActionType, ifThenType
dim anyObjectType
dim outputToType, inputToType, inputTo2Type
dim valueObj
dim debug

set currentModel = metis.currentModel
set currentInstance = currentModel.currentInstance


set rule = currentInstance
set actionType       = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#action")
set conditionType    = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")
set inputToType      = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to")
set inputTo2Type     = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_2")
set outputToType     = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#has_output")
set hasActionType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_action")
set ifThenType       = metis.findType("http://xml.chalmers.se/class/rule.kmd#if_then")
set anyObjectType    = metis.findType("metis:stdtypes#oid1")

debug = true

'stop

lineNo = 0
' Find the action
set actions = rule.getNeighbourObjects(0, hasActionType, actionType)
if actions.count > 0 then
    set action = actions(1)
    operation = action.getNamedStringValue("operation")
    if Len(operation) > 0 then
        ReDim Preserve script(lineNo+3)
        lineNo = lineNo + 1
        script(lineNo) = "end if"
        lineNo = lineNo + 1
        script(lineNo) = "    call " & operation
        set outputs = action.getNeighbourObjects(0, outputToType, anyObjectType)
        if outputs.count > 0 then
            set valueObj = outputs(1)
            paramObj = getCcParameterObj(valueObj)
            if debug then
                paramType = getCcParameterType(valueObj)
                script(lineNo) = script(lineNo) & "(" & Chr(34) & paramType & ", " & Chr(34) & paramObj.title & Chr(34) & ", " & Chr(34) & valueObj.title & Chr(34) & ") "
            else
                script(lineNo) = script(lineNo) & "(" & Chr(34) & paramObj.uri & Chr(34) & ", " & Chr(34) & valueObj.uri & Chr(34) & ") "
            end if
        end if



        lineNo = lineNo + 1
        script(lineNo) = "if condition then"
        ' Find the conditions
        ReDim Preserve script(lineNo+3)
        set ifThens = action.getNeighbourObjects(1, ifThenType, conditionType)
        if ifThens.count > 0 then
'stop
            set condition = ifThens(1)
            text = ""
            text = getCondition(condition, text, debug)
        end if
        if Len(text) > 0 then
            text = "condition = " & text & vbCrLf
        end if
        for i = lineNo to 1 step -1
            text = text & script(i) & vbCrLf
        next
        if Len(text) > 0 then
            call rule.setNamedStringValue("description", text)
            MsgBox text
        end if
    end if
 '   stop
end if

    Function getCondition(condition, text, debug)
        dim inputRel, inputRels
        dim valueObj, paramObj
        dim paramType, operator
        dim conditionType, inputToType, inputTo2Type
        dim conditionObj
        dim i

        set conditionType    = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")
        set inputToType      = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to")
        set inputTo2Type      = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_2")

        set inputRels = condition.getNeighbourRelationships(1, inputToType)
        operator = condition.getNamedStringValue("operator")
        if inputRels.count = 0 then
            getCondition = operator
        else
            i = 0
            for each inputRel in inputRels
                i = i + 1
                set valueObj = inputRel.origin
                set paramObj = getCcParameterObj(valueObj)
                if debug then
                    paramType = getCcParameterType(valueObj)
                    text = text & "(getParameterValue(" & Chr(34) & paramType & Chr(34) & ", " & Chr(34) & paramObj.title & Chr(34) & ") = " & Chr(34) & valueObj.title &  Chr(34) & ")"
                else
                    text = text & "(getParameterValue(" & Chr(34) & paramObj.uri & Chr(34) & ") = getValueOf(" & Chr(34) & valueObj.uri &  Chr(34) & "))"
                end if
                if i < inputRels.count then
                    text = text & " " & operator & " "
                end if
            next

            set inputRels = condition.getNeighbourRelationships(1, inputTo2Type)
            ReDim Preserve script(lineNo + inputRels.count)
            for each inputRel in inputRels
                set conditionObj = inputRel.origin
                text = text & " " & operator & " ("
                text = getCondition(conditionObj, text, debug)
                text = text & ")"
            next
            getCondition = text
        end if

    End Function


    Function getCcParameterObj(valueObj)
        dim paramType
        dim hasValueType
        dim hasVPVtype, hasCPVtype, hasFPVtype, hasDPVtype, hasPPVtype
        dim paramObj, paramRels

        set getCcParameterObj = Nothing

        set hasVPVtype = metis.findType("http://xml.chalmers.se/class/has_variant_parameter_value.kmd#has_variant_parameter_value")
        set hasCPVtype = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter_value.kmd#has_constraint_parameter_value")
        set hasFPVtype = metis.findType("http://xml.chalmers.se/class/has_functional_requirement_parameter_value.kmd#has_functional_requirement_parameter_value")
        set hasDPVtype = metis.findType("http://xml.chalmers.se/class/has_design_parameter_value.kmd#has_design_parameter_value")
        set hasPPVtype = metis.findType("http://xml.chalmers.se/class/has_performance_parameter_value.kmd#has_performance_parameter_value")

        paramType = getCcParameterType(valueObj)
        select case paramType
        case "VP"   set hasValueType = hasVPVtype
        case "CP"   set hasValueType = hasCPVtype
        case "FP"   set hasValueType = hasFPVtype
        case "DP"   set hasValueType = hasDPVtype
        case "PP"   set hasValueType = hasPPVtype
        end select
        if isValid(hasValueType) then
            set paramRels = valueObj.getNeighbourRelationships(1, hasValueType)
            if paramRels.count > 0 then
                set paramObj = paramRels(1).origin
                if isEnabled(paramObj) then
                    set getCcParameterObj = paramObj
                end if
            end if
        end if

    End Function

    Function getCcParameterType(valueObj)
        dim vType
        dim vpvType, cpvType, fpvType, dpvType, ppvType

        getCcParameterType = ""

        set cpvType      = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set dpvType      = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set fpvType      = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set ppvType      = metis.findType("http://xml.chalmers.se/class/performance_parameter_value.kmd#performance_parameter_value")
        set vpvType      = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")

        set vType = valueObj.type
        if vType.inherits(vpvType) then
            getCcParameterType = "VP"
        elseif vType.inherits(cpvType) then
            getCcParameterType = "CP"
        elseif vType.inherits(fpvType) then
            getCcParameterType = "FP"
        elseif vType.inherits(dpvType) then
            getCcParameterType = "DP"
        elseif vType.inherits(ppvType) then
            getCcParameterType = "PP"
        end if
    End Function



