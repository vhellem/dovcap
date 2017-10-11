' New requirement type
' contextInst is the CC

call newCCcontent(contextInst, "Technology Responsible", 2, 0, 0)


' New component specification
' contextInst is the CC

call newCCcontent(contextInst, "Component Responsible", 2, 0, 1)


' New product specification
' contextInst is the CC

call newCCcontent(contextInst, "Product Responsible", 2, 0, 1)


' New family member
if isEnabled(GLOBAL_CC_CurrentProject) then
    set projectObject = GLOBAL_CC_CurrentProject
else
    set ccProject = new CC_Project
    set projectObject = ccProject.selectProject1
    set GLOBAL_CC_CurrentProject = projectObject
end if
if not isEnabled(GLOBAL_CC_CurrentFamily) then
    set ccFamily = new CC_Family
    set ccFamily.ProjectObject = projectObject
    set GLOBAL_CC_CurrentFamily = ccFamily.selectFamily
    set ccFamily = Nothing
end if
call newCCcontent(contextInst, "Component Family Responsible", 2, 1, 1)



' Search component specification

' contextInst is the CC

call searchContent(contextInst, "Component Responsible", 2, 0, 1)


' Search product specification

' contextInst is the CC

call searchContent(contextInst, "Product Responsible", 2, 0, 1)


' Search component family

' contextInst is the CC

call searchContent(contextInst, "Component Family Responsible", 2, 1, 1)




