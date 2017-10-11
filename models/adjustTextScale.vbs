option explicit

dim model, modelView
dim obj, objView
dim textScale

set model = metis.currentModel
set modelView = model.currentModelView
set objView = modelView.currentInstanceView
textScale = objView.textScale

call adjustTextScale(objView, textScale)

sub adjustTextScale(objView, textScale)
    dim child, children

    textScale = textScale / 4
    set children = objView.children
    for each child in children
        child.textScale = textScale
        call adjustTextScale(child, textScale)
    next
    
end sub
