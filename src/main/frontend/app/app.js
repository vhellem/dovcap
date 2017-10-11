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
      relationships: null,
      zoom: 1,
      movedX: 0,
      movedY: 0,
      xOffset: 0,
      yOffset: 0,
      modelViewWidth: 0,
      modelViewHeight: 0,
    };
    this.zoom = this.zoom.bind(this);
    this.offsetRight = this.offsetRight.bind(this);
    this.offsetDown = this.offsetDown.bind(this);
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);

      console.log(json);
      this.setState({
        selectedModel: 0,
        modelViews: json.modelViewL,
        relationships: json.relationshipL,
      });
      this.updateWindowDimensions();
      this.zoom(-0.1);
    });
  }
  onChange = activeKey => {
    this.setState({
      selectedModel: parseInt(activeKey),
    });
  };

  zoom(num) {
    let xDiffZoom =
      this.state.modelViewWidth * this.state.zoom -
      this.state.modelViewWidth * (this.state.zoom + num);

    let xDiffMove = this.state.movedX * num;

    let yDiffZoom =
      this.state.modelViewHeight * this.state.zoom -
      this.state.modelViewHeight * (this.state.zoom + num);

    let yDiffMove = this.state.movedY * num;

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

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({
      modelViewWidth: window.innerWidth * 1,
      modelViewHeight: window.innerHeight * 0.9,
    });
  }

  render() {
    if (
      (this.state.selectedModel || this.state.selectedModel === 0) &&
      this.state.modelViews
    ) {
      return (
        <div>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <ModelView
              modelView={this.state.modelViews[this.state.selectedModel]}
              relationships={this.state.relationships}
              zoom={this.state.zoom}
              xOffset={this.state.xOffset}
              yOffset={this.state.yOffset}
              width={this.state.modelViewWidth}
              height={this.state.modelViewHeight}
            />
          </div>
          <Tabs
            activeKey={this.state.selectedModel.toString()}
            onChange={this.onChange}
          >
            {this.state.modelViews.map((modelView, index) => {
              return <TabPane tab={modelView.attributes.title} key={index} />;
            })}
          </Tabs>
          <button className="" onClick={() => this.zoom(0.25)}>
            Zoom in
          </button>
          <button className="" onClick={() => this.zoom(-0.25)}>
            Zoom out
          </button>

          <button className="" onClick={() => this.offsetRight(50)}>
            Left
          </button>
          <button className="" onClick={() => this.offsetRight(-50)}>
            Right
          </button>

          <button className="" onClick={() => this.offsetDown(50)}>
            Up
          </button>
          <button className="" onClick={() => this.offsetDown(-50)}>
            Down
          </button>
        </div>
      );
    }
    return <h1>loading</h1>;
  }
}
export default App;
