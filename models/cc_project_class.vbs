option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Project

    ' Variant parameters
    Public Title                        ' String
    Public ModelContext                 ' String: CurrentModel | SubModel
    Public ModelViewTitle               ' Name of modelview that contains the project model
    Public DialogTitle
    Public DialogHeading
    Public NoNewProject

    ' Context variables (public)
    Public ProjectModel

    ' Context variables (private)
    Private projectObject               ' IMetisInstance
    Private parentObject                ' IMetisInstance


'-----------------------------------------------------------
    Public Function create(projectId)
        dim container

        set create = Nothing
        if isEnabled(ProjectModel) then
            set container = ProjectModel.parts(1)
            if isEnabled(container) then
                set create = container.newPart(GLOBAL_Type_CcProject)
                if isEnabled(create) then
                    create.title = projectId
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function find(projectId)
        dim container
        dim part, parts

        set find = Nothing
        if isEnabled(ProjectModel) then
            set container = ProjectModel.parts(1)
            if isEnabled(container) then
                set parts = container.parts
                for each part in parts
                    if part.type.inherits(GLOBAL_Type_CcProject) then
                        if part.title = projectId then
                            set find = part
                            exit for
                        end if
                    end if
                next
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function list()
        dim container
        dim part, parts

        set list = metis.newInstanceList
        if isEnabled(ProjectModel) then
            set container = ProjectModel.parts(1)
            if isEnabled(container) then
                set parts = container.parts
                for each part in parts
                    if part.type.inherits(GLOBAL_Type_CcProject) then
                        call list.addLast(part)
                    end if
                next
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function selectProject1()
        dim connector
        dim projects

        set selectProject1 = Nothing
        if not isEnabled(ProjectModel) then
            ' Find project model (submodel)
            set connector = findInstModel2(ModelContext, ModelViewTitle)
            if isValid(connector) then
                set ProjectModel = getModelFromConnector(connector)
            end if
        end if
        if isEnabled(ProjectModel) then
            set projects = ProjectModel.parts
            if projects.count > 0 then
                set selectProject1 = projects(1)
            else
                set selectProject1 = selectProject
            end if
        end if

    End Function
'-----------------------------------------------------------
    Public Function selectProject()
        dim container
        dim connector
        dim part, parts
        dim project, projects
        dim newProject, projectName
        dim cvwSelectDialog

        set selectProject = Nothing
        if not isEnabled(ProjectModel) then
            ' Find project model (submodel)
            set connector = findInstModel2(ModelContext, ModelViewTitle)
            if isValid(connector) then
                set ProjectModel = getModelFromConnector(connector)
            end if
        elseif ProjectModel.isConnectorType then
            set ProjectModel = getModelFromConnector(ProjectModel)
        end if
        if isEnabled(ProjectModel) then
            set projects = ProjectModel.parts
            if not NoNewProject then
                set newProject = ProjectModel.newObject(GLOBAL_Type_CcProject)
            end if
            if isEnabled(newProject) then
                newProject.title = "New project"
                projects.addLast newProject
            end if
            if projects.count = 0 then
                exit function
            else
                if not NoNewProject or projects.count > 1 then
                    set cvwSelectDialog = new CVW_SelectDialog
                    cvwSelectDialog.singleSelect = true
                    cvwSelectDialog.title = DialogTitle
                    cvwSelectDialog.heading = DialogHeading
                    set projects = cvwSelectDialog.show(projects)
                end if
                if isValid(projects) then
                    if projects.count = 1 then
                        set project = projects(1)
                        if project.title = "New project" then
                            projectName = "New project"
                            projectName = InputBox("Enter project name", "Input dialog", projectName)
                            if Len(projectName) > 0 then
                                project.title = projectName
                            else
                                exit function
                            end if
                        end if
                        set selectProject = project
                    end if
                    if not isValid(project) then
                        ProjectModel.deleteObject(newProject)
                    elseif isValid(newProject) then
                        if project.uri <> newProject.uri or projects.count = 0 then
                            ProjectModel.deleteObject(newProject)
                        end if
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Sub addToProject(projectObj, contentObj)
        if isEnabled(projectObj) then
            set contentObj.parent = projectObj
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        set ccGlobals = Nothing
        ' Further initialization
        set ProjectModel = Nothing
        ModelContext   = "SubModel"
        ModelViewTitle = "ProjectModel"
        DialogTitle    = "Select project"
        DialogHeading  = "Select project"
        NoNewProject   = false
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

