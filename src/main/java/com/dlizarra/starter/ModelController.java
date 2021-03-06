package com.dlizarra.starter;

import com.google.gson.Gson;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.mapping;
import static java.util.stream.Collectors.toList;

@RestController
public class ModelController {

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value = "/api/getModel", method = RequestMethod.GET)
        public String getModels() {
            Parser parser = new Parser("models/cvw-sprint4-workplace.kmv");
            return parser.getJson();
        }

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value = "/api/selectModel", method=RequestMethod.GET)
        public String selectModel(@RequestParam("name") String fileName) {
          Parser parser = new Parser("models/"+fileName);
          String json = parser.getJson();
          return json;
        }

        @CrossOrigin(origins = "http://localhost:9090")
        @RequestMapping(value="/api/getModelNames", method=RequestMethod.GET)
        public String getModelNames() {
          File folder = new File("models");
          File[] files = folder.listFiles();
          ArrayList<String> fileNames = new ArrayList<>();

          for(File file : files) {
            if (file.isFile()) {
              if (getFileExt(file).equals("kmv")) {
                fileNames.add(file.getName());
              }
            }
          }
          String json = new Gson().toJson(fileNames);
          return json;
        }

        @CrossOrigin(origins="http://localhost:9090")
        @RequestMapping(value="/api/getAllFileNames", method=RequestMethod.GET)
        public String getAllFileNames() {
          File folder = new File("models");
          Stream<File> files = Arrays.stream(folder.listFiles());
          Map<String, List<String>> fileGroups = files
            .collect(groupingBy(f -> getFileExt(f), mapping((File f) -> f.getName(), toList())));
          String json = new Gson().toJson(fileGroups);
          return json;
        }

        @CrossOrigin(origins="http://localhost:9090")
        @RequestMapping(value="/api/uploadModel", method=RequestMethod.POST)
        public @ResponseBody ResponseEntity<String> handleModelUpload(
          @RequestParam("name") String name, @RequestParam("file") MultipartFile file) throws Exception {
          if (!file.isEmpty()) {
            try {
              byte[] bytes = file.getBytes();
              BufferedOutputStream stream = new BufferedOutputStream(new FileOutputStream(new File("models/" + name)));
              stream.write(bytes);
              stream.close();
              System.out.println("POST OK!");
              return ResponseEntity.ok("File " + name + " uploaded.");
            } catch (Exception e) {
              return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(e.getMessage());
            }
          } else {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body("You failed to upload " + name + " because the file was empty.");
          }
        }
        @CrossOrigin(origins="http://localhost:9090")
        @RequestMapping(value="/api/deleteModel", method=RequestMethod.POST)
        public @ResponseBody ResponseEntity<String> handleModelDelete(@RequestParam("name") String fileName) throws Exception {
          File folder = new File("models");
          for (File file : folder.listFiles()) {
            if (file.getName().equals(fileName)) {
              file.delete();
              return ResponseEntity.ok("File " + fileName + " deleted!");
            }
          }
          return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body("Couldn't find " + fileName + " in model folders!");
        }
        private static String getFileExt(File file) {
          String fileName = file.getName();
          int dotIndex = fileName.lastIndexOf('.');
          return (dotIndex == -1) ? "" : fileName.substring(dotIndex + 1);
        }
    }
