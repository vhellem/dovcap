option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim workarea, workwindow
dim cvwObject
dim obj

'Initialization
set currentModel        = metis.currentModel
set currentModelView    = currentModel.currentModelView
set currentInstance     = currentModel.currentInstance
set currentInstanceView = currentModelView.currentInstanceView
set workarea            = currentInstanceView.parent.parent
set workwindow          = workarea.children(2)

'stop
' Create object
set cvwObject = new CVW_Object
set cvwObject.workWindow = workwindow
cvwObject.nestedTextFactor = 1.75
cvwObject.treeTextFactor = 1
set obj = cvwObject.newObject
set cvwObject = Nothing

