option explicit
on error resume next

dim model, modelView, inst, instView, symbol1, symbol2
'stop
set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView

symbol1 = instView.openSymbol
symbol2 = instView.closedSymbol

if symbol1 <> symbol2 then
    call inst.setNamedStringValue("symbol", symbol1)
    call metis.refreshMacros(modelView)
else
    dim symbolUri
    symbolUri = inst.getNamedStringValue("symbol")
    if Len(symbolUri) > 0 then instView.openSymbol = symbolUri
end if

