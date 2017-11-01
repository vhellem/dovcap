' Main-------------------
    On error resume next
 
    set fileSysObj = CreateObject("Scripting.FileSystemObject")
    
    cDirName = selectedFolder()      

    IF fileSysObj.FolderExists(cDirName) Then

     Set cFolder = fileSysObj.GetFolder(cDirName)

      MsgBox cFolder

    End if

 

' --------------- sub

 

Function selectedFolder()

   Dim strBFF, objSHL, objBFF

   selectedFolder = "c:\temp"

   Set objSHL = CreateObject("Shell.Application")

   Set objBFF = objSHL.BrowseForFolder(&H0,"OpenFile",&H4031,&H0011)

   strBFF = objBFF.ParentFolder.ParseName(objBFF.Title).Path

   selectedFolder = strBFF

   Set objBFF = Nothing

   Set objSHL = Nothing

end Function

