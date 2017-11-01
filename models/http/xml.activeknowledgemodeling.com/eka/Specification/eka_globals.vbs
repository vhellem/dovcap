option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class EKA_Globals


    Private Sub Class_Initialize()

        if not isEmpty(ekaGlobalsInitialized) then exit Sub

        ' Object types
        set GLOBAL_Type_AnyObject          = metis.findType("metis:stdtypes#oid1")
        set GLOBAL_Type_EkaSpace           = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID")
        set GLOBAL_Type_EkaProject         = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/project.kmd#AKM_Project")
        set GLOBAL_Type_EkaElement         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_element.kmd#ObjType_EKA:Element_UUID")
        set GLOBAL_Type_EkaObject          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_object.kmd#ObjType_EKA:Object_UUID")
        set GLOBAL_Type_EkaProperty        = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set GLOBAL_Type_EkaPropertyView    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:PropertyView_UUID")
        set GLOBAL_Type_EkaSymbol          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:Symbol_UUID")
        set GLOBAL_Type_EkaValue           = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        ' Relationship types
        set GLOBAL_Type_AnyRelationship    = metis.findType("metis:stdtypes#oid101")
        set GLOBAL_Type_EkaRelationship    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/symbol_relships.kmd#RelType_EKA:Relationship_UUID")
        set GLOBAL_Type_EkaEquals          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Equals_UUID")
        set GLOBAL_Type_EkaIs              = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
        set GLOBAL_Type_EkaHasMember       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set GLOBAL_Type_EkaHasPart         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Part_UUID")
        set GLOBAL_Type_EkaHasAggregatedProperty = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasAggregatedProperty_UUID")
        set GLOBAL_Type_EkaHasProperty     = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
         set GLOBAL_Type_EkaHasParameter    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasParameter_UUID")
        set GLOBAL_Type_EkaHasAggregatedParameter = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasAggregatedParameter_UUID")
        set GLOBAL_Type_EkaHasValue        = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set GLOBAL_Type_EkaHasValue2       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue2_UUID")
        set GLOBAL_Type_EkaHasDefinition   = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")
        set GLOBAL_Type_EkaHasAllowedValue = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasAllowedValue_UUID")
        set GLOBAL_Type_EkaHasIcon         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/symbol_relships.kmd#RelType_EKA:HasIcon_UUID")
        set GLOBAL_Type_EkaHasSymbol       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/symbol_relships.kmd#RelType_EKA:HasSymbol_UUID")
        ' Methods
        set GLOBAL_Mtd_EkaEditProperties   = metis.findMethod("http://xml.activeknowledgemodeling.com/eka/operations/virtual_methods.kmd#Method_EKA:editProperties_UUID")
        set GLOBAL_Mtd_EkaSetSymbol        = metis.findMethod("http://xml.activeknowledgemodeling.com/eka/operations/eka_methods.kmd#Method_EKA:SetSymbol_UUID")
        set GLOBAL_Mtd_EkaSetTypeView      = metis.findMethod("http://xml.activeknowledgemodeling.com/eka/operations/eka_methods.kmd#Method_EKA:SetTypeView_UUID")

    End Sub
    
End Class

