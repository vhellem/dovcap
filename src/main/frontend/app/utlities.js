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
