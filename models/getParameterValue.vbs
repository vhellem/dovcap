option explicit

function getParameterValue(paramName)
    dim model, inst, obj
    dim objects

    getParameterValue = "No value"
    set model = metis.currentModel
    ' The current instance is a CC relationship
    set inst = model.currentInstance
    set objects = inst.getNeighbourObjects(1, typeCCrelship, typeEKAobject)
    for each obj in objects        
        if isEnabled(obj) then
            getParameterValue =  getParamValue(inst, paramName)
            exit for
        end if
    next
end function

function getParamValue(inst, paramName)
    getParamValue = "No value"
    set values = inst.getNeighbourObjects(0, typeHasValue, typeEKAobject)
    for each value in values
        sval = value.name
    next
    
end function
