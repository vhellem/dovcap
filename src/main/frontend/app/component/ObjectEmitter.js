import React from 'react';
var { EventEmitter } = require('fbemitter');

var emitter = new EventEmitter();

function getEmitter() {
  return emitter;
}

export default getEmitter();
