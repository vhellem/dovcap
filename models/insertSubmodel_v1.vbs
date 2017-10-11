option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim workarea, workwindow
dim indx
dim model, modelObj, modelObjView
dim objView, parentView
dim selected
dim method
dim SubmodelUrl
dim CC_Type, CS_type, CE_type, CR_type
dim useCcType
dim ccObj, csObj, ceObj, crObj
dim ccObjView, csObjView, ceObjView, crObjView
dim cvwObjView
dim view, views
dim connector, part, parts
dim found

    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    set CC_type = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
    set CS_type = metis.findType("http://xml.chalmers.se/class/composition_set.kmd#composition_set")
    set CE_type = metis.findType("http://xml.chalmers.se/class/composition_element.kmd#composition_element")
    set CR_type = metis.findType("http://xml.chalmers.se/class/composition_request.kmd#composition_request")
    set useCcType = metis.findType("http://xml.chalmers.se/class/uses_configurable_component.kmd#uses_configurable_component")

    set workarea = currentInstanceView.parent.parent
    indx = workarea.children.count
    set workwindow = workarea.children(indx)

    set currentModel = workwindow.instance.ownerModel
    set metis.currentModel = currentModel

'stop
    set selected = metis.selectedObjectViews
    if selected.count = 1 then
        set crObj = selected(1).instance
        if crObj.type.uri = CR_type.uri then
            set objView = selected(1).parent
            set ceObj = objView.instance
            ' Set submodel context
            set model = contentModel(currentModel, currentModelView, workwindow)
            set modelObj = metis.findInstance(model.uri)
            set modelObjView = modelObj.views(1)
            ' Then find where to insert the submodel
            set parentView = modelObjView.children(1)
            set views = parentView.children
            for each view in views
                if hasInstance(view) then
                    if view.instance.type.uri = CS_type.uri then
                        set csObjView = view
                        exit for
                    end if
                end if
            next
            if isValid(csObjView) then
                ' Has found composition set
                found = false
                set views = csObjView.children
                for each view in views
                    if hasInstance(view) then
                        if view.instance.uri = ceObj.uri then
                            found = true
                            set ceObjView = view
                        end if
                    end if
                next
                if not found then
                    ' Create view of CE
                    set ceObjView = csObjView.newObjectView(ceObj)
                end if
                if isValid(ceObjView) then
                    ' Has found view of composition element
                    found = false
                    set views = ceObjView.children
                    for each view in views
                        if hasInstance(view) then
                            if view.instance.uri = crObj.uri then
                                found = true
                                set crObjView = view
                            end if
                        end if
                    next
                    if not found then
                        ' Create view of CR
                        set crObjView = ceObjView.newObjectView(crObj)
                    end if
'stop
                    if isValid(crObjView) then
                        ' Check if submodel already is inserted
                        ' ....
                        ' If not, load submodel
                        SubmodelUrl = "file:///D|/dag/metismodels/customers/ka/dag/resistive_wire.kmv"
                        call metis.load(SubmodelUrl)
                        'Insert submodel
                        set method = metis.findMethod("http://xml.chalmers.se/methods/cc_methods.kmd#insertSubmodel")
                        call method.setArgument1("SubModelUrl", SubmodelUrl)
                        call method.setArgument1("ParentUri", modelObj.uri)
                        call method.setArgument1("ParentViewUri", crObjView.uri)
                        call model.runMethodOnInst(method, modelObj)
                        ' Find inserted submodel
                        set parts = crObj.parts
                        for each part in parts
                            if part.isConnectorType then
                                set connector = part
                                exit for
                            end if
                        next
                        ' Find  CC object
                        if isValid(connector) then
                            set parts = connector.parts
                            for each part in parts
                                if part.type.uri = CC_type.uri then
                                    set ccObj = part
                                    exit for
                                end if
                            next
                        end if
                        ' Connect relationship from CR to CC
                        if isEnabled(ccObj) then
                            call model.newRelationship(useCcType, crObj, ccObj)
                            ' Create view of CC object
                            set cvwObjView = new CVW_ObjectView
                            set ccObjView = cvwObjView.create(workwindow, objView, ccObj, 1)
                        end if
                    end if
                end if
            end if
        else
            call MsgBox("Creating the object violates a language rule!", vbExclamation)
        end if
    end if

' End

'-----------------------------------------------------------
    Function contentModel(model, modelView, window)           'IMetisObject
        dim context

        ' Find ContentModel
        if isValid(window) then
            set contentModel = model
            set context = new EKA_Context
            set context.currentModel        = model
            set context.currentModelView    = modelView
            set context.currentInstance     = window.instance
            set context.currentInstanceView = window
            if isValid(context) then
                if isEnabled(context.contentModel) then
                    set contentModel = context.contentModel
                end if
            end if
            set context = Nothing
        end if
    End Function



' End
