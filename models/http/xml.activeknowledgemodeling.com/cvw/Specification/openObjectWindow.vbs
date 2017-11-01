option explicit

dim model, inst
dim cvwTask

set model = metis.currentModel
set inst  = model.currentInstance

set cvwTask = new CVW_Task

call cvwTask.openEditParametersWindow(inst)

set cvwTask = Nothing

' End

