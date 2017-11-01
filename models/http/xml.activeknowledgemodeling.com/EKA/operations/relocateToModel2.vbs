option explicit

dim cvwObject
'stop
set cvwObject = new CVW_Object
cvwObject.ModelContext  = "SubModel"
cvwObject.ModelViewName = "ContentModel"
cvwObject.ModelType     = "http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID"
call cvwObject.relocateToModel()

