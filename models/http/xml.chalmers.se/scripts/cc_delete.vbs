option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim hasInstanceContext2Type
dim wObject, workwindow, contentModel
dim noInstances
dim context, instContexts
dim rel
dim answer

'Initialization
set currentModel        = metis.currentModel
set currentModelView    = currentModel.currentModelView
set currentInstance     = currentModel.currentInstance
set currentInstanceView = currentModelView.currentInstanceView
set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

'stop

set workwindow          = findWorkWindowView(currentInstanceView)
set contentModel        = currentModel

if isValid(workwindow) then
    set wObject = workwindow.instance
    ' Check instance context
    set instContexts = wObject.getNeighbourRelationships(0, hasInstanceContext2Type)
    if instContexts.count > 0 then
        set rel = instContexts(1)
        if isEnabled(rel) then
            set context = rel.target
            set contentModel = context.ownerModel
        end if
    end if
    if not isEnabled(contentModel) then
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
    dim ccParamType, ccValueType
    dim ruleType
    dim skipParameters, noDelete
    dim objType

    set ccParamType = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")
    set ccValueType = metis.findType("http://xml.chalmers.se/class/cc_value.kmd#CC_value")
    set ruleType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")

    skipParameters = false

'stop
    countInstances = 0
    if instView.instance.type.uri = ruleType.uri then
        skipParameters = true
    end if
    set children = instView.children
    if children.count > 0 then
        for each child in children
            noDelete = false
            if hasInstance(child) then
                if skipParameters then
                    set objType = child.instance.type
                    if objType.inherits(ccParamType) or objType.inherits(ccValueType) then
                        noDelete = true
                    end if
                end if
                if not noDelete then
                    countInstances = countInstances + countInstances(child)
                end if
            end if
        next
    end if
    countInstances = countInstances + 1
End Function

Sub deleteInstance(instView, modelView, model)
    dim child, children
    dim ccParamType, ccValueType
    dim ruleType
    dim objType
    dim skipParameters, noDelete

    set ccParamType = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")
    set ccValueType = metis.findType("http://xml.chalmers.se/class/cc_value.kmd#CC_value")
    set ruleType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")

    skipParameters = false

    set children = instView.children
    if children.count > 0 then
        if instView.instance.type.uri = ruleType.uri then
            skipParameters = true
        end if
        for each child in children
            noDelete = false
            if hasInstance(child) then
                if skipParameters then
                    set objType = child.instance.type
                    if objType.inherits(ccParamType) or objType.inherits(ccValueType) then
                        noDelete = true
                    end if
                end if
                if not noDelete then
                    call deleteInstance(child, modelView, model)
                end if
            end if
        next
    end if
    call model.deleteObject(instView.instance)
    call modelView.deleteObjectView(instView)
End Sub

