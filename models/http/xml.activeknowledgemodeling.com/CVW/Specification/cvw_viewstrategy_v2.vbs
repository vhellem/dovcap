option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewStrategy

    Public  title

    ' Parameters
    Public SpecificationModel            ' String
    Public noHierarchyRules              ' Integer
    Public hierarchyRules()              ' Collection of CVW_Rule

    ' Context variables
    Private model
    Private modelView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private anyObjectType                ' IMetisType
    Private isTopType                    ' IMetisType
    Private hasViewStrategyType          ' IMetisType

    ' Others
    Private cvwArg                       ' CVW_ArgumentValue

'-----------------------------------------------------------
    Public Property Get component           'IMetisObject
        set component = cObject
    End Property

    Public Property Set component(obj)
        if isEnabled(obj) then
            set cObject = obj
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get configObject           'IMetisObject
        set configObject = aObject
    End Property

    Public Property Set configObject(obj)
        if isEnabled(obj) then
            set aObject = obj
        end if
    End Property

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build(strategyCont)
        dim indx
        dim strategies
        dim contUri, specObject
        dim obj1, obj2, rel, rels
        dim relDir
        dim type1, type2, relType
        dim cvwRule

        ' Build code
        indx = 1
        ' Find view strategy specification
        if isEnabled(strategyCont) then
            ' Find view strategies
            set strategies = strategyCont.getNeighbourObjects(0, isTopType, anyObjectType)
            for each obj1 in strategies
                if isEnabled(obj1) then
                    set rels = obj1.neighbourRelationships
                    for each rel in rels
                        if isEnabled(rel) then
                            if not isTopType.uri = rel.type.uri then
                                set relType = rel.type
                                if rel.origin.uri = obj1.uri then
                                    relDir = 0
                                    set type1 = obj1.type
                                    set obj2 = rel.target
                                    set type2 = obj2.type
                                elseif rel.target.uri = obj1.uri then
                                    relDir = 1
                                    set type1 = obj1.type
                                    set obj2 = rel.origin
                                    set type2 = obj2.type
                                end if
                                set cvwRule = new CVW_Rule
                                cvwRule.title = "Rule" & CStr(indx)
                                set cvwRule.parentType = type1
                                set cvwRule.relType = relType
                                set cvwRule.childType = type2
                                cvwRule.relDir = relDir
                                call addHierarchyRule(cvwRule)
                            end if
                        end if
                        indx = indx + 1
                    next
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if CVW_ViewStrategy uses other components
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim Something

        set execute = Nothing
        ' The code
        set execute = Something
    End Function

'-----------------------------------------------------------
    Private Sub addHierarchyRule(cvwRule)
        dim rule
        dim indx, found

        found = false
        for indx = 1 to noHierarchyRules
            set rule = hierarchyRules(indx)
            if isValid(rule) then
                if cvwRule.title = rule.title then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noHierarchyRules = noHierarchyRules + 1
            ReDim Preserve hierarchyRules(noHierarchyRules)
            set hierarchyRules(noHierarchyRules) = cvwRule
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set cObject   = model.currentInstance
        set aObject   = model.currentInstance
        set cvwArg    = new CVW_ArgumentValue
        noHierarchyRules  = 0
        ReDim hierarchyRules(noHierarchyRules)
        set anyObjectType       = metis.findType("metis:stdtypes#oid1")
        set isTopType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy_UUID")
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Rule
    Public title
    Public parentType
    Public relType
    Public childType
    Public relDir

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        title = "Rule"
        set parentType = Nothing
        set relType   = Nothing
        set childType = Nothing
        relDir = 0
    End Sub

End Class

'-----------------------------------------------------------


