option explicit

Class CVW_SelectDialog

    Private dialog

'-----------------------------------------------------------
    Public Property Let title(str1)
        if isValid(dialog) then
            dialog.title = str1
        end if
    End Property

'-----------------------------------------------------------
    Public Property Let heading(str1)
        if isValid(dialog) then
            dialog.heading = str1
        end if
    End Property

'-----------------------------------------------------------
    Public Property Let singleSelect(str1)
        if isValid(dialog) then
            dialog.singleSelect = str1
        end if
    End Property

'-----------------------------------------------------------
    Public Function show(instances)
        set show = Nothing
        if isValid(dialog) and isValid(instances) then
            dialog.clear
            if instances.count > 0 then
                dialog.addData instances
                set show = dialog.show
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set dialog = CreateObject("Metis.SelectDialog." & metis.versionMajor & "." & metis.versionMinor)
        if isValid(dialog) then
            with dialog
				.title = "Select"
				.heading = "Select dialog"
				.singleSelect = False
				.columnLabel = True
				.columnURI = False
				.columnType = False
            end with
		'else
            ' Error handling
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set dialog = Nothing
    End Sub

'-----------------------------------------------------------

End Class
