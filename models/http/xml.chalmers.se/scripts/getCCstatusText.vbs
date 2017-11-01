option explicit

Function getCCstatusText
    dim model, inst
    dim instType
    dim status
    dim ccGlobals

    set model = metis.currentModel
    set inst  = model.currentInstance

    getCCstatusText = ""
    set ccGlobals = new CC_Globals

    if not isEnabled(inst) then
        exit function
    end if
    
    set instType = inst.type
    if instType.inherits(GLOBAL_Type_CCProperty) then
        status = inst.getNamedValue("status").getInteger
        select case status
            case 0  getCCstatusText = "Not_OK"
            case 1  getCCstatusText = "Check"
            case 2  getCCstatusText = "OK"
        end select
    elseif instType.inherits(GLOBAL_Type_Specification) then
        status = inst.getNamedValue("status").getInteger
        select case status
            case 0  getCCstatusText = "Not_OK"
            case 1  getCCstatusText = "Not_OK"
            case 2  getCCstatusText = "Check"
            case 3  getCCstatusText = "OK"
        end select
    end if
    set ccGlobals = Nothing
    
End Function

