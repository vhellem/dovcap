option explicit

    ' doViewAction
    dim model, modelView
    dim aObject
    dim component, components
    dim instances
    dim workspace
    dim cvwWorkspace, cvwWorkarea
    dim cvwViewStrategy, cvwContentSpec
    dim usesType, componentType
    dim doIt

    set model = metis.currentModel
    set modelView = model.currentModelView
    set aObject = model.currentInstance

    set usesType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent2_UUID")
    set componentType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")

    doIt = true
    set instances = Nothing
    set components = aObject.getNeighbourObjects(0, usesType, componentType)

    ' 3 Locate content specification component
    for each component in components
        if isEnabled(component) then
            if component.name = "ContentSpecification" then
                doIt = false
                ' Configure content specification
                call resetCVWcomponent(component)
                call configureCVWcomponent(aObject, component)
                ' Build and execute
                set cvwContentSpec = new CVW_ContentSpecification
                set cvwContentSpec.component = component
                set cvwContentSpec.configObject = aObject
                call cvwContentSpec.build                          ' Build internal structures
                set instances = cvwContentSpec.execute             ' Execute methods dependent on configuration
                if instances.count > 0 then doIt = true
                exit for
            end if
        end if
    next

    if doIt then
      ' 1. Locate workspace component
      for each component in components
        if isEnabled(component) then
            if component.name = "Workspace" then
                ' Configure workspace
                call resetCVWcomponent(component)
                call configureCVWcomponent(aObject, component)
                ' Build and execute
                set cvwWorkspace = new CVW_Workspace
                set cvwWorkspace.component = component
                set cvwWorkspace.configObject = aObject
                call cvwWorkspace.build                          ' Build internal structures
                set workspace = cvwWorkspace.execute             ' Execute methods dependent on configuration
                exit for
            end if
        end if
      next

      ' 2. Locate workarea component
      for each component in components
        if isEnabled(component) then
            if component.name = "Workarea" then
                ' Configure workarea
                call resetCVWcomponent(component)
                call configureCVWcomponent(aObject, component)
                ' Build and execute
                set cvwWorkarea = new CVW_Workarea
                set cvwWorkarea.component = component
                set cvwWorkarea.configObject = aObject
                set cvwWorkarea.workspace = workspace
                call cvwWorkarea.build                          ' Build internal structures
                call cvwWorkarea.configure
                call cvwWorkarea.execute                        ' Execute: Builds workarea (as an empty window w titlebar)
                exit for
            end if
        end if
      next

      ' 5. Populate workarea
      if isValid(instances) then
        if instances.count > 0 then
            call cvwWorkarea.populate(instances)            ' Populates view with instances dependent on view specifications
        end if
      end if
    end if



    
    

