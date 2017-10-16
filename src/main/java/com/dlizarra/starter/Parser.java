package com.dlizarra.starter;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.File;
import java.io.FileInputStream;
import java.io.StringReader;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
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
    List<myObject> typeviewL;
    List<String> linkedDocsL;
    List<String> loadedDocsL;

    String objectXmlFileName;
    String tmpValue;
    String tmpName;
    boolean readingValueset;
    boolean readingRelationshipView;
    boolean readingRelationship;
    boolean readingIcon;
    myObject objectTmp;

    public Parser(String objectXmlFileName) {
        this.objectXmlFileName  = objectXmlFileName;
        objectL                 = new ArrayList<myObject>();
        viewL                   = new ArrayList<myObject>();
        modelViewL              = new ArrayList<myObject>();
        relationshipL           = new ArrayList<myObject>();
        relationshipViewL       = new ArrayList<myObject>();
        typeviewL               = new ArrayList<myObject>();
        linkedDocsL             = new ArrayList<String>();
        loadedDocsL             = new ArrayList<String>();

        readingValueset         = false;
        readingRelationshipView = false;
        readingRelationship     = false;
        readingIcon             = false;
        parseDocument();
        //printJson();
    }

    public void parseFile(String fileName) {
        this.objectXmlFileName = fileName;
        parseDocument();
    }

    private void loadLinkedDocuments() {
        List<String> currentLinkedDocsL = new ArrayList<String>(linkedDocsL);
        Iterator<String> currentLinkedDocsIterator = currentLinkedDocsL.iterator();
        while(currentLinkedDocsIterator.hasNext()) {
            String doc = currentLinkedDocsIterator.next();
            doc = lookupFileName(doc);
            if(!loadedDocsL.contains(doc)) {
                loadedDocsL.add(doc);
                parseFile(doc);
            }
        }
    }

    private void parseDocument() {
        SAXParserFactory factory = SAXParserFactory.newInstance();
        try {
            SAXParser parser = factory.newSAXParser();
            parser.parse(objectXmlFileName, this);
            loadedDocsL.add(objectXmlFileName);
            loadLinkedDocuments();

        } catch (ParserConfigurationException e) {
            System.out.println("ParserConfig error");
            System.out.println(e);

        } catch (SAXException e) {
            System.out.println("SAXException : xml not well formed");
            System.out.println(e);

        } catch (IOException e) {
            System.out.println("IO error");
            System.out.println(e);
        }
    }

    private class MyExclusionStrategy implements ExclusionStrategy {
        private final Class<?> typeToSkip;

        private MyExclusionStrategy(Class<?> typeToSkip) {
            this.typeToSkip = typeToSkip;
        }

        public boolean shouldSkipClass(Class<?> clazz) {
            return (clazz == typeToSkip);
        }

        public boolean shouldSkipField(FieldAttributes f) {
            return f.getAnnotation(gsonSkip.class) != null;
        }
    }

    public String getJson() {
        Gson gson = new GsonBuilder()
            .setPrettyPrinting()
            .setExclusionStrategies(new MyExclusionStrategy(Parser.class))
            .serializeNulls()
            .create();

        Model model = new Model();
        model.setLists(objectL, viewL, modelViewL, relationshipL, relationshipViewL,
                typeviewL);
        model.setParser(this);
        model.preprocess();
        return gson.toJson(model);
    }

    private void printJson() {
        System.out.println(getJson());
    }

    public String lookupFileName(String filename) {
        int dotIndex = filename.lastIndexOf(".");
        int startIndex = filename.lastIndexOf("/");
        if (dotIndex == -1 | startIndex == -1) {
            return filename;
        }
        return "models" + filename.substring(startIndex, dotIndex+4);
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
            addOrUpdateElement(objectL, attributes.getValue("id"), attributes);
        }
        if (elementName.equals("objectview")) {
            addOrUpdateElement(viewL, attributes.getValue("id"), attributes);
        }
        if (elementName.equals("child-link")) {
            objectTmp.addChild(attributes.getValue("xlink:href"));
        }
        if (readingValueset) {
            tmpName = attributes.getValue("name");
        }
        if(elementName.equals("modelview")) {
            addOrUpdateElement(modelViewL, attributes.getValue("id"), attributes);
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
            linkedDocsL.add(attributes.getValue("xlink:href"));
            objectTmp.setAttributes(modelAtt);
        }
        if (elementName.equals("relationship")) {
            addOrUpdateElement(relationshipL, attributes.getValue("id"), attributes);
            readingRelationship = true;
        }
        if (elementName.equals("relationshipview")) {
            addOrUpdateElement(relationshipViewL, attributes.getValue("id"), attributes);
            readingRelationshipView = true;
        }
        if (elementName.equals("origin-link")) {
            if (readingRelationshipView){
                objectTmp.addValueset("origin_role" , attributes.getValue("xlink:role"));
                objectTmp.addValueset("origin_title", attributes.getValue("xlink:title"));
                objectTmp.addValueset("origin_href" , attributes.getValue("xlink:href"));
            }
        }
        if (elementName.equals("target-link")) {
            if (readingRelationshipView){
                objectTmp.addValueset("target_role" , attributes.getValue("xlink:role"));
                objectTmp.addValueset("target_title", attributes.getValue("xlink:title"));
                objectTmp.addValueset("target_href" , attributes.getValue("xlink:href"));
            }
        }
        if (elementName.equals("origin")) {
            if (readingRelationship) {
                objectTmp.addValueset("origin_seq"  , attributes.getValue("seq"));
                objectTmp.addValueset("origin_role" , attributes.getValue("xlink:role"));
                objectTmp.addValueset("origin_title", attributes.getValue("xlink:title"));
                objectTmp.addValueset("origin_href" , attributes.getValue("xlink:href"));
            }
        }
        if (elementName.equals("target")) {
            if (readingRelationship){
                objectTmp.addValueset("target_seq"  , attributes.getValue("seq"));
                objectTmp.addValueset("target_role" , attributes.getValue("xlink:role"));
                objectTmp.addValueset("target_title", attributes.getValue("xlink:title"));
                objectTmp.addValueset("target_href" , attributes.getValue("xlink:href"));
            }
        }
        if (elementName.equals("typeview")) {
            addOrUpdateElement(typeviewL, objectXmlFileName+":"+attributes.getValue("id"), attributes);
        }
        if (elementName.equals("replace")) {
            if (attributes.getValue("tag").equals("icon")) {
                String iconLink = attributes.getValue("macro");
                int dotIndex = iconLink.lastIndexOf(".");
                int startIndex = iconLink.lastIndexOf("/");
                if(iconLink.substring(dotIndex+1, dotIndex+4).equals("svg")) {
                    String icon = iconLink.substring(startIndex+1, dotIndex+4);
                    objectTmp.addValueset("icon", icon);
                }
            }
        }
        if (elementName.equals("string")) {
            String name = attributes.getValue("name");
            if (name.length() >= 4) {
                if (name.substring(0, 4).equals("icon")) {
                    readingIcon = true;
                }
            }
        }
    }

    private void addOrUpdateElement(List<myObject> list, String name, Attributes attributes) {
        int index = list.indexOf(name);
        if (index != -1) {
            objectTmp = list.get(index);
        } else {
            objectTmp = new myObject();
            list.add(objectTmp);
        }
        objectTmp.setId(name);

        HashMap<String, String> att = new HashMap();
        for (int i = 0; i < attributes.getLength(); i++) {
            att.put(attributes.getQName(i), attributes.getValue(i));
        }
        objectTmp.setAttributes(att);
    }

    @Override
    public void endElement(String s, String s1, String element) throws SAXException {
        if (element.equals("valueset")) {
            readingValueset = false;
        }
        if (readingValueset) {
            if (tmpName != null) {
                if (tmpName.equals("name")) {
                    objectTmp.setName(tmpValue);
                }
                else {
                    objectTmp.addValueset(tmpName, tmpValue);
                }
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
        if (element.equals("string")) {
            if(readingIcon & tmpValue != null) {
                String iconLink = tmpValue;
                int dotIndex = iconLink.lastIndexOf(".");
                int startIndex = iconLink.lastIndexOf("/");
                try {
                    if(iconLink.substring(dotIndex+1, dotIndex+4).equals("svg")) {
                        String icon = iconLink.substring(startIndex+1, dotIndex+4);
                        objectTmp.addValueset("icon", icon);
                    }
                } catch (StringIndexOutOfBoundsException e) {
                    // Not a valid icon.
                }
            }
        }
    }

    @Override
    public void characters(char[] ac, int i, int j) throws SAXException {
        tmpValue = new String(ac, i, j);
        // It puts a newline plus some tabs and spaces if there is no value
        // for some attribute. The json becomes nicer with null instead.
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
