option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Instance

    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

    Private anyObjectType
    Private windowType
    Private isInstanceType

'-----------------------------------------------------------
    Public Sub showProperties
        dim selected
        dim m, indx
        dim workarea, workwindow, wObject
        dim obj, objects
        dim objViews, objView
        dim created

        ' Assume started on Property button on titlebar
        set workarea = currentInstanceView.parent.parent
        indx = workarea.children.count
        set workwindow = workarea.children(indx)
        set selected = metis.selectedObjectViews
        if selected.count = 1 then
            if isInView(selected(1), workwindow) then
                set metis.currentModel.currentInstance = selected(1).instance
                set metis.currentModel.currentModelView.currentInstanceView = selected(1)
                call metis.runCommand("properties")
                exit sub
            end if
        elseif selected.count > 1 then
            call metis.runCommand("object-property-list")
            exit sub
        end if
        if true then
            set wObject = workwindow.instance
            if isEnabled(wObject) then
                set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
                if isValid(objects) then
                    if objects.count > 0 then
                        for each obj in objects
                            if isEnabled(obj) then
                                ' Ensure object view exists
                                created = false
                                set objViews = obj.views
                                if objViews.count = 0 then
                                    set objView = workwindow.newObjectView(obj)
                                    created = true
                                end if
                                if objViews.count > 0 then
                                    set objView = objViews(1)
                                end if
                                ' Set current values
                                set metis.currentModel = obj.ownerModel
                                set metis.currentModel.currentInstance = obj
                                set metis.currentModel.currentModelView.currentInstanceView = objView
                                call metis.runCommand("properties")
                                if created then
                                    call currentModelView.deleteObjectView(objView)
                                end if
                                exit for
                            end if
                        next
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Public Function getInstanceName
        dim obj, objects
        dim workarea, workwindow, wObject

        getInstanceName = ""
        ' Assume started on workwindow
        set workwindow = currentInstanceView
        set wObject = workwindow.instance
        if isEnabled(wObject) then
            set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
            if isValid(objects) then
                if objects.count > 0 then
                    for each obj in objects
                        if isEnabled(obj) then
                            getInstanceName = obj.title
                            exit for
                        end if
                    next
                end if
            end if
        end if

    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        set anyObjectType  = metis.findType("metis:stdtypes#oid1")
        set windowType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set isInstanceType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

    End Sub

'-----------------------------------------------------------

End Class

'-----------------------------------------------------------

