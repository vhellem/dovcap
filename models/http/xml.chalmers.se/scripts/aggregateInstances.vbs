' Aggregate instances in family

' contextInst is the CC

' Check if family is given
if not isEnabled(GLOBAL_CC_CurrentFamily) then
    set ccFamily = new CC_Family
    set ccFamily.ProjectObject = GLOBAL_CC_CurrentProject
    set GLOBAL_CC_CurrentFamily = ccFamily.selectFamily
    set ccFamily = Nothing
end if
if isEnabled(GLOBAL_CC_CurrentFamily) then
    ' Find the members of the family
    set familyMembers = GLOBAL_CC_CurrentFamily.getNeighbourObjects(0, GLOBAL_Type_EkaHasPart, GLOBAL_Type_CCInstance)
    if familyMembers.count > 0 then
        ' Find requirement type
        set reqTypes = familyMembers(1).getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_Requirement)
        for each reqType in reqTypes
            exit for
        next
    end if
    ' Aggregate the property values
    set ccInstanceType = new CC_InstanceType
    roleName = "Component Family Responsible"
    ccInstanceType.parameterRule = "Aggregated Parameters(" & roleName & ")"
    call ccInstanceType.aggregateValues(contextInst, GLOBAL_CC_CurrentFamily, reqType, GLOBAL_CC_CurrentProject)
    call searchContent(contextInst, roleName, 2, 1, 1, 1)
    ' Open the property dialog
    set method = metis.findMethod("http://xml.chalmers.se/methods/virtual_methods.kmd#editReqProperties")
    call model.runMethodOnInst(method, GLOBAL_CC_CurrentFamily)

end if

