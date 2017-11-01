option explicit

public model, modelView
dim paramId, vpv

 paramId = InputBox("Enter parameter")
 vpv = getVPV(paramId)
 MsgBox vpv

