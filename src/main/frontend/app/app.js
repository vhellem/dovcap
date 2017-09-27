import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import ModelView from './ModelView.js';

class App extends React.Component {
  constructor() {
    super();
    this.state = {
      selectedModel: false,
      modelViews: null
    };
  }
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);

      console.log(json);
      this.setState({
        selectedModel: 0,
        modelViews: json.modelViewL
      });
    });
  }

  render() {
    console.log(this.state);
    if (this.state.selectedModel === 0) {
      return <ModelView modelView={this.state.modelViews[this.state.selectedModel]} />;
    }
    return <h1>loading</h1>;
  }
}
export default App;
