option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim workwindow, contentModel
dim noInstances
dim context
dim answer

'Initialization
set currentModel        = metis.currentModel
set currentModelView    = currentModel.currentModelView
set currentInstance     = currentModel.currentInstance
set currentInstanceView = currentModelView.currentInstanceView

'stop

set workwindow          = findWorkWindowView(currentInstanceView)
set contentModel        = currentModel

if isValid(workwindow) then
    ' Find ContentModel
    set context = new EKA_Context
    set context.currentModel        = currentModel
    set context.currentModelView    = currentModelView
    set context.currentInstance     = workWindow.instance
    set context.currentInstanceView = workWindow
    if isValid(context) then
        set contentModel = context.contentModel
    end if
    set context = Nothing
end if
' Give the user warning
noInstances = countInstances(currentInstanceView)
if noInstances > 0 then
    answer = MsgBox(noInstances & " objects have been marked for deletion. In addition comes connected relationships!" & vbCrLf & vbCrLf & "Do you really want to delete?", vbOKCancel + vbExclamation)
    if answer = vbOK then
        ' Do the delete
        if currentInstance.isObject then
            call deleteInstance(currentInstanceView, currentModelView, currentModel)
        else
            call model.deleteRelationship(currentInstance)
            call modelView.deleteRelationshipView(currentInstanceView)
        end if
    end if
end if

Function countInstances(instView)
    dim child, children

    countInstances = 0
    set children = instView.children
    if children.count > 0 then
        for each child in children
            if hasInstance(child) then
                countInstances = countInstances(child)
            end if
        next
    end if
    countInstances = countInstances + 1
End Function

Sub deleteInstance(instView, modelView, model)
    dim child, children

    set children = instView.children
    if children.count > 0 then
        for each child in children
            if hasInstance(child) then
                call deleteInstance(child, modelView, model)
            end if
        next
    end if
    call model.deleteObject(instView.instance)
    call modelView.deleteObjectView(instView)
End Sub

