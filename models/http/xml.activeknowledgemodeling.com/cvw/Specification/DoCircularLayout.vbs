option explicit
dim model, modelView
dim inst, instView
dim workarea
dim child, children
dim cvwCircularLayout

' Get context variables
set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView

' Get workarea
set workarea = instView.parent
' Clean workarea view
set children = workarea.children
for each childView in children
    modelView.deleteObjectView(childView)
next

' Do the circular layout
set cvwCircularLayout = new CVW_CircularLayout
call cvwCircularLayout.build
call cvwCircularLayout.execute(workarea, inst)

