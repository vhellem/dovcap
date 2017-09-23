package com.dlizarra.starter;

import java.util.*;
/**
 * Class to store object information and descriptions.
 */

public class myObject {
    String id;
    String name;
    String type;
    Map<String, String> valueset;

    public myObject(){
        valueset = new HashMap<String, String>();
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

    public void setId(String id){
        if (this.id == null) {
            this.id = id;
        }
    }
    
    public void setType(String type){
        if (this.type == null){
            this.type = type;
        }
    }

    public void setName(String name){
        this.name = name;
    }

}
