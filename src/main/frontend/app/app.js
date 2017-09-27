import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import Workspace from './components/workspace.js';
import '../style/workspace.css';

class App extends React.Component {
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);
      console.log(json);
    });
  }
  render() {
    return <Workspace/>
  }
}
export default App;
