option explicit

public model, modelView
dim paramId, vpv

paramId = InputBox("Enter parameter")
if CLen(paramId) > 0 then
    paramValue = InputBox("Enter parameter value to set")
    if CLen(paramValue) > 0 then
        setVPV paramId paramValue
    end if
end if

