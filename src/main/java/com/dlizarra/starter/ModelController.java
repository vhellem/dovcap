package com.dlizarra.starter;


import org.springframework.web.bind.annotation.*;

@RestController
public class ModelController {

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value = "/api/getModel", method = RequestMethod.GET)
        public String getModels() {
            Parser parser = new Parser("models/cvw-sprint3-workplace.kmv");

            return parser.getJson();
        }

    }
