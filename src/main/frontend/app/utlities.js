var request = require('superagent');

export function getModelsFromBackend() {
  const res = request.get('http://localhost:8080/api/getModel');
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
