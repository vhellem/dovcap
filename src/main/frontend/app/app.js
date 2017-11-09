import React from 'react';
import { selectModelFromBackend } from './utlities.js';
import ModelView from './ModelView.js';
import Tabs from 'antd/lib/tabs'; // for js
import 'antd/lib/tabs/style/css';
const TabPane = Tabs.TabPane;
import ObjectEmitter from './component/ObjectEmitter';
import PropertiesView from './component/PropertiesView.js';

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
      direction: '',
      lastScrollPos: 0,
      relTypesSelected: [],
      propertiesView: false,
    };
    this.zoom = this.zoom.bind(this);
    this.offsetRight = this.offsetRight.bind(this);
    this.offsetDown = this.offsetDown.bind(this);
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.propertiesView = this.propertiesView.bind(this);
    this.renderEnvironment = this.renderEnvironment.bind(this);
  }
  componentWillMount() {
    selectModelFromBackend(this.props.match.params.modelID).then(res => {
      const json = JSON.parse(res.text);
      console.log('Whole JSON', json);
      this.renderEnvironment(json);
      this.updateWindowDimensions();
      this.zoom(-0.1);
      this.setState({
        selectedModel: 0,
      });
      if (this.props.match.params.viewID) {
        const model = json.modelViewL.find(
          object => object.attributes.title === this.props.match.params.viewID
        );
        const modelIndex = json.modelViewL.indexOf(model);

        this.setState({
          selectedModel: modelIndex,
        });
      }
    });

    this.addListeningToEvents();
  }

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
    document.addEventListener('keydown', this.handleKeyDown, false);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
    document.removeEventListener('keydown', this.handleKeyDown, false);
  }

  renderEnvironment(json) {
    this.setState({
      fullData: json,
      modelViews: json.modelViewL,
      relationships: json.relationshipL,
      objectViews: json.viewL,
    });
  }

  propertiesView(json, part) {
    // called from properties
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
      properties: json,
    });
  }

  onChange = activeKey => {
    this.setState({
      selectedModel: parseInt(activeKey, 10),
    });
    const emitter = ObjectEmitter;
    emitter.emit('forceUpdate', true);
  };

  addListeningToEvents = () => {
    const emitter = ObjectEmitter;

    emitter.addListener('tasks', () => {
      const newView = this.state.objectViews.find(
        object => object.id === 'UUID4_8193025B-8CA4-4DC4-A444-1F190A41B85B'
      );

      const newModelViews = this.state.modelViews;

      newView.attributes.scaleHeight = 0.5;
      newView.attributes.scaleWidth = 0.5;
      newView.attributes.scaleX = 0;
      newView.attributes.scaleY = 0.51;

      newModelViews[2].children[0].children[2].children.push(newView);

      this.setState({
        modelViews: newModelViews,
      });
    });

    emitter.addListener('Users', () => {
      const newView = this.state.objectViews.find(object => object.id === '_002astd01rqf6b84i23l');

      const newModelViews = this.state.modelViews;

      newView.attributes.scaleHeight = 0.5;
      newView.attributes.scaleWidth = 0.5;
      newView.attributes.scaleX = 0.5;
      newView.attributes.scaleY = 0.51;

      newModelViews[2].children[0].children[2].children.push(newView);

      this.setState({
        modelViews: newModelViews,
      });
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

  selectModel = model => {
    this.setState({ model });
  };

  updateWindowDimensions() {
    this.setState({
      modelViewWidth: window.innerWidth * 1,
      modelViewHeight: window.innerHeight * 0.85,
    });
  }

  handleKeyDown(event) {
    if (event.keyCode === 87) {
      this.offsetDown(50);
    } else if (event.keyCode === 83) {
      this.offsetDown(-50);
    } else if (event.keyCode === 65) {
      this.offsetRight(50);
    } else if (event.keyCode === 68) {
      this.offsetRight(-50);
    } else if (event.keyCode === 90) {
      this.zoom(0.25);
    } else if (event.keyCode === 88) {
      this.zoom(-0.25);
    }
  }

  render() {
    if ((this.state.selectedModel || this.state.selectedModel === 0) && this.state.modelViews) {
      return (
        <div>
          {this.state.propertiesView ? (
            <PropertiesView
              width={300}
              height={400}
              toggle={this.propertiesView}
              properties={this.state.properties.valueset}
            />
          ) : null}
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
              propertiesView={this.propertiesView}
            />
          </div>
          <Tabs activeKey={this.state.selectedModel.toString()} onChange={this.onChange}>
            {this.state.modelViews.map((modelView, index) => {
              return (
                <TabPane tab={modelView.attributes.title} key={index}>
                  {modelView.attributes.title}
                </TabPane>
              );
            })}
          </Tabs>
        </div>
      );
    }
    return <h1>loading</h1>;
  }
}
export default App;
