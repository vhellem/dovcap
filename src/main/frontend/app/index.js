import React from 'react';
import ReactDOM from 'react-dom';
import '../style/style.css';
import Root from './root';
import { BrowserRouter, HashRouter } from 'react-router-dom';
import Main from './main.js';

ReactDOM.render(
  <HashRouter>
    <Root />
  </HashRouter>,
  document.querySelector('.container')
);
