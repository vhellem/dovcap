' Set variant

' contextInst is the CC

'stop

set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

set ccObject = Nothing
set varObject = Nothing
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set wObject = workWindow.instance
set objects = wObject.getNeighbourObjects(0, hasContextType, GLOBAL_Type_AnyObject)
if objects.count > 0 then 
    if objects(1).type.inherits(GLOBAL_Type_VAR) then
        set varObject = objects(1)
    end if
end if
if isEnabled(varObject) then
    set rels = contextInst.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
    if rels.count > 0 then
        set rel = rels(1)
        set rel.target = varObject
    end if
else
    set ccObject = contextInst
end if

if isEnabled(ccObject) then
    set objects = ccObject.getNeighbourObjects(0, GLOBAL_Type_hasVAR, GLOBAL_Type_VAR)
    if objects.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select variant"
        cvwSelectDialog.heading = "Select variant"
        set variants = cvwSelectDialog.show(objects)
        if isValid(variants) then
            if variants.count = 1 then
                set varObject = variants(1)
                ' Connect usesVar relationship
                set rels = ccObject.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
                if rels.count = 1 then
                    set rel = rels(1)
                    set rel.target = varObject
                elseif rels.count = 0 then
                    ' Create rel
                    set model = varObject.ownerModel
                    set rel = model.newRelationship(GLOBAL_Type_usesVAR, ccObject, varObject)
                end if
            end if
        end if
    end if
end if
' Configure component according to the chosen variant
if isEnabled(varObject) then
    set ccObject = contextInst
    set ccConfig = new CC_Configure
    call ccConfig.setVariantParameters(ccObject, varObject)
    call ccConfig.configureVariant(ccObject)
    MsgBox "Done!"
end if

