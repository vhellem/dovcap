option explicit

Public Function getCcFamilyName

    dim model, inst, parent, parentType
    dim families
    dim ccGlobals

    set ccGlobals = new CC_Globals
    set model = metis.currentModel
    set inst  = model.currentInstance
    set parent = inst.parent
    set parentType = parent.type

    set families = inst.getNeighbourObjects(1, GLOBAL_Type_EkaHasPart, GLOBAL_Type_CcFamily)
    if families.count > 0 then
        getCcFamilyName = families(1).title
    elseif parentType.inherits(GLOBAL_Type_EkaProject) then
        getCcFamilyName = parent.title
    elseif parentType.inherits(GLOBAL_Type_VAR) then
        getCcFamilyName = getReferencedValue("name", 0, GLOBAL_Type_EkaIs, GLOBAL_Type_Requirement)
    else
        getCcFamilyName = ""
    end if
End Function

