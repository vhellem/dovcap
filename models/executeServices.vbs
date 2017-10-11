option explicit

    dim currentModel, currentModelView
    dim currentInstance, currentInstanceView
    dim workarea, workWindow
    dim ccType, isType
    dim actionType
    dim invokesType, serviceType, hasContextType
    dim hasInstanceContext2Type, hasContentModelType, anyObjectType
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

    set ccType          = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
    set actionType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
    set anyObjectType       = metis.findType("metis:stdtypes#oid1")
    set isType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
    set serviceType     = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
    set invokesType     = metis.findType("http://xml.chalmers.se/class/rule.kmd#invokes_rule")
    set hasContextType  = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule_context")
    set hasContentModelType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext2_UUID")
    set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

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
                    cvwSelectDialog.title = "Select dialog"
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

        if isValid(services) then
            for each service in services
                ' Check if the rule context is different than the invoking object
                set contextRels = service.getNeighbourRelationships(0, hasContextType)
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

    ' End

    Function getServices(subject)
        dim service, services, inheritedServices
        dim component, components
        dim i, removed
        dim ruleKind

        set getServices = Nothing
        set services = subject.getNeighbourObjects(0, invokesType, serviceType)
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

        if subject.type.inherits(ccType) then
            set components = subject.getNeighbourObjects(0, isType, ccType)
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


