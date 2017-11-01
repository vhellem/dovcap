option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_InstRule
    Public title
    Public instType
    Public propname
    Public propvalue
    Public operator

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        title = "InstRule"
        set instType  = Nothing
        propname  = ""
        propvalue = ""
        operator  = ""
    End Sub

End Class

'-----------------------------------------------------------

'-----------------------------------------------------------
Class CVW_RelRule
    Public title
    Public parentType
    Public relType
    Public childType
    Public relDir

'-----------------------------------------------------------
    Public Function isAllowed(rel, rule)

        isAllowed = false
        if isEnabled(rel) and isValid(rule) then
            if rel.type.uri = relType.uri then
                if rule.relDir = 0 then
                    if rel.origin.type.uri = rule.parentType.uri then
                        if rel.target.type.uri = rule.childType.uri then
                            isAllowed = true
                        end if
                    end if
                else
                    if rel.target.type.uri = rule.parentType.uri then
                        if rel.origin.type.uri = rule.childType.uri then
                            isAllowed = true
                        end if
                    end if
                end if
            end if
        end if

    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        title = "RelRule"
        set parentType = Nothing
        set relType   = Nothing
        set childType = Nothing
        relDir = 0
    End Sub

End Class


