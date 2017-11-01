option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Object

    Public  object
    Public  objectView

    Public  ModelContext            ' String
    Public  ModelViewName           ' String
    Public  ModelType               ' String

    Private model
    Private modelView
    Private modlType


'-----------------------------------------------------------
    Public Sub relocateToModel
        dim relocated

        if modelObject.ownerModel.uri = model.uri then
            if isEnabled(object) then
                set object.parent = modelObject
            end if
        else
            ' Instance and view models are not in the same file
            ' Create new element and copy property values
            set relocated = modelObject.newPart(object.type)
            call copyPropertyValues(object, relocated)
            call objectView.setInstance(relocated)
            model.deleteObject(object)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub connectViewAsChild
    End Sub

'-----------------------------------------------------------
    Public Property  Get modelObject
        dim modlType, instModel

        if Len(ModelType) > 0 then
            set modlType = metis.findType(ModelType)
        end if
        if ModelContext = "SubModel" then
            if Len(ModelViewName) > 0 then
                set instModel = findInstModel(ModelContext, modelViewName)
            else
                set instModel = getInstModel(ModelContext, "")
            end if
            if isEnabled(instModel) then
                set modelObject = findModelObject(instModel, modlType)
            end if
        elseif ModelContext = "ContainerType" then
            if Len(ModelType) > 0 then
                set modlType = metis.findType(ModelType)
                if isEnabled(modlType) then
                    set modelObject = findModelObject(model, modlType)
                end if
            end if
        else
            set modelObject = findModelObject(model, modlType)
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
        set object     = model.currentInstance
        set objectView = modelView.currentInstanceView
    End Sub

End Class

