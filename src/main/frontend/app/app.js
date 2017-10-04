import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import ModelView from './ModelView.js';
import person from './image/networkdevice.svg';
import test from './image/organization.png';
class App extends React.Component {
  constructor() {
    super();
    this.state = {
      selectedModel: false,
      modelViews: null,
      relationships: null
    };
  }
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);

      console.log(json);
      this.setState({
        selectedModel: 0,
        modelViews: json.modelViewL,
        relationships: json.relationshipL
      });
    });
  }

  render() {
    if (this.state.selectedModel === 0) {
      return (
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <ModelView
            modelView={this.state.modelViews[this.state.selectedModel]}
            relationships={this.state.relationships}
          />
        </div>
      );
      11;
    }
    return <img src={person} />;
  }
}
export default App;
