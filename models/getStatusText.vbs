option explicit

Public Function getStatusText
    dim model, inst
    dim instType
    dim status

    set model = metis.currentModel
    set inst  = model.currentInstance

    getStatusText = ""
    set instType = inst.type
    if instType.inherits(GLOBAL_Type_CCProperty) then
        status = inst.getNamedValue("status").getInteger
        select case status
            case 0  getStatusText = "Not_OK"
            case 1  getStatusText = "Check"
            case 2  getStatusText = "OK"
        end select
    elseif instType.inherits(GLOBAL_Type_Specification) then
        status = inst.getNamedValue("status").getInteger
        select case status
            case 0  getStatusText = "Not_OK"
            case 1  getStatusText = "Not_OK"
            case 2  getStatusText = "Check"
            case 3  getStatusText = "OK"
        end select
    end select
End Function

