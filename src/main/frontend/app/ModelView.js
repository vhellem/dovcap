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
      x: 5, //We dont want the root container to lie at the Stage-border
      y: 5
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
            parentWidth={this.state.width * 0.99}
            parentHeight={this.state.height * 0.99}
            parentX={this.state.x}
            parentY={this.state.y}
          />
        </Layer>
      </Stage>
    );
  }
}

export default ModelView;
