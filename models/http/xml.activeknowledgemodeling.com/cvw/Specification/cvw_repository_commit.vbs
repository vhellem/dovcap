option explicit

dim aRep, aRepType
dim aMethod
dim InputDClickMethod

    set aRepType = metis.findType("metis:troux#TrouxMarshalling")
    set aRep = metis.currentModel.findInstances(aRepType,"","")
    if isEnabled(aRep) then

        InputDClickMethod ="metis:troux#TrouxUpload"
        set aMethod = metis.findMethod(InputDClickMethod)

        call metis.currentModel.runMethodOnInst(aMethod, aRep.item(1))
    end if
    
' End    

