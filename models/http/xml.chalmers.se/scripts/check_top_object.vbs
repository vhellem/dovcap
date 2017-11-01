option explicit

dim model, modelObj, parent
dim modelView, instView, parentView
dim geo, instGeo, parentGeo
dim pnt, size

set model = metis.currentModel
set modelObj = metis.findInstance(model.uri)

set modelView = model.currentModelView
set instView = modelView.currentInstanceView
set parentView = instView.parent
set parent = parentView.instance
'--------------------
if parentView.instance.uri = modelObj.uri then
   msgbox "Current object is Top object!"
end if


