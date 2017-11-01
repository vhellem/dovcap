
Call ccSendMail("responsible@supplier.com", "Notification", "Description of Notification")        'Creates an e-mail


Sub ccSendMail(mailAddress, subject, body)
       Dim objOutlook
       Dim objMsg

        Const olMailItem = 0

        'Create Outlook
            Set objOutlook = CreateObject("Outlook.application")
            Set objMsg =  objOutlook.CreateItem(olMailItem)

            objMsg.To = mailAddress ' your reminder notification address
            objMsg.Subject = subject
            objMsg.Body = body
            objMsg.Display

        'Clean up
            set objOutlook = Nothing
            set objMsg = Nothing
End Sub

