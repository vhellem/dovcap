var request = require('superagent')


export function getModelsFromBackend() {
    const res =  request.get('http://localhost:8080/api/getModel')
    return res;



}