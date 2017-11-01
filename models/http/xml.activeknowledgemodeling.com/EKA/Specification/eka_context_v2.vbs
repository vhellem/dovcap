option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class EKA_Context

    Public contextMode                      ' String
    Public modelViewName                    ' String
    Public modelObjectType                  ' IMetisType
    Public operationModelViewName           ' String
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

    Private model
    Private modelView
    Private contextType                     ' IMetisType
    Private propertyType                    ' IMetisType
    Private hasPropertyType                 ' IMetisType
    Private modelObject                     ' IMetisInstance

   '---------------------------------------------------------------------------------------------------
    Public Property Get contentModel
        set contentModel = getContentModel
    End Property

   '---------------------------------------------------------------------------------------------------
    Private Function getParentModel
        dim child, children
        dim part, parentInst

        set getParentModel = currentModel
        if isEnabled(currentModelView) then
            ' Find parent model
            set children = currentModelView.children
            if children.count > 0 then
                for each child in children
                    if hasInstance(child) then
                        set part = child.instance
                        if isEnabled(part) then
                            set getParentModel = part.ownerModel
                            exit for
                        end if
                    end if
                next
            end if
        end if
    End Function

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

'-----------------------------------------------------------------
    Private Function getContentModel()
        dim modelUri
        dim context, contexts
        dim prop, properties
        dim modelObjectTypeUri
        dim parentModel, instModel

        set getContentModel = Nothing
        set parentModel = currentModel 'getParentModel
        if isEnabled(parentModel) then
            set contexts = parentModel.findInstances(contextType, "", "")
            if isValid(contexts) then
                set contexts = instancesInModel(contexts, parentModel)
            end if
            for each context in contexts
                if isEnabled(context) then
                    set properties = context.getNeighbourObjects(0, hasPropertyType, propertyType)
                    for each prop  in properties
                        if prop.title = "ContextMode" then
                            contextMode = prop.getNamedStringValue("value")
                        elseif prop.title = "ContentModelView" then
                            modelViewName = prop.getNamedStringValue("value")
                        elseif prop.title = "OperationModelView" then
                            operationModelViewName = prop.getNamedStringValue("value")
                        elseif prop.title = "ModelObjectType" then
                            modelObjectTypeUri = prop.getNamedStringValue("value")
                            if Len(modelObjectTypeUri) > 0 then
                                set modelObjectType = metis.findType(modelObjectTypeUri)
                            end if
                        end if
                    next
                    if Len(operationModelViewName) > 0 then
                        if currentModelView.title <> operationModelViewName then
                            exit for
                        end if
                    end if
                    select case contextMode
                    case "CurrentModel"
                        if isEnabled(modelObjectType) then
                            set getContentModel = findModelObject(parentModel, modelObjectType)
                        end if
                    case "SubModel"
                        if Len(modelViewName) > 0 then
                            set instModel = findInstModel(contextMode, modelViewName)
                        else
                            set instModel = getInstModel(contextMode, "")
                        end if
                        if isEnabled(instModel) then
                            if isEnabled(modelObjectType) then
                                set getContentModel = findModelObject(instModel, modelObjectType)
                            else
                                set getContentModel = metis.findInstance(instModel.uri)
                            end if
                        else
                            set getContentModel = metis.findInstance(parentModel.uri)
                        end if
                    end select
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()

        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set contextType         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_context.kmd#ObjType_EKA:Context_UUID")
        set propertyType        = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType     = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")

    End Sub

End Class

