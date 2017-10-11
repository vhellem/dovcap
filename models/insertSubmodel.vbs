option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim workarea, workwindow
dim indx
dim model, modelObj, modelObjView
dim subModel
dim objView, parentView
dim selected
dim CC_Type, CR_type
dim useCcType
dim ccObj, crObj
dim rel
dim ccObjView
dim cvwObjView
dim view, views
dim part, parts
dim found

    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    set CC_type = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
    set CR_type = metis.findType("http://xml.chalmers.se/class/composition_request.kmd#composition_request")
    set useCcType = metis.findType("http://xml.chalmers.se/class/uses_configurable_component.kmd#uses_configurable_component")

    set workarea = currentInstanceView.parent.parent
    indx = workarea.children.count
    set workwindow = workarea.children(indx)

'stop
    set selected = metis.selectedObjectViews
    if selected.count = 1 then
        set crObj = selected(1).instance
        if crObj.type.uri = CR_type.uri then
            set objView = selected(1)
            ' Find ccObj
            set model = getContentModel(currentModel, currentModelView, workwindow, false)
            set subModel = getContentModel(currentModel, currentModelView, workwindow, true)
            if isValid(subModel) then
                set metis.currentModel = model
                set parts = subModel.parts
                for each part in parts
                    if part.type.inherits(CC_type) then
                        set ccObj = part
                        exit for
                    end if
                next
                ' Connect relationship from CR to CC
                if isEnabled(ccObj) then
                    set rel = model.newRelationship(useCcType, crObj, ccObj)
                    ' Create view of CC object
                    set cvwObjView = new CVW_ObjectView
                    set ccObjView = cvwObjView.create(workwindow, objView, ccObj, 1)
                    objView.open
                else
                    call MsgBox("An error occurred when trying to connect to submodel")
                end if
            end if
        else
            call MsgBox("Creating the object violates a language rule!", vbExclamation)
        end if
    end if

' End

'-----------------------------------------------------------
    Function getContentModel(model, modelView, window, forceSearch)           'IMetisObject
        dim context, contextModel

        set getContentModel = Nothing
        ' Find ContentModel
        if isValid(window) then
            set getContentModel = model
            set context = new EKA_Context
            set context.currentModel        = model
            set context.currentModelView    = modelView
            set context.currentInstance     = window.instance
            set context.currentInstanceView = window
            context.forceSearch = forceSearch
            if isValid(context) then
                set contextModel = context.contentModel
                if isValid(contextModel) then
                    set getContentModel = contextModel
                end if
            end if
            set context = Nothing
        end if
    End Function



' End
