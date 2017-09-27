import React from 'react';
import ReactDOM from 'react-dom';
import Container from './Container.js';
import { Layer, Rect, Stage, Group } from 'react-konva';

class ModelView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: props.modelView.children,
      width: 0,
      height: 0,
      x: 0,
      y: 0
    };
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }
  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({ width: window.innerWidth * 0.9, height: window.innerHeight * 0.9 });
  }
  render() {
    return (
      <Stage width={this.state.width} height={this.state.height}>
        <Layer>
          <Container
            container={this.state.children[0]}
            parentWidth={this.state.width}
            parentHeight={this.state.height}
            parentX={this.state.x}
            parentY={this.state.y}
          />
        </Layer>
      </Stage>
    );
  }
}

export default ModelView;
