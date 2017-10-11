    option explicit

    dim parentView, workWindow
    dim cvwWorkspace, ccRule
    dim workarea, workareas
    dim obj, indx
    dim objectView, objectViews
    dim didSomething

    didSomething = false
    set cvwWorkspace = new CVW_Workspace
    call cvwWorkspace.build
    set parentView = cvwWorkspace.WorkspaceWindow
    if isValid(parentView) then
        set ccRule = new CC_Rule
        set workareas = parentView.children
        for each workarea in workareas
            indx = workarea.children.count
            if indx > 0 then
                set workWindow = workarea.children(indx)
                if isValid(workWindow) then
                    set objectViews = workWindow.children
                    if isValid(objectViews) then
                        for each objectView in objectViews
                            if hasInstance(objectView) then
                                set obj = objectView.instance
                                call ccRule.transformRulesToScripts(obj)
                                call ccRule.ruleEngine.executeRules(obj)
                                didSomething = true
                            end if
                        next
                    end if
                end if
            end if
        next
        set ccRule = Nothing
    end if
    if didSomething then
        MsgBox "Configuration done!"
    else
        MsgBox "Nothing was configured!"
    end if
    set cvwWorkspace = Nothing

