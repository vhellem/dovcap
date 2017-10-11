option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim ccRule
dim obj, objects
dim selected
dim inst

'Initialization
    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    
'stop
    ' Get context instance
    set selected = metis.selectedObjectViews
    if selected.count = 1 then
        set inst = selected(1).instance
        set metis.currentModel.currentInstance = inst
        set metis.currentModel.currentModelView.currentInstanceView = selected(1)
        set ccRule = new CC_Rule
        ccRule.ObjectAspectRatio = 0.3
        call ccRule.execute("Edit")
    end if

' End
