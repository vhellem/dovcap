package com.dlizarra.starter;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.File;
import java.io.FileInputStream;
import java.io.StringReader;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Map;
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
    Map<String, myObject> objectM;
    Map<String, myObject> viewM;
    Map<String, myObject> modelViewM;
    Map<String, myObject> relationshipM;
    Map<String, myObject> relationshipViewM;
    Map<String, myObject> typeviewM;
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
        objectM                 = new HashMap<String, myObject>();
        viewM                   = new HashMap<String, myObject>();
        modelViewM              = new HashMap<String, myObject>();
        relationshipM           = new HashMap<String, myObject>();
        relationshipViewM       = new HashMap<String, myObject>();
        typeviewM               = new HashMap<String, myObject>();
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
                if (doc.matches(".*\\.(kmv|kmd)")) {
                    parseFile(doc);
                }
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
        model.setLists(objectM.values(), viewM.values(), modelViewM.values(),
            relationshipM.values(), relationshipViewM.values(), typeviewM.values());
        model.setParser(this);
        model.preprocess();
        return gson.toJson(model);
    }

    private void printJson() {
        System.out.println(getJson());
    }

    public String lookupFileName(String filename) {
        if(filename.startsWith("http://") && filename.matches(".*\\.(kmv|kmd).*")){
            // This is assumed to be on the correct form.
            try {
                int endIndex = filename.lastIndexOf(".");
                int startIndex = 7;
                return "models/http/" + filename.substring(startIndex, endIndex+4);
            }
            catch (Exception e) {
                // It was not on the correct form.
            }
        }
        try{
            return "models/" + removeDirectory(filename);
        } catch (Exception e){
            return filename;
        }
    }

    private String removeDirectory(String filePath) {
        int dotIndex = filePath.lastIndexOf(".");
        int startIndex = filePath.lastIndexOf("/");
        return filePath.substring(startIndex+1, dotIndex+4);
    }

    private void addIcon(String iconReference) {
        try {
            String iconString = removeDirectory(iconReference);
            if (iconString.matches(".*\\.(png|svg|gif)")) {
                objectTmp.addValueset("icon", iconString);
            }
        } catch (Exception e) {
            // Not a valid icon.
        }
    }

    @Override
    public InputSource resolveEntity(String pId, String sId) throws SAXException, IOException {
        System.out.println("Skipping " + pId + " , " +sId);
        return new InputSource(new StringReader(""));
    }

    @Override
    public void startElement(String s, String s1, String elementName,
                            Attributes attributes) throws SAXException {
      try {
        if (elementName.equals("metis")) {
          // Maybe we will need this info later
        }
        if (elementName.equals("object")) {
          addOrUpdateElement(objectM, attributes.getValue("id"), attributes);
        }
        if (elementName.equals("objectview")) {
          addOrUpdateElement(viewM, attributes.getValue("id"), attributes);
        }
        if (elementName.equals("child-link")) {
          objectTmp.addChild(attributes.getValue("xlink:href"));
        }
        if (readingValueset) {
          tmpName = attributes.getValue("name");
        }
        if (elementName.equals("modelview")) {
          addOrUpdateElement(modelViewM, attributes.getValue("id"), attributes);
        }
        if (elementName.equals("valueset")) {
          HashMap<String, String> modelAtt = new HashMap();
          for (int i = 0; i < attributes.getLength(); i++) {
            modelAtt.put(attributes.getQName(i), attributes.getValue(i));
          }

          readingValueset = true;
          if (attributes.getValue("xlink:role").equals("type")) {
            objectTmp.setType(attributes.getValue("xlink:title"));
          }
          linkedDocsL.add(attributes.getValue("xlink:href"));
          objectTmp.setAttributes(modelAtt);
        }
        // If this is uncommented, the ITRV submodels will be loaded.
        // They get their own panes though, and are not displayed properly.
        // if (elementName.equals("part-link")) {
        //   if(attributes.getValue("xlink:title") != null){
        //     if(attributes.getValue("xlink:title").equals("IRTV Core")){
        //         linkedDocsL.add(attributes.getValue("xlink:href"));
        //     }
        //   }
        // }
        if (elementName.equals("relationship")) {
          addOrUpdateElement(relationshipM, attributes.getValue("id"), attributes);
          readingRelationship = true;
        }
        if (elementName.equals("relationshipview")) {
          addOrUpdateElement(relationshipViewM, attributes.getValue("id"), attributes);
          readingRelationshipView = true;
        }
        if (elementName.equals("origin-link")) {
          if (readingRelationshipView) {
            objectTmp.addValueset("origin_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("origin_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("origin_href", attributes.getValue("xlink:href"));
          }
        }
        if (elementName.equals("target-link")) {
          if (readingRelationshipView) {
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
          if (readingRelationship) {
            objectTmp.addValueset("target_seq", attributes.getValue("seq"));
            objectTmp.addValueset("target_role", attributes.getValue("xlink:role"));
            objectTmp.addValueset("target_title", attributes.getValue("xlink:title"));
            objectTmp.addValueset("target_href", attributes.getValue("xlink:href"));
          }
        }
        if (elementName.equals("typeview")) {
          addOrUpdateElement(typeviewM,
            objectXmlFileName + ":" + attributes.getValue("id"),
            attributes);
        }
        if (elementName.equals("replace")) {
          if (attributes.getValue("tag").equals("icon")) {
            addIcon(attributes.getValue("macro"));
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



        if (elementName.equals("url")) {
          if (attributes.getValue("name").equals("filename")) {
            addIcon(attributes.getValue("xlink:href"));
          }
        }
      }
      catch(NullPointerException e){
        //This is to avoid missing objects, when we have taken wrong assumptions
      }
    }

    private void addOrUpdateElement(Map<String, myObject> map, String name,
                                    Attributes attributes) {
        objectTmp = map.get(name);
        if (objectTmp == null) {
            objectTmp = new myObject();
            map.put(name, objectTmp);
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
      try {
        if (element.equals("valueset")) {
          readingValueset = false;
        }
        if (readingValueset) {
          if (tmpName != null) {
            if (tmpName.equals("name")) {
              objectTmp.setName(tmpValue);
            } else {
              objectTmp.addValueset(tmpName, tmpValue);
            }
          }
        }
        if (element.equals("relationshipview")) {
          readingRelationshipView = false;
        }
        if (element.equals("relationship")) {
          readingRelationship = false;
        }
        if (element.equals("string")) {
          if (readingIcon & tmpValue != null) {
            addIcon(tmpValue);
          }
        }
      }
      catch(NullPointerException e){
        //This is here to avoid errors when we have made the wrong assumptions for what values can come
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
