package com.dlizarra.starter;

import java.util.ArrayList;
import java.util.List;

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
}
