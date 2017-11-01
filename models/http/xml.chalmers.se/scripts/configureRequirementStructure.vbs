' Configure requirement structure

' contextInst is the CC

'stop

set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

set currentObj = Nothing
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set wObject = workWindow.instance
set objects = wObject.getNeighbourObjects(0, hasContextType, GLOBAL_Type_AnyObject)
if objects.count > 0 then set varObject = objects(1)
if isEnabled(varObject) then
    set rels = contextInst.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
    if rels.count > 0 then
        set rel = rels(1)
        set rel.target = varObject
    end if
else
    set currentObj = contextInst
end if

if isEnabled(currentObj) then
    set objects = currentObj.getNeighbourObjects(0, GLOBAL_Type_hasVAR, GLOBAL_Type_VAR)
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
                set rels = currentObj.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
                if rels.count = 1 then
                    set rel = rels(1)
                    set rel.target = varObject
                elseif rels.count = 0 then
                    ' Create rel
                    set model = varObject.ownerModel
                    set rel = model.newRelationship(GLOBAL_Type_usesVAR, currentObj, varObject)
                end if
            end if
        end if
    end if
end if
'stop
' Configure component according to the chosen variant
if isEnabled(varObject) then
    set currentObj = contextInst
    set ccConfig = new CC_Configure
    call ccConfig.setVariantParameters(currentObj, varObject)
    call ccConfig.configureVariant(currentObj)
    call ccConfig.buildRequirementStructure(contextInst, varObject, Nothing)
end if


