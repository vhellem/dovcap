import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, hashHistory } from 'react-router';
import '../style/style.css';
import App from './app.js';
import Landingpage from './landingpage';
import Workplace from './workplace';
import Uploader from './upload';

ReactDOM.render(
  <Router history={hashHistory}>
    <Route path="/" component={App}/>
    <Route path="/workplace" component={Workplace}/>
    <Route path="/upload" component={Uploader} />
  </Router>
  , document.querySelector('.container')
);
