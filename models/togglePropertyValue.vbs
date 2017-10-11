option explicit

dim currentModel, currentModelView
dim currentInstance
dim actionType, conditionType

dim propName
'dim propValues()
dim noPropValues

set currentModel    = metis.currentModel
set currentInstance = currentModel.currentInstance
set actionType      = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#action")
set conditionType   = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")

'stop

if currentInstance.type.uri = conditionType.uri then
    propName     = "operator"
    noPropValues = 5
    ReDim Preserve propValues(noPropValues)
    propValues(1) = "AND"
    propValues(2) = "OR"
    propValues(3) = "NOT"
    propValues(4) = "TRUE"
    propValues(5) = "FALSE"
elseif currentInstance.type.uri = actionType.uri then
    propName     = "operation"
    noPropValues = 3
    ReDim Preserve propValues(noPropValues)
    propValues(1) = "includeInConfiguration"
    propValues(2) = "excludeFromConfiguration"
    propValues(3) = "setParameterValue"
end if

call togglePropertyValue(currentInstance, propName, noPropValues, propValues)

' End

Sub togglePropertyValue(inst, propName, noPropValues, propValues)
    dim i, propVal

    propVal = inst.getNamedStringValue(propName)
    for i = 1 to noPropValues
        if propValues(i) = propVal then
            if i = noPropValues then
                call inst.setNamedStringValue(propName, propValues(1))
            else
                call inst.setNamedStringValue(propName, propValues(i+1))
            end if
            exit for
        end if
    next
End Sub

