import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import ModelView from './ModelView.js';
import Tabs from 'antd/lib/tabs'; // for js
import 'antd/lib/tabs/style/css';
const TabPane = Tabs.TabPane;

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
  onChange = activeKey => {
    this.setState({
      selectedModel: parseInt(activeKey)
    });
  };

  render() {
    if ((this.state.selectedModel || this.state.selectedModel === 0) && this.state.modelViews) {
      return (
        <div>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <ModelView
              modelView={this.state.modelViews[this.state.selectedModel]}
              relationships={this.state.relationships}
            />
          </div>
          <Tabs activeKey={this.state.selectedModel.toString()} onChange={this.onChange}>
            {this.state.modelViews.map((modelView, index) => {
              return <TabPane tab={modelView.attributes.title} key={index} />;
            })}
          </Tabs>
        </div>
      );
      11;
    }
    return <h1>loading</h1>;
  }
}
export default App;
