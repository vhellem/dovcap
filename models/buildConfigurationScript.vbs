option explicit

dim currentModel, currentInstance
dim r

set currentModel = metis.currentModel
set currentInstance = currentModel.currentInstance


set r = new Rule
r.debug = false
'stop
call r.transformToScript(currentInstance)

set r = Nothing

