const request = require('superagent');

const PORT = process.env.PORT || 8080;

export function getModelsFromBackend() {
  const res = request.get(`//localhost:${PORT}/api/getModel`);
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
