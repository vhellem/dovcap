option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Filter

    ' Variant parameters
    Public Title                          ' String


'-----------------------------------------------------------
    Public Function instIsValid(inst, rules, noRules)
        dim rule
        dim propname, operator, value
        dim i

        instIsValid = true
        for i = 1 to noRules
            set rule = rules(i)
            propName = rule.propName
            operator = rule.operator
            value = rule.propValue
            if not valueIsValid(inst, propName, operator, value) then
                instIsValid = false
                exit function
            end if
        next
    End Function

'-----------------------------------------------------------
    Public Function valueIsValid(inst, propName, operator, value)
        dim propValue, numValue, stringValue, strValue
        dim isNumber, number

        on error resume next
        valueIsValid = false
        if Len(propName) = 0 then
            valueIsValid = true
            exit function
        end if
        set propValue = inst.getNamedValue(propName)
        if not isValid(propValue) then
            valueIsValid = true
            exit function
        end if
        if propValue.isInteger then
            isNumber = true
            numValue = propValue.getInteger
            if value = "true" then 
                value = "1"
            elseif value = "false" then
                value = "0"
            end if
            number = CInt(value)
        elseif propValue.isFloat then
            isNumber = true
            numValue = propValue.getFloat
            number = CDbl(value)
        else
            isNumber = false
            stringValue = propValue.getString
        end if
        if isNumber then
            select case operator
            case "lt"
                if numValue < number then
                    valueIsValid = true
                end if
            case "le"
                if numValue <= number then
                    valueIsValid = true
                end if
            case "eq"
                if numValue = number then
                    valueIsValid = true
                end if
            case "ne"
                if numValue <> number then
                    valueIsValid = true
                end if
            case "ge"
                if numValue >= number then
                    valueIsValid = true
                end if
            case "gt"
                if numValue > number then
                    valueIsValid = true
                end if
            end select
        else
            select case operator
            case "eq"
                if stringValue = value then
                    valueIsValid = true
                end if
            case "ne"
                if stringValue <> value then
                    valueIsValid = true
                end if
            end select
        end if

    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

