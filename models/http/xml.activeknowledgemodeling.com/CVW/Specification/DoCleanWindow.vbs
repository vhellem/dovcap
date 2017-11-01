option explicit

dim model, modelView, inst, instView
dim objectView, selected
dim workarea, workwindow
dim indx
dim done

    set model = metis.currentModel
    set modelView = model.currentModelView
    set inst = model.currentInstance
    set instView = modelView.currentInstanceView

    set workarea = instView.parent.parent
    indx = workarea.children.count
    set workwindow = workarea.children(indx)

    done = false
    set selected = metis.selectedObjectViews
    if selected.count > 0 then
        for each objectView in selected
            if isInView(objectView, workwindow) then
                call modelView.deleteObjectView(objectView)
                done = true
            end if
        next
    end if
    if not done then
        for each objectView in workwindow.children
            call modelView.deleteObjectView(objectView)
        next
    end if

' End

