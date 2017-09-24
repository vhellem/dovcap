package com.dlizarra.starter;


import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ModelController {


        @RequestMapping(value = "/api/getModel", method = RequestMethod.GET)

        public String getModels() {
            Parser parser = new Parser("simple.kmv");

            return parser.getJson();
        }

    }
