option explicit

dim model, obj, modelObj

set model = metis.currentModel
set obj = model.currentInstance
set modelObj = metis.findInstance(model.uri)
set obj.parent = modelObj

