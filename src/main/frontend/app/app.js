import React from 'react';
import { selectModelFromBackend } from './utlities.js';
import ModelView from './ModelView.js';
import Tabs from 'antd/lib/tabs'; // for js
import 'antd/lib/tabs/style/css';
const TabPane = Tabs.TabPane;
import ObjectEmitter from './component/ObjectEmitter';
import { Link } from 'react-router-dom';
import NavTab from 'react-router-navtab';

var options = [
  { value: 'one', label: 'One' },
  { value: 'two', label: 'Two' },
  { value: 'three', label: 'Three' },
  { value: 'four', label: 'Four' }
];

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
      relTypesSelected: []
    };
    this.zoom = this.zoom.bind(this);
    this.offsetRight = this.offsetRight.bind(this);
    this.offsetDown = this.offsetDown.bind(this);
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
  }
  componentWillMount() {
    console.log(this.props.match.params.modelID);

    selectModelFromBackend(this.props.match.params.modelID).then(res => {
      const json = JSON.parse(res.text);

      this.setState({
        selectedModel: 0,
        modelViews: json.modelViewL,
        relationships: json.relationshipL,
        objectViews: json.viewL
      });
      if (this.props.match.params.viewID) {
        const model = json.modelViewL.find(
          object => object.attributes.title === this.props.match.params.viewID
        );
        const modelIndex = json.modelViewL.indexOf(model);

        this.setState({
          selectedModel: modelIndex
        });
      }

      console.log(json);
      this.updateWindowDimensions();
      this.zoom(-0.1);
    });

    this.addListeningToEvents();
  }

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
        modelViews: newModelViews
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
        modelViews: newModelViews
      });
    });
  };

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
    document.addEventListener('keydown', this.handleKeyDown, false);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
    document.removeEventListener('keydown', this.handleKeyDown, false);
  }

  onChange = activeKey => {
    this.setState({
      selectedModel: parseInt(activeKey, 10)
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
        yOffset: this.state.yOffset + yDiffMove + yDiffZoom / 2
      });
    }
  }

  offsetRight(num) {
    this.setState({
      movedX: (this.state.movedX += num / this.state.zoom),
      xOffset: (this.state.xOffset += num)
    });
  }

  offsetDown(num) {
    this.setState({
      movedY: (this.state.movedY += num / this.state.zoom),
      yOffset: (this.state.yOffset += num)
    });
  }

  selectModel = model => {
    this.setState({ model });
  };

  updateWindowDimensions() {
    this.setState({
      modelViewWidth: window.innerWidth * 1,
      modelViewHeight: window.innerHeight * 0.9
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
          <Tabs activeKey={this.state.selectedModel.toString()} onChange={this.onChange}>
            {this.state.modelViews.map((modelView, index) => {
              const link =
                'model/' + this.props.match.params.modelID + '/' + modelView.attributes.title;
              return (
                <TabPane tab={modelView.attributes.title} key={index}>
                  <Link to={link} />
                </TabPane>
              );
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
