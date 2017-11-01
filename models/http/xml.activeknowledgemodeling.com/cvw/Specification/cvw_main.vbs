'option explicit

dim model, modelview
dim inst, instview

dim selectDialog, selected
dim instances
dim specificationContainer


set model = metis.currentModel
set modelview = model.currentModelView
set inst = model.currentInstance
set instview = modelview.currentInstanceView

set parentView = ....

set cvwAction = new CVW_Action


' Current instance is the menu button
' Set content specification
set hasContentSpecType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasContentSpecification_UUID")
set specContainerType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
set containers = inst.getNeighbourObjects(0, hasContentSpecType, specContainerType)
for each cont in containers
    if isEnabled(cont) then
        set cvwContentSpec = new CVW_ContentSpecification
        cvwContentSpec.model = metis.currentModel
        set instances = cvwContentSpec.findInstances(cont)
    end if
next

' Find search mode
set cvwArgValue = new CVW_ArgumentValue
searchMode = cvwArgValue.getArgumentValue(inst, "ContentSpecification")

' Handle select dialog if specified
if searchMode = "SelectAll" then
    set selected = instances
else
    set cvwSelectDialog = new CVW_SelectDialog
    if searchMode = "SelectOneFromList" then
        cvwSelectDialog.singleSelect = true
    elseif searchMode = "SelectManyFromList" then
        cvwSelectDialog.singleSelect = false
    end if
    set selected = cvwSelectDialog.show(instances)
end if

' Set view specification
set specRelType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:specificationRel_UUID")
set hasViewSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewSpecification1_UUID")
set hasLanguageSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification_UUID")
set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy_UUID")
set hasViewstyleType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewstyleSpecification_UUID")

set containers = inst.getNeighbourObjects(0, hasViewSpecificationType, specContainerType)
for each cont in containers
    if isEnabled(cont) then
        set cvwViewSpec = new CVW_ViewSpecification
        set relships = cont.getNeighbourrelationships(0, specRelType)
        for each rel in rels
            if isEnabled(rel) then
                if rel.type.uri = hasLanguageSpecificationType then
                    if not isValid(cvwViewSpec.languageSpecification) then
                        set cvwLangSpec = new CVW_LanguageSpecification
                        call cvwLangSpec.build(rel.target)
                        set cvwViewSpec.languageSpecification = cvwLangSpec
                    end if
                elseif rel.type.uri = hasViewStrategyType then
                    if not isValid(cvwViewSpec.viewStrategy) then
                        set cvwViewStrategy = new CVW_ViewStrategy
                        call cvwViewStrategy.build(rel.target)
                        set cvwViewSpec.viewStrategy = cvwViewStrategy
                    end if
                elseif rel.type.uri = hasViewstyleType then
                    if not isValid(cvwViewSpec.viewstyleSpecification) then
                        set cvwViewstyleSpec = new CVW_ViewstyleSpecification
                        call cvwViewstyleSpec.build(rel.target)
                        set cvwViewSpec.viewstyleSpecification = cvwViewstyleSpec
                    end if
                end if
            end if
        next
        
        ' Create workarea
        set cvwWorkArea = new CVW_Workarea
        cvwWorkArea.create(title, parentView)
        cvwWorkArea.setSpecification(cont)
        cvwWorkArea.populateView(selected)
    end if
next


















