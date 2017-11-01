option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class EKA_Context

    Public contextMode                      ' String
    Public modelViewName                    ' String
    Public modelObjectType                  ' IMetisType
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

    Private model
    Private modelView
    Private contextType                     ' IMetisType
    Private propertyType                    ' IMetisType
    Private hasPropertyType                 ' IMetisType
    Private hasModelContextType             ' IMetisType
    Private specContainerType               ' IMetisType
    Private windowType                      ' IMetisType
    Private window2Type                     ' IMetisType
    Private is_repository                   ' Boolean

   '---------------------------------------------------------------------------------------------------
    Public Property Get contentModel
        set contentModel = getContentModel
    End Property

   '---------------------------------------------------------------------------------------------------
    Public Property Get modelObject
        dim contModel

        set modelObject = Nothing
        set contModel   = getContentModel
        if isEnabled(contModel) then
            set modelObject = metis.findInstance(contModel.uri)
        end if
    End Property

'-----------------------------------------------------------------
    Public Property Get isRepository
        isRepository = is_repository
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

'-----------------------------------------------------------------
    Private Function getContentModel()
        dim modelUri
        dim context, contexts
        dim prop, properties
        dim modelObjectTypeUri
        dim parentModel, instModel
        dim contextCont, contextConts
        dim contextContView
        dim child, children
        dim wObject

        set getContentModel = Nothing

        set wObject = findWorkWindow(currentInstanceView)
        if isEnabled(wObject) then
            set parentModel = wObject.ownerModel
            set contextConts = wObject.getNeighbourObjects(0, hasModelContextType, specContainerType)
            if contextConts.count > 0 then
                set contextCont = contextConts(1)
            end if
        else
            set parentModel = metis.currentModel
        end if

        if isEnabled(contextCont) then
            set contextContView = contextCont.views(1)
            set children = contextContView.children
            if isValid(children) then
                for each child in children
                    if hasInstance(child) then
                        if child.instance.type.uri = contextType.uri then
                            set context = child.instance
                            exit for
                        end if
                    end if
                next
            end if
        end if

        if isEnabled(context) then
            set properties = context.getNeighbourObjects(0, hasPropertyType, propertyType)
            for each prop in properties
                if prop.title = "ContextMode" then
                    contextMode = prop.getNamedStringValue("value")
                elseif prop.title = "ContentModelView" then
                    modelViewName = prop.getNamedStringValue("value")
                elseif prop.title = "ModelObjectType" then
                    modelObjectTypeUri = prop.getNamedStringValue("value")
                    if Len(modelObjectTypeUri) > 0 then
                        set modelObjectType = metis.findType(modelObjectTypeUri)
                    end if
                end if
            next
            select case contextMode
            case "CurrentModel"
                ' Model object is returned
                if isEnabled(modelObjectType) then
                    set getContentModel = findModelObject(parentModel, modelObjectType)
                end if
            case "SubModel"
                ' Model is returned
                if Len(modelViewName) > 0 then
                    set instModel = findInstModel(contextMode, modelViewName)
                else
                    set instModel = getInstModel(contextMode, "")
                end if
                if isEnabled(instModel) then
                    set getContentModel = instModel
                else
                    set getContentModel = parentModel
                end if
            case "Repository"
                ' Model object is returned
                if isEnabled(modelObjectType) then
                    set getContentModel = findModelObject(parentModel, modelObjectType)
                    is_repository = true
                end if
            end select
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
        set hasModelContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext_UUID")
        set specContainerType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set windowType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set window2Type         = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")
        is_repository = false
    End Sub

End Class

