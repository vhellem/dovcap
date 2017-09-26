package com.dlizarra.starter;


import org.springframework.web.bind.annotation.*;

@RestController
public class ModelController {

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value = "/api/getModel", method = RequestMethod.GET)
        public String getModels() {
            Parser parser = new Parser("simple.kmv");

            return parser.getJson();
        }

    }
