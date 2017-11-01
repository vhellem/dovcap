option explicit

dim currentModel, currentModelView, currentInstance, currentInstanceView
dim objectView, selected
dim workWindow, wObject
dim contView
dim indx
dim specContainerType, hasSearchSpecificationType
dim anyObjectType
dim isInstanceType, hasInstanceContextType
dim objects
dim contextInstance, contextInstanceModel, contextObj
dim searchCont, searchConts
dim cvwContentSpec, cvwWorkarea
dim instances
dim searchLocal

    searchLocal = false

    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    set specContainerType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
    set hasSearchSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasSearchSpecification_UUID")
    set anyObjectType  = metis.findType("metis:stdtypes#oid1")
    set isInstanceType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
    set hasInstanceContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
'stop
    set contView = currentInstanceView.parent.parent
    indx = contView.children.count
    set workWindow = contView.children(indx)
    if isValid(workWindow) then
        set wObject = workWindow.instance
        if isEnabled(wObject) then
            set cvwWorkarea = new CVW_Workarea
            set cvwWorkarea.WorkWindow = workWindow
            set objects = wObject.getNeighbourObjects(0, hasInstanceContextType, anyObjectType)
            if isValid(objects) then
                if objects.count > 0 then
                    set contextInstanceModel = objects(1)
                end if
            end if
            set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
            if isValid(objects) then
                if objects.count > 0 then
                    set contextInstance = objects(1)
                end if
            end if
            ' Get search specification
            set searchConts = wObject.getNeighbourObjects(0, hasSearchSpecificationType, specContainerType)
            if searchConts.count > 0 then
                set searchCont = searchConts(1)

                set cvwContentSpec = new CVW_ContentSpecification
                set cvwContentSpec.currentModel     = currentModel
                set cvwContentSpec.currentModelView = currentModelView
                set cvwContentSpec.contentModel     = cvwWorkarea.contentModel
                if not searchLocal then
                    cvwContentSpec.RepositoryConnection = cvwWorkarea.ContentInRepository
                end if
                if isEnabled(contextInstanceModel) then
                    if searchCont.uri = contextInstanceModel.uri then
                        if isEnabled(contextInstance) then
                            set cvwContentSpec.contextInstance  = contextInstance
                        end if
                    end if
                end if
                cvwContentSpec.SpecificationModel   = searchCont.uri
                cvwContentSpec.PathMode = "Path"
                set instances = cvwContentSpec.execute             ' Execute methods dependent on configuration
                if isValid(instances) then
                    cvwWorkarea.ContentSearchModel = cvwContentSpec.SpecificationModel
                    call cvwWorkarea.populate(instances, -1)
                end if
            end if
        end if
    end if
    
' End

