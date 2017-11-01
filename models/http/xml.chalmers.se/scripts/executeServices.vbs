option explicit

    dim ccGlobals
    dim currentModel, currentModelView
    dim currentInstance, currentInstanceView
    dim workarea, workWindow
    dim ccType, isType
    dim hasInstanceContext2Type, hasContentModelType
    dim service, services, serviceName
    dim contextRels, context
    dim cvwSelectDialog, ccRuleEngine
    dim subject, ccObject
    dim selected
    dim i, removed

    'Initialization
    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    set hasContentModelType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext2_UUID")
    set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
    
    set ccGlobals = new CC_Globals
    set ccObject = getCcObject(currentInstance, currentInstanceView)
    if isEnabled(ccObject) then
        serviceName = currentInstance.getNamedStringValue("comments")
        if Len(serviceName) = 0 then
            set workWindow = getWorkWindowView(currentInstance, currentInstanceView)
            set selected = metis.selectedObjectViews
            if selected.count = 1 then
                ' Find the services
                set subject = selected(1).instance
                set services = getServices(subject)
                ' Select one
                if isValid(services) then
                    set cvwSelectDialog = new CVW_SelectDialog
                    cvwSelectDialog.singleSelect = true
                    cvwSelectDialog.title = "Select service"
                    cvwSelectDialog.heading = "Select service"
                    set services = cvwSelectDialog.show(services)
                end if
            end if
        else
            set subject = ccObject
            set services = getServices(subject)
            i = 1
            for each service in services
                removed = false
                if not service.title = serviceName then
                    services.removeAt(i)
                    removed = true
                else
                    i = i + 1
                end if
            next
        end if
'stop
        if isValid(services) then
            for each service in services
                ' Check if the rule context is different than the invoking object
                set contextRels = service.getNeighbourRelationships(0, GLOBAL_Type_hasRuleContext)
                if contextRels.count > 0 then
                    set context = contextRels(1).target
                else
                    set context = subject
                end if
                set ccRuleEngine = new CC_RuleEngine
                call ccRuleEngine.executeRule(context, service, 2)
            next
        end if
    end if
    set ccGlobals = Nothing

    ' End

    Function getServices(subject)
        dim service, services, inheritedServices
        dim component, components
        dim i, removed
        dim ruleKind

        set getServices = Nothing
        set services = subject.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
        i = 1
        removed = false
        for each service in services
            ruleKind = service.getNamedStringValue("ruleKind")
            if not ruleKind = "Service" then
                services.removeAt(i)
                removed = true
            end if
            if not removed then
                i = i + 1
            end if
        next

        if subject.type.inherits(GLOBAL_Type_CC) then
            set components = subject.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_CC)
            for each component in components
                set inheritedServices = getServices(component)
            next
        end if
        if isValid(inheritedServices) then
            for each service in inheritedServices
                services.addLast service
            next
        end if
        set getServices = services
    End Function


