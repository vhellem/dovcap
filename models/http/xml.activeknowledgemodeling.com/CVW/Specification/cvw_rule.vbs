option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Rule


    ' Variant parameters
    Public Title                        ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    
    ' Types
    Private ruleType
    Private isSubjectToType

'-----------------------------------------------------------
    Private Function findRule
        dim rule, rules

        set findRule = Nothing
        set rules = wObject.getNeighbourObjects(0, isSubjectToType, ruleType)
        if isValid(rules) then
            set findRule = rules(1)
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set workWindow          = currentInstanceView
        
        ' Types
        set ruleType        = metis.findType("")
        set isSubjectToType = metis.findType("")
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

