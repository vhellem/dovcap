option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewSpecification

    Public  title                   ' String
    Public  languageSpecification   ' CVW_LanguageSpecification
    Public  viewStrategy            ' CVW_ViewStrategy
    Public  viewstyleSpecification  ' CVW_ViewstyleSpecification
    Public  layoutStrategy          ' IMetisInstance
    Public  backgroundSymbol        ' Uri

    Private model
    Private modelView
    Private hasLanguageSpecType
    Private hasViewStrategyType
    Private hasViewstyleSpecType
    Private hasLayoutStrategyType
    Private viewStyle

'-----------------------------------------------------------
    Public Sub build(specObject)
        dim obj, rel, relships

        set languageSpecification  = new CVW_LanguageSpecification
        ' Find language specification (in model)
        set relships = specObject.getNeighbourRelationships(0, hasLanguageSpecType)
        for each rel in relships
            if isEnabled(rel) then
                set obj = rel.target
                if isEnabled(obj) then
                    languageSpecification.build(obj)
                end if
            end if
        next

        set viewStrategy = new CVW_ViewStrategy
        ' Find view strategy (in model)
        set relships = specObject.getNeighbourRelationships(0, hasViewStrategyType)
        for each rel in relships
            if isEnabled(rel) then
                set obj = rel.target
                if isEnabled(obj) then
                    viewStrategy.build(obj)
                end if
            end if
        next

        set viewstyleSpecification = new CVW_ViewstyleSpecification
        ' Find view strategy (in model)
        set relships = specObject.getNeighbourRelationships(0, hasViewstyleSpecType)
        for each rel in relships
            if isEnabled(rel) then
                set obj = rel.target
                if isEnabled(obj) then
                    viewstyleSpecification.build(obj)
                end if
            end if
        next
        if not isValid(relships) then
            set argObj = new CVW_Argument
            viewstyle = argObj.getArgumentValue(specObject, "Viewstyle")
            viewstyleSpecification.setViewstyle(viewstyle)
        end if

        set relships = specObject.getNeighbourRelationships(0, hasLayoutStrategyType)
        for each rel in relships
            if isEnabled(rel) then
                set obj = rel.target
                if isEnabled(obj) then
                    set layoutStrategy = obj
                    exit for
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        dim argObj
        on error resume next

        set model = metis.currentModel
        set modelView = model.currentModelView
        set hasLanguageSpecType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification_UUID")
        set hasViewStrategyType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategySpecification_UUID")
        set hasViewstyleSpecType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewstyleSpecification_UUID")
        set hasLayoutStrategyType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLayoutStrategy_UUID")
        set argObj = new CVW_ArgumentValue
        viewstyle  = argObj.getArgumentValue(aObject, "Viewstyle")
        if Len(viewStyle) > 0 then
            modelView.setViewStyle(viewStyle)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub
End Class


