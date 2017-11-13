package com.dlizarra.starter;

import org.junit.*;
import com.google.gson.*;
import java.io.*;

public class TestParser {
    Parser parser;

    @Before
    public void setUp() {
        System.out.println("Initialising parser with simple model.");
        //Parser parser = new Parser("../../../../../../models/simple2.kmv");
        parser = new Parser("../../../models/simple2.kmv");
    }

    @Test
    public void testInit() {
        Assert.assertNotNull(parser);
    }

    @Test
    public void testGetJson() {
        String jsonString = parser.getJson();
        Assert.assertNotNull(jsonString);
        Assert.assertTrue(validateJson(jsonString));
        Assert.assertTrue(compareJson(jsonString));
    }

    private boolean validateJson(String jsonString) {
        Gson gson = new Gson();
        try{
            if(gson.fromJson(jsonString, Object.class) != null){
                return true;
            }
            return false;
        } catch(Exception e) {
            return false;
        }
    }

    private boolean compareJson(String json) {
        char[] actual = json.toCharArray();
        FileReader in = null;

        try{
            in = new FileReader("testing/simple_goal.txt");

            int c;
            int i = 0;
            while((c = in.read()) != -1) {
                if(actual[i++] != (char)c){
                    return false;
                }
            }
        } catch(ArrayIndexOutOfBoundsException aioobe) {
            try{
                if(in.read() != -1){
                    return false;
                }
            } catch(Exception e) {
                return false;
            }
        } catch(Exception e){
            return false;
        }
        return true;
    }
}
