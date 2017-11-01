option explicit
dim model, modelView, inst, instView
dim workwindow, ruleView
dim ccRule

' Starts on Rule object

set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView
'if instView.children.count = 0 then

'stop

    set workwindow = findWorkWindowView(instView)
    set ccRule = new CC_Rule
    set ccRule.currentModel        = model
    set ccRule.currentModelView    = modelView
    set ccRule.currentInstance     = inst
    set ccRule.currentInstanceView = instView
    set ruleView = ccRule.populateRule(workwindow, inst, true)
    instView.open
    set ccRule = Nothing
'end if

