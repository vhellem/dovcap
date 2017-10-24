const { EventEmitter } = require('fbemitter');

const emitter = new EventEmitter();

function getEmitter() {
  return emitter;
}

export default getEmitter();
