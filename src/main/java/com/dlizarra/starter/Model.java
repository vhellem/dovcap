package com.dlizarra.starter;

import java.util.*;

public class Model {

    List<myObject> objectL;
    List<myObject> viewL;
    List<myObject> modelViewL;

    public Model(){
        objectL = new ArrayList<myObject>();
        viewL = new ArrayList<myObject>();
        modelViewL = new ArrayList<myObject>();
    }

    public void setObjectL(List<myObject> list){
        this.objectL=list;
    }
    public void setviewL(List<myObject> list){
        this.viewL=list;
    }
    public void setModelViewL(List<myObject> list){
        this.modelViewL=list;
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
      Queue<myObject> queue = new ArrayDeque<>();
      queue.add(this.modelViewL.get(0));
      while(!queue.isEmpty()){
        myObject curr = queue.remove();
        for (String childRef: curr.viewChildren){
          for (myObject child: this.viewL){
            if (child.id.equals(childRef.substring(1))){
              curr.addModelChild(child);
              queue.add(child);
            }
          }
        }

      }
    }
}
