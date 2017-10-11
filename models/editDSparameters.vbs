option explicit

    dim model, ccObject
    dim dsList
    dim frObj, frObjects
    dim dsObj, dsObjects
    dim primary
    dim ccGlobals, cvwSelectDialog
    dim method


    ' Init
    set ccGlobals = new CC_Globals

    set model = metis.currentModel
    set ccObject = model.currentInstance

    ' The idea is to find the design solutions and choose the one to view its parameters
    set dsList = metis.newInstanceList
    ' First find primary functional requirements
    set frObjects = ccObject.getNeighbourObjects(0, GLOBAL_Type_explains, GLOBAL_Type_FR)
    for each frObj in frObjects
        primary = frObj.getNamedValue("primary").getInteger
        'if primary = 1 then
            ' Then find design solutions
            set dsObjects = frObj.getNeighbourObjects(0, GLOBAL_Type_solves, GLOBAL_Type_DS)
            for each dsObj in dsObjects
                call dsList.addLast(dsObj)
            next
        'end if
    next
    if dsList.count > 0 then
        ' Choose the design solution
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select Design Solution"
        cvwSelectDialog.heading = "Select Design Solution"
        set dsList = cvwSelectDialog.show(dsList)
        if dsList.count = 1 then
            set method = metis.findMethod("http://xml.chalmers.se/methods/virtual_methods.kmd#editDSproperties")
            call model.runMethodOnInst(method, dsList(1))
        end if
    end if

' End
