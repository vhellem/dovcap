option explicit

dim model, modelObject, ownerModel, modelView
dim parentInst, inst, instView, obj, relship
dim context, contextObj
dim isModel
dim specContainerType, hasViewStrategyType, isTopType
dim hasInstanceContextType, hasInstanceContext2Type
dim specObject, specObjects
dim wObject, wObjectView
dim strategyCont, strategyConts
dim cvwViewStrategy, rule
dim instContext, instContexts
dim rel, rels, relType
dim i

' Context
set model       = metis.currentModel
set modelView   = model.currentModelView
set inst        = metis.currentModel.currentInstance
set instView    = modelView.currentInstanceView
set wObject     = findWorkWindow(instView)
set wObjectView = findWorkWindowView(instView)

set cvwObject = new CVW_Object
set cvwObject.workWindow = workwindow
set obj = cvwObject.newObject
set cvwObject = Nothing

