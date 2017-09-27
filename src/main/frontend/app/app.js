import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import { Layer, Rect, Stage, Group } from 'react-konva';
import MyRect from './MyRect.js';

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
      return <h1 modelView={this.state.modelViews[this.state.selectedModel]}>Selected model</h1>;
    }
    return <h1>loading</h1>;
  }
}
export default App;
