option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewAsHierarchySpecification

    Public  title             ' String
    Public parentObjectType   ' IMetisType
    Public childObjectType    ' IMetisType
    Public partOfRelType      ' IMetisType
    Public partOfRelDir       ' Integer:   0 = From parent to child, 1 = From child to parent


'-----------------------------------------------------------
    Public Sub build(specificationObject)

        ' Build code

    End Sub

End Class

