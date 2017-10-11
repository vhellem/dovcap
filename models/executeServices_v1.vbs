option explicit

    dim currentModel, currentModelView
    dim currentInstance, currentInstanceView
    dim workarea, workwindow
    dim ccType, isType
    dim invokesType, serviceType, hasContextType
    dim service, services, inheritedServices
    dim contextRels, context
    dim cvwSelectDialog, ccRuleEngine
    dim indx, i, removed
    dim ruleKind
    dim subject
    dim selected

    'Initialization
    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView

    set ccType          = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
    set isType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
    set serviceType     = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
    set invokesType     = metis.findType("http://xml.chalmers.se/class/rule.kmd#invokes_rule")
    set hasContextType  = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule_context")

        ' Assume started on Property button on titlebar
        set workarea = currentInstanceView.parent.parent
        indx = workarea.children.count
        set workwindow = workarea.children(indx)
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
            if isValid(services) then
                if services.count = 1 then
                    set service = services(1)
                    ' Check if the rule context is different than the invoking object
                    set contextRels = service.getNeighbourRelationships(0, hasContextType)
                    if contextRels.count > 0 then
                        set context = contextRels(1).target
                    else
                        set context = subject
                    end if
                    set ccRuleEngine = new CC_RuleEngine
                    call ccRuleEngine.executeRule(context, service, 2)
                end if
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




