import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import ModelView from './ModelView.js';
import Tabs from 'antd/lib/tabs'; // for js
import 'antd/lib/tabs/style/css';
import '../style/bootstrap.css';
import Panel from './site/panel.js'
import PropertiesView from './site/propertiesview.js'

class App extends React.Component {
  constructor() {
    super();
    this.state = {
      selectedModel: false,
      modelViews: null,
      relationships: null,
      zoom: 1,
      movedX: 0,
      movedY: 0,
      xOffset: 0,
      yOffset: 0,
      modelViewWidth: 0,
      modelViewHeight: 0,
      propertiesView: false
    };
    this.zoom = this.zoom.bind(this);
    this.offsetRight = this.offsetRight.bind(this);
    this.offsetDown = this.offsetDown.bind(this);
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
    this.renderEnvironment = this.renderEnvironment.bind(this);
    this.propertiesView = this.propertiesView.bind(this);
  }
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);
      this.renderEnvironment(json);
      this.updateWindowDimensions();
      this.zoom(-0.1);
    });
  }

  renderEnvironment(json) {
    console.log("Whole model render", json);

    this.setState({
      selectedModel: 0,
      fullData: json,
      modelViews: json.modelViewL,
      relationships: json.relationshipL,

    });
  }

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  onChange = activeKey => {
    this.setState({
      selectedModel: parseInt(activeKey, 10),
    });
  };

  zoom(num) {
    const xDiffZoom =
      this.state.modelViewWidth * this.state.zoom -
      this.state.modelViewWidth * (this.state.zoom + num);

    const xDiffMove = this.state.movedX * num;

    const yDiffZoom =
      this.state.modelViewHeight * this.state.zoom -
      this.state.modelViewHeight * (this.state.zoom + num);

    const yDiffMove = this.state.movedY * num;

    if (num > 0 || this.state.zoom + num > 0) {
      this.setState({
        zoom: (this.state.zoom += num),
        xOffset: this.state.xOffset + xDiffMove + xDiffZoom / 2,
        yOffset: this.state.yOffset + yDiffMove + yDiffZoom / 2,
      });
    }
  }

  offsetRight(num) {
    this.setState({
      movedX: (this.state.movedX += num / this.state.zoom),
      xOffset: (this.state.xOffset += num),
    });
  }

  offsetDown(num) {
    this.setState({
      movedY: (this.state.movedY += num / this.state.zoom),
      yOffset: (this.state.yOffset += num),
    });
  }

  updateWindowDimensions() {
    this.setState({
      modelViewWidth: window.innerWidth * 1,
      modelViewHeight: window.innerHeight * 0.9,
    });
  }

  propertiesView(json, part?) {
    console.log("called", json, part);
    //called from properties
    if (part) {
      for (let prop of this.state.fullData.viewL) {
        if (prop.objectReference.id === this.state.properties.id) {
          prop.objectReference.valueset = json;
          this.renderEnvironment(this.state.fullData);
        }
      }
    }

    this.setState({
      propertiesView: !this.state.propertiesView,
      properties: json
    });
  }

  render() {
    if (
      (this.state.selectedModel || this.state.selectedModel === 0) &&
      this.state.modelViews
    ) {
      return (
        <div>
          <Panel
            selectedModel={this.state.selectedModel}
            onChange={this.onChange}
            modelViews={this.state.modelViews}
            zoom={this.zoom}
            offsetRight={this.offsetRight}
            offsetDown={this.offsetDown}
          ></Panel>
          {this.state.propertiesView ?
            <PropertiesView width={300} height={400} toggle={this.propertiesView} properties={this.state.properties.valueset}></PropertiesView>
            : null}
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <ModelView
              modelView={this.state.modelViews[this.state.selectedModel]}
              relationships={this.state.relationships}
              zoom={this.state.zoom}
              xOffset={this.state.xOffset}
              yOffset={this.state.yOffset}
              width={this.state.modelViewWidth}
              height={this.state.modelViewHeight}
              fullData={this.state.fullData}
              renderEnvironment={this.renderEnvironment}
              propertiesView={this.propertiesView}
            />
          </div>
        </div>
      );
    }
    return <h1>loading</h1>;
  }
}
export default App;
