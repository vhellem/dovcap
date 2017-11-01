option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Context

    Public  ContextMode             ' String
    Public  ContextArg1             ' String
    Public  ContextArg2             ' String

    Private model
    Private modelView
    Private modlType


'-----------------------------------------------------------
    Public Property  Get modelObject
        dim modelType, instModel

        if ContextMode = "SubModel" then
            if Len(ContextArg1) > 0 then  
                ' ContextArg1 = ModelViewName
                set instModel = findInstModel(ContextMode, ContextArg)
            else
                set instModel = getInstModel(ContextMode, "")
            end if
            if isEnabled(instModel) then
                if Len(ContextArg2) > 0 then  
                    ' ContextArg2 = ModelObjectType
                    set modelType = metis.findType(ContextArg2)
                    if isEnabled(modelType) then
                        set modelObject = findModelObject(instModel, modelType)
                    end if
                else
                    set modelObject = metis.findInstance(instModel.uri)
                end if
            end if
        elseif ContextMode = "CurrentModel" then
            if Len(ContextArg2) > 0 then
                ' ContextArg2 = ModelObjectType
                set modelType = metis.findType(ContextArg2)
                if isEnabled(modelType) then
                    set modelObject = findModelObject(model, modelType)
                end if
            end if
        end if
        if not isEnabled(modelObject) then
            set modelObject = metis.findInstance(model.uri)
        end if
    End Property


'-----------------------------------------------------------------
    Private Function findModelObject(instModel, modelObjectType)
        dim inst, instances, obj

        set findModelObject = Nothing
        set obj = metis.findInstance(instModel.uri)
        set instances = obj.parts
        for each inst in instances
            if isEnabled(inst) then
                if inst.type.uri = modelObjectType.uri then
                    set findModelObject = inst
                    exit for
                end if
            end if
        next
        if not isEnabled(findModelObject) then
            set findModelObject = metis.findInstance(instModel.uri)
        end if
    End function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model      = metis.currentModel
        set modelView  = model.currentModelView
    End Sub

End Class

