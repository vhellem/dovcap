package com.dlizarra.starter;

import java.io.IOException;
import java.text.ParseException;
import java.util.ArrayList;
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
    String objectXmlFileName;
    String tmpValue;
    String tmpName;
    boolean readingValueset;
    myObject objectTmp;
    
    public Parser(String objectXmlFileName) {
        this.objectXmlFileName = objectXmlFileName;
        objectL = new ArrayList<myObject>();
        readingValueset = false;
        parseDocument();
        //printAll();
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
        return gson.toJson(objectL);
    }

    private void printJson(){
        Gson gson = new GsonBuilder()
            .setPrettyPrinting()
            .serializeNulls()
            .create();
        for (myObject tmpO : objectL) {
            System.out.println(gson.toJson(tmpO));
            /*Path file = Paths.get("json_output.txt");
            try{
                Files.write(file, gson.toJson(tmpO).getBytes(),// Charset.forName("UTF-8"),
                    StandardOpenOption.APPEND);
            } catch (IOException e) {
                System.out.println("IO error");
            }
            */
        }
    }

    private void printAll() {
        for (myObject tmpO : objectL) {
            System.out.println(tmpO.getInfo());
        }
    }

    @Override
    public InputSource resolveEntity(String pId, String sId) throws SAXException, IOException {
        System.out.println("Skipping " + pId + " , " +sId);
        return new InputSource("");
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
        if (readingValueset) {
            tmpName = attributes.getValue("name");
        }
        if (elementName.equals("valueset")) {
            readingValueset = true;
            if (attributes.getValue("xlink:role").equals("type")) {
                objectTmp.setType(attributes.getValue("xlink:title"));
            }
        }
    }

    @Override
    public void endElement(String s, String s1, String element) throws SAXException {
        if (readingValueset) {
            if (tmpName.equals("name")){
                objectTmp.setName(tmpValue);
            }
            else{
                objectTmp.addValueset(tmpName, tmpValue);
            }
        }

        if (element.equals("valueset")) {
            readingValueset = false;
        }

        if (element.equals("object")) {
            // End editing of the current object
            objectTmp = new myObject();
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
            new Parser("simple.kmv");
        }
        else {
            new Parser(args[0]);
        }
    }
}
