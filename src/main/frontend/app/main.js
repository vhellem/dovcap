import { Switch, Route } from 'react-router-dom';
import Root from './root.js';
import App from './app.js';
import Uploader from './upload';
import React from 'react';
import LandingPage from './landingpage';

const Main = () => (
  <main>
    <Switch>
      <Route path="/model/:modelID/:viewID" component={App} />
      <Route path="/model/:modelID" component={App} />
      <Route path="/upload" component={Uploader} />
      <Route path="/*" component={LandingPage} />
    </Switch>
  </main>
);

export default Main;
