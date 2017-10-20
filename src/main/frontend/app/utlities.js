const request = require('superagent');

export function getModelsFromBackend() {
  const res = request.get('/api/getModel');
  console.log("Get models from backend", res);
  return res;
}

export function findModelByReference(reference, list) {
  for (const model in list) {
    if (model.id === reference) {
      return model;
    }
  }
  return false;
}

export function selectModelFromBackend(model) {
  const res = request.get('/api/selectModel2').query({ name: model });
  return res;
}

export function getModelNamesFromBackend() {
  fetch('http://localhost:8080/api/getModelNames')
    .then(response => response.json())
    .then(data => {
      console.log('Data:', data);
      return data;
    }).catch(err => console.error(err.toString()));
}
export function getModelNames() {
  const res = request.get('/api/getModelNames');
  return res;
}
