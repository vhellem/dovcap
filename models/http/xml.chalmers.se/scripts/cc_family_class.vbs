option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Family

    ' Variant parameters
    Public Title                        ' String
    Public DialogTitle
    Public DialogHeading

    ' Context variables (public)
    Public ProjectObject

'-----------------------------------------------------------
    Public Function create(familyId)
        dim container

        set create = Nothing
        if isEnabled(ProjectObject) then
            set container = ProjectObject.parts(1)
            if isEnabled(container) then
                set create = container.newPart(GLOBAL_Type_CcFamily)
                if isEnabled(create) then
                    create.title = familyId
                end if
            end if
        else
            MsgBox "Family is not created - requires project to be defined!"
        end if
    End Function

'-----------------------------------------------------------
    Public Function find(familyId)
        dim container
        dim part, parts

        set find = Nothing
        if isEnabled(ProjectObject) then
            set container = ProjectObject.parts(1)
            if isEnabled(container) then
                set parts = container.parts
                for each part in parts
                    if part.type.inherits(GLOBAL_Type_CcFamily) then
                        if part.title = projectId then
                            set find = part
                            exit for
                        end if
                    end if
                next
            end if
        else
            MsgBox "No project given - the search is not performed!"
        end if
    End Function

'-----------------------------------------------------------
    Public Function list()
        dim part, parts

        set list = metis.newInstanceList
        if isEnabled(ProjectObject) then
            set parts = ProjectObject.parts
            for each part in parts
                if part.type.inherits(GLOBAL_Type_CcFamily) then
                    call list.addLast(part)
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function selectFamily()
        dim part, parts
        dim family, families
        dim newFamily, familyName
        dim cvwSelectDialog

        set selectFamily = Nothing
        if isEnabled(ProjectObject) then
            set families = list
            set newFamily = ProjectObject.newPart(GLOBAL_Type_CcFamily)
            if isEnabled(newFamily) then
                newFamily.title = "New family"
                families.addLast newFamily
            end if
            if families.count = 0 then
                exit function
            else
                set cvwSelectDialog = new CVW_SelectDialog
                cvwSelectDialog.singleSelect = true
                cvwSelectDialog.title = DialogTitle
                cvwSelectDialog.heading = DialogHeading
                set families = cvwSelectDialog.show(families)
                if isValid(families) then
                    if families.count = 1 then
                        set family = families(1)
                        if family.title = "New family" then
                            familyName = "New family"
                            familyName = InputBox("Enter family name", "Input dialog", familyName)
                            if Len(familyName) > 0 then
                                family.title = familyName
                            else
                                exit function
                            end if
                        end if
                        set selectFamily = family
                    end if
                    if not isValid(family) then
                        ProjectObject.ownerModel.deleteObject(newFamily)
                    else
                        if family.uri <> newFamily.uri or families.count = 0 then
                            ProjectObject.ownerModel.deleteObject(newFamily)
                        end if
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        set ccGlobals = Nothing
        ' Further initialization
        set ProjectObject = Nothing
        DialogTitle   = "Select family"
        DialogHeading = "Select family"
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

