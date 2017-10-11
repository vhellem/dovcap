const request = require('superagent');

export function getModelsFromBackend() {
  const res = request.get('/api/getModel');
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
  const req = new FormData();
  req.append('name', model);
  request.post('/api/selectModel')
    .send(req)
    .end((err, res) => {
      if (err) {
        console.log(err);
      }
      return res;
    });
}

export function getModelNamesFromBackend() {
  let files = [];
  fetch('http://localhost:8080/api/getModelNames')
    .then(response => response.json())
    .then(data => {
      console.log('Data:', data);
      files = data;
    }).catch(err => console.error(err.toString()));
  console.log('Files', files);
  return files;
}
