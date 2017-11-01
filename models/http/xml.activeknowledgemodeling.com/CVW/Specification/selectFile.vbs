option explicit

dim fileName
dim fileTypes

fileName = selectFile(fileTypes)
if Len(fileName) > 0 then
    MsgBox fileName
end if

Function selectFile(fileTypes)
    dim objDialog
    dim filter
    dim intResult
    
    selectFile = ""
    select case fileTypes
    case "kmv"
        filter = "Modelview urls (*.kmv)|*.kmv"
    case "kmd"
        filter = "Data urls (*.kmd)|*.kmd"
    case "doc"
        filter = "Word files (*.doc)|*.doc"
    case "xls"
        filter = "Excel files (*.xls)|*.xls"
    case "txt"
        filter = "Text files (*.txt)|*.txt"
    case else
        filter = "All files (*.*)|*.*"
    end select

    Set objDialog = Createobject("Useraccounts.Commondialog")
    objDialog.Filter = filter
    objDialog.Filterindex = 1
    objDialog.InitialDir = "C:\"
'    objDialog.dialogTitle = "Select a file"
    intResult = objDialog.Showopen
    If intResult <> 0 Then
        selectFile = objDialog.FileName
    End if
End Function

