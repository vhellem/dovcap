package com.dlizarra.starter;


import com.google.gson.Gson;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@RestController
public class ModelController {

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value = "/api/getModel", method = RequestMethod.GET)
        public String getModels() {
            Parser parser = new Parser("models/simple.kmv");

            return parser.getJson();
        }

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value="/api/getModelNames", method=RequestMethod.GET)
        public String getModelNames() {
          File folder = new File("models");
          File[] files = folder.listFiles();
          ArrayList fileNames = new ArrayList();

          for(File file : files) {
            if (file.isFile()) {
             fileNames.add(file.getName());
            }
          }
          String json = new Gson().toJson(fileNames);
          return json;
        }

    }
