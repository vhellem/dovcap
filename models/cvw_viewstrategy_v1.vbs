option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewStrategy

    Public  title

    Private model
    Private modelView
    Private noHierarchyRules
    Private hierarchyRules()
    
'-----------------------------------------------------------
    Public Sub build(specObject)

        ' Build code

    End Sub

'-----------------------------------------------------------
    Public Sub addHierarchyRule(rule)
        dim cvwRule
        dim indx, found

        found = false
        for indx = 1 to noHierarchyRules
            set cvwRule = hierarchyRules(indx)
            if not cvwRule is Nothing then
                if cvwRule.title = rule.title then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noHierarchyRules = noHierarchyRules + 1
            ReDim Preserve hierarchyRules(noHierarchyRules)
            set hierarchyRules(noHierarchyRules) = rule
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set model = metis.currentModel
        set modelView = model.currentModelView
        noHierarchyRules = 0
        ReDim hierarchyRules(noHierarchyRules)
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

