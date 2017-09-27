package com.dlizarra.starter;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.File;
import java.io.FileInputStream;
import java.io.StringReader;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.nio.file.*;
import java.nio.charset.*;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.InputSource;

import com.google.gson.*;

public class Parser extends DefaultHandler {
    List<myObject> objectL;
    List<myObject> viewL;
    List<myObject> modelViewL;
    List<myObject> relationshipL;
    List<myObject> relationshipViewL;

    String objectXmlFileName;
    String tmpValue;
    String tmpName;
    boolean readingValueset;
    boolean readingRelationshipView;
    boolean readingRelationship;
    myObject objectTmp;

    public Parser(String objectXmlFileName) {
        this.objectXmlFileName = objectXmlFileName;
        objectL = new ArrayList<myObject>();
        viewL = new ArrayList<myObject>();
        modelViewL = new ArrayList<myObject>();
        relationshipL = new ArrayList<myObject>();
        relationshipViewL = new ArrayList<myObject>();
        readingValueset = false;
        readingRelationshipView = false;
        readingRelationship = false;
        parseDocument();
        //printJson();
    }

    private void parseDocument() {
        SAXParserFactory factory = SAXParserFactory.newInstance();
        try {
            SAXParser parser = factory.newSAXParser();
            parser.parse(objectXmlFileName, this);
        } catch (ParserConfigurationException e) {
            System.out.println("ParserConfig error");
        } catch (SAXException e) {
            System.out.println("SAXException : xml not well formed");
            System.out.println(e);
        } catch (IOException e) {
            System.out.println("IO error");
            System.out.println(e);
        }
    }

    public String getJson(){
        Gson gson = new GsonBuilder()
            .setPrettyPrinting()
            .serializeNulls()
            .create();
        Model model = new Model();
        model.setModelViewL(modelViewL);
        model.setObjectL(objectL);
        model.setviewL(viewL);
        model.setRelationshipL(relationshipL);
        model.setRelationshipViewL(relationshipViewL);
        model.preprocess();
        return gson.toJson(model);
    }

    private void printJson(){
        System.out.println(getJson());
    }

    @Override
    public InputSource resolveEntity(String pId, String sId) throws SAXException, IOException {
        System.out.println("Skipping " + pId + " , " +sId);
        return new InputSource(new StringReader(""));
    }

    @Override
    public void startElement(String s, String s1, String elementName, Attributes attributes) throws SAXException {

        if (elementName.equals("metis")) {
            // Maybe we will need this info later
        }
        if (elementName.equals("object")) {
            int index = objectL.indexOf(attributes.getValue("id"));
            if (index != -1){
                objectTmp = objectL.get(index);
            } else {
                objectTmp = new myObject();
                objectL.add(objectTmp);
            }
            objectTmp.setId(attributes.getValue("id"));
        }
        if (elementName.equals("objectview")){
            HashMap<String, String> att = new HashMap();
            for (int i =0; i<attributes.getLength(); i++){
                att.put(attributes.getQName(i), attributes.getValue(i));
            }

            int index = viewL.indexOf(attributes.getValue("id"));
            if (index != -1){
                objectTmp = viewL.get(index);
            } else {
                objectTmp = new myObject();
                viewL.add(objectTmp);
            }
            objectTmp.setAttributes(att);
            objectTmp.setId(attributes.getValue("id"));

        }
        if (elementName.equals("child-link")){
            objectTmp.addChild(attributes.getValue("xlink:href"));
        }
        if (readingValueset) {
            tmpName = attributes.getValue("name");
        }
        if(elementName.equals("modelview")){
            HashMap<String, String> modelAtt = new HashMap();
            for (int i =0; i<attributes.getLength(); i++){
                modelAtt.put(attributes.getQName(i), attributes.getValue(i));
            }

            int index = modelViewL.indexOf(attributes.getValue("id"));
            if (index != -1){
                objectTmp = modelViewL.get(index);
            } else {
                objectTmp = new myObject();
                modelViewL.add(objectTmp);
            }
            objectTmp.setAttributes(modelAtt);
            objectTmp.setId(attributes.getValue("id"));

        }
        if (elementName.equals("valueset")) {
            HashMap<String, String> modelAtt = new HashMap();
            for (int i =0; i<attributes.getLength(); i++){
                modelAtt.put(attributes.getQName(i), attributes.getValue(i));
            }

            readingValueset = true;
            if (attributes.getValue("xlink:role").equals("type")) {
                objectTmp.setType(attributes.getValue("xlink:title"));
            }
            objectTmp.setAttributes(modelAtt);
        }
        if (elementName.equals("relationship")) {
          int index = relationshipL.indexOf(attributes.getValue("id"));
          if(index != -1){
            objectTmp = relationshipL.get(index);
          } else {
            objectTmp = new myObject();
            relationshipL.add(objectTmp);
          }
          objectTmp.setId(attributes.getValue("id"));
          readingRelationship = true;
        }
        if (elementName.equals("relationshipview")) {
          HashMap<String, String> modelAtt = new HashMap();
          for (int i =0; i<attributes.getLength(); i++){
            modelAtt.put(attributes.getQName(i), attributes.getValue(i));
          }

          int index = relationshipViewL.indexOf(attributes.getValue("id"));
          if(index != -1){
            objectTmp = relationshipViewL.get(index);
          } else {
            objectTmp = new myObject();
            relationshipViewL.add(objectTmp);
          }
          objectTmp.setAttributes(modelAtt);
          objectTmp.setId(attributes.getValue("id"));
          readingRelationshipView = true;
        }
        if (elementName.equals("origin-link")) {
          if (readingRelationshipView){
            objectTmp.addValueset("origin_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("origin_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("origin_href", attributes.getValue("xlink:href"));
          }
        }
        if (elementName.equals("target-link")) {
          if (readingRelationshipView){
            objectTmp.addValueset("target_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("target_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("target_href", attributes.getValue("xlink:href"));
          }
        }
        if (elementName.equals("origin")) {
          if (readingRelationship) {
            objectTmp.addValueset("origin_seq", attributes.getValue("seq"));
            objectTmp.addValueset("origin_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("origin_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("origin_href", attributes.getValue("xlink:href"));
          }
        }
        if (elementName.equals("target")) {
          if (readingRelationship){
            objectTmp.addValueset("target_seq", attributes.getValue("seq"));
            objectTmp.addValueset("target_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("target_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("target_href", attributes.getValue("xlink:href"));
          }
        }
    }

    @Override
    public void endElement(String s, String s1, String element) throws SAXException {
        if (element.equals("valueset")) {
            readingValueset = false;
        }

        if (readingValueset) {
            if (tmpName.equals("name")){
                objectTmp.setName(tmpValue);
            }
            else{
                objectTmp.addValueset(tmpName, tmpValue);
            }
        }

        if (element.equals("object")) {
            // End editing of the current object
            objectTmp = new myObject();
        }

        if (element.equals("relationshipview")) {
          readingRelationshipView = false;
        }

        if (element.equals("relationship")) {
          readingRelationship = false;
        }
    }

    @Override
    public void characters(char[] ac, int i, int j) throws SAXException {
        tmpValue = new String(ac, i, j);
        // It puts a newline plus some tabs and spaces if there is no value
        // for some attribute. The json becomes nicer with null instead
        if(tmpValue.charAt(0) == '\n') {
            tmpValue = null;
        }
    }

    // Change to public if you want to run just the parser.
    private static void main(String[] args) {
        if(args.length == 0) {
            new Parser("models/simple.kmv");
        }
        else {
            new Parser(args[0]);
        }
    }
}
