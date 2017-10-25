package com.dlizarra.starter;

import java.util.*;
import java.io.File;

public class Model {

    List<myObject> objectL;
    List<myObject> viewL;
    List<myObject> modelViewL;
    List<myObject> relationshipL;
    List<myObject> relationshipViewL;
    List<myObject> typeviewL;
    Parser parser;

    public Model(){
        objectL             = new ArrayList<myObject>();
        viewL               = new ArrayList<myObject>();
        modelViewL          = new ArrayList<myObject>();
        relationshipL       = new ArrayList<myObject>();
        relationshipViewL   = new ArrayList<myObject>();
        typeviewL           = new ArrayList<myObject>();
    }

    public void setLists(   List<myObject> objectL,
                            List<myObject> viewL,
                            List<myObject> modelViewL,
                            List<myObject> relationshipL,
                            List<myObject> relationshipViewL,
                            List<myObject> typeviewL) {
        this.objectL = objectL;
        this.viewL = viewL;
        this.modelViewL = modelViewL;
        this.relationshipL = relationshipL;
        this.relationshipViewL = relationshipViewL;
        this.typeviewL = typeviewL;
    }

    public void setObjectL(List<myObject> list){
        this.objectL = list;
    }
    public void setviewL(List<myObject> list){
        this.viewL = list;
    }
    public void setModelViewL(List<myObject> list){
        this.modelViewL = list;
    }
    public void setRelationshipL(List<myObject> list){
        this.relationshipL = list;
    }
    public void setRelationshipViewL(List<myObject> list){
        this.relationshipViewL = list;
    }
    public void settypeviewL(List<myObject> list){
        this.typeviewL = list;
    }
    public void setParser(Parser parser) {
        this.parser = parser;
    }

    public void addTypeAndName(){
        for(myObject view: viewL){
            String objectRef = view.attributes.get("xlink:href").substring(1);
            for (myObject object: objectL){
                if(object.id.equals(objectRef)){
                    view.setType(object.type);
                    view.setName(object.name);
                }
            }
        }
    }

    public void preprocess(){
        this.addTypeAndName();
        //Creates tree structure from the modelViews

        for(myObject modelView: this.modelViewL){
            Queue<myObject> queue = new ArrayDeque<>();
            Map<String, List<Double>> newScales = new HashMap();

            queue.add(modelView);
            double width = 0;
            double height = 0 ;
            double decomp = 0 ;
            while(!queue.isEmpty()){
                myObject curr = queue.remove();
                if (curr.name != null) {
                    width = Double.parseDouble(curr.attributes.get("width"));
                    height = Double.parseDouble(curr.attributes.get("height"));
                    decomp = Double.parseDouble(curr.attributes.get("decomp-scale"));
                }
                this.findObjectReference(curr);
                for (String childReference: curr.viewChildren){
                    String childRef = childReference.substring(1);
                    for (myObject child: this.viewL){
                        if (child.id.equals(childRef)){

                            curr.addModelChild(child);
                            queue.add(child);

                            if(child.name != null){
                                if(!modelViewL.contains(curr)){
                                    double childScaleX = Double.parseDouble(child.attributes.get("left"))*decomp/width;
                                    double childScaleY = Double.parseDouble(child.attributes.get("top"))*decomp/height;
                                    double childScaleHeight = Double.parseDouble(child.attributes.get("height"))*decomp/height;
                                    double childScaleWidth = Double.parseDouble(child.attributes.get("width"))*decomp/width;
                                    newScales.put(childRef, Arrays.asList(childScaleX, childScaleY, childScaleHeight, childScaleWidth));
                                }
                                else{
                                    newScales.put(childRef, Arrays.asList(0.0, 0.0, 1.0, 1.0));
                                }
                            }
                        }
                    }

                }
            }
            this.putNewScalesOnObjects(newScales);
        }

        // Adds the icon as part of the valueset of each object which
        // has a metamodel reference that exists in the parsed file list.
        Iterator<myObject> objectIterator = objectL.iterator();
        while(objectIterator.hasNext()){
            myObject currObject = objectIterator.next();
            if(currObject.attributes.containsKey("xlink:href")) {
                String reference = currObject.attributes.get("xlink:href");
                reference = parser.lookupFileName(reference);
                int referenceIndex = -1;
                for (int ii = 0; ii < typeviewL.size(); ii++){
                    if (typeviewL.get(ii).getId().contains(reference)) {
                        referenceIndex = ii;
                    }
                }
                if (referenceIndex != -1) {
                    String icon;
                    icon = typeviewL.get(referenceIndex).valueset.get("icon");
                    if(icon != null){
                        if(icon.substring(icon.length()-3, icon.length()).equals("svg")){
                            currObject.addValueset("icon", icon);
                        }
                    }
                }
            }
        }

        // Attempts to find and add icons for the files that does not have any icons yet.
        // Will probably add more icons than wanted, so uncomment with caution.
        File folder = new File("models/");
        File[] listOfFiles = folder.listFiles();
        objectIterator = objectL.iterator();
        while(objectIterator.hasNext()){
            myObject currObject = objectIterator.next();
            if(currObject.valueset.containsKey("icon")) {
                if(!currObject.valueset.get("icon").equals(null)){
                    continue;
                }
            }
            ArrayList<String> candidates = new ArrayList<String>();
            int lowestCandidate = 100;
            String name = currObject.type;
            if(name != null) {
                for(String subtype : name.split(" ")){
                    for (File file : listOfFiles){
                        String filename = file.getName();
                        int dotIndex = filename.lastIndexOf(".");
                        int startIndex = filename.lastIndexOf("/");
                        if(filename.length() - dotIndex > 3) {
                            if(filename.substring(dotIndex+1, dotIndex+4).equals("svg")){
                                filename = filename.substring(startIndex+1, dotIndex+4);
                                if(filename.contains(subtype.toLowerCase())) {
                                    candidates.add(filename);
                                    if(filename.length() < lowestCandidate) {
                                        lowestCandidate = filename.length();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for (String cand : candidates) {
                if(cand.length() == lowestCandidate) {
                    currObject.addValueset("icon", cand);
                }
            }
        }
    }


    //Inserts information about the object to the viewModel
    public void findObjectReference(myObject view){
        for (myObject object: this.objectL){
            if (view.attributes.get("xlink:href").substring(1).equals(object.id)){
                view.addObject(object);
            }
        }
    }

    public void putNewScalesOnObjects(Map<String, List<Double>> scales){
        for(myObject obj: this.viewL){
            List<Double> newAttr = scales.get(obj.id);
            obj.updateAttributesWithScales(newAttr);
        }
    }
}
