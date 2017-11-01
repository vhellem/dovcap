    dim inst, isRels, rel, super, logg, answer

    logg = ""
    set inst = Global_Context.Info
    if isEnabled(inst) then
        if not inst.type.inherits(Global_Context.TaskType) then
            logg = logg & inst.title & vbCrLf
            call deleteInheritedPartRels(inst)
            set isRels = Global_InformationManager.getAllNeighbours(inst, "", GLOBAL_Type_EkaIs , 0)
            if isRels.count > 0 then
                answer = InputBox("Include inherited parts (Y/N)?", "Input dialog", "Y")
                if UCase(answer) = "Y" then
                    for each rel in isRels
                        set super = rel.target
                        call inheritParts(inst, super, logg)
                    next
                end if
            end if
        end if
    end if
    'MsgBox logg

    sub inheritParts(current, super, logg)
        dim rel, isRels, superSuper
        dim p, parts, superParts, removeRels
        dim sp, r, rp, op
        dim found, remove

        set isRels = Global_InformationManager.getAllNeighbours(super, "", GLOBAL_Type_EkaIs, 0)
        for each rel in isRels
            set superSuper = rel.target
            call inheritParts(super, superSuper, logg)
        next
        set parts = Global_InformationManager.getParts(current)
        set superParts = Global_InformationManager.getParts(super)
        set removeRels = Global_InformationManager.getAllNeighbours(current, "", Global_Context.RemoveType, 0)
        for each p in parts
            found = false
            for each sp in superParts
                if p.title = sp.title then 
                    found = true
                    exit for
                end if
            next
            if found then exit for
            logg = logg & p.title & vbCrLf
        next
        for each sp in superParts
            remove = false
            for each r in removeRels
                set rp = r.target
                if rp.uri = sp.uri then
                    remove = true
                    exit for
                end if
            next
            if not remove then
                ' Find corresponding part in parts
                found = false
                for each p in parts
                    if p.title = sp.title then
                        logg = logg & p.title & vbCrLf
                        call inheritParts(p, sp, logg)
                        found = true
                        exit for
                    else
                        set overrideRels = Global_InformationManager.getAllNeighbours(p, "", GLOBAL_Type_EkaIs , 0)
                        for each r in overrideRels
                            set op = r.target
                            if op.uri = sp.uri then
                                logg = logg & p.title & vbCrLf
                                found = true
                                exit for
                            end if
                        next
                    end if
                next
                if not found then
                    if not instanceByNameInList(sp, parts) then
                        dim partRel
                        logg = logg & sp.title & vbCrLf
                        ' Connect inheritsPart from current to sp
                        set partRel = current.ownerModel.newRelationship(GLOBAL_Type_EkaHasInheritedPart, current, sp)
                        call parts.addLast(sp)
                    end if
                end if
            end if
        next
    end sub

    sub deleteInheritedPartRels(current)
        dim p, parts, rel, inheritRels
        set parts = Global_InformationManager.getParts(current)
        for each p in parts
            call deleteInheritedPartRels(p)
        next
        set inheritRels = Global_InformationManager.getAllNeighbours(current, "", GLOBAL_Type_EkaHasInheritedPart, 0)
        for each rel in inheritRels
            call rel.ownerModel.deleteRelationship(rel)
        next
    end sub

