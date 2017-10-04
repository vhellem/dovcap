package com.dlizarra.starter;

import java.util.*;
/**
 * Class to store object information and descriptions.
 */

public class myObject {
    String id;
    String name;
    String type;
    ArrayList<String> viewChildren;
    Map<String, String> valueset;
    Map<String, String> attributes;
    ArrayList<myObject> children;
    myObject objectReference;

    public myObject(){
        valueset = new HashMap<String, String>();
        attributes = new HashMap<String, String>();
        viewChildren = new ArrayList();
        children = new ArrayList();
    }

    @Override
    public String toString(){
        return this.id;
    }

    public String getInfo(){
        return this.id + ": " + this.name;
    }

    public void addValueset(String key, String value){
        valueset.put(key, value);
    }

    public void addChild(String ref){
        viewChildren.add(ref);
    }

    public void addModelChild(myObject child){
      children.add(child);
    }
    public void setId(String id){
        if (this.id == null) {
            this.id = id;
        }
    }
    public void addObject(myObject obj){
      this.objectReference = obj;
    }

    public void setType(String type){
        if (this.type == null){
            this.type = type;
        }
    }
    public void setAttributes(HashMap<String, String> att){
        this.attributes.putAll(att);
    }

    public void setName(String name){
        this.name = name;
    }

    public void updateAttributesWithScales(List<Double> scales){
      this.attributes.put("scaleX", String.valueOf(scales.get(0)));
      this.attributes.put("scaleY", String.valueOf(scales.get(1)));
      this.attributes.put("scaleHeight", String.valueOf(scales.get(2)));
      this.attributes.put("scaleWidth", String.valueOf(scales.get(3)));

    }

}
