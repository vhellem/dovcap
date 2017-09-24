var request = require('superagent')


function getModelsFromBackend() {
    request.get('http://localhost:8080/api/getModel').end(function(err, res){
        //console.log(res.text);
        json = JSON.parse(res.text)
        return json


    })
}