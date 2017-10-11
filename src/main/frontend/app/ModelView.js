import React from 'react';
import ReactDOM from 'react-dom';
import Container from './Container.js';
import Relationship from './component/Relationship.js';
import { Layer, Rect, Stage, Group } from 'react-konva';

class ModelView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: props.modelView.children,
      relationships: props.relationships,
      width: 0,
      height: 0,
      x: 5, // Some space in between stage and top-container is needed
      y: 5,
      zoom: props.zoom,
      xOffset: props.xOffset,
      yOffset: props.yOffset,
      width: props.width,
      height: props.height,
    };
  }

  componentWillReceiveProps(newProps) {
    this.setState({
      children: newProps.modelView.children,
      relationships: newProps.relationships,
      zoom: newProps.zoom,
      xOffset: newProps.xOffset,
      yOffset: newProps.yOffset,
      width: newProps.width,
      height: newProps.height,
    });
  }
  render() {
    return (
      <Stage width={this.state.width} height={this.state.height}>
        <Layer>
          <Container
            container={this.state.children[0]}
            parentWidth={this.state.width * this.state.zoom}
            parentHeight={this.state.height * this.state.zoom}
            parentX={this.state.x + this.state.xOffset}
            parentY={this.state.y + this.state.yOffset}
          />
          <Relationship data={this.state.relationships} />
        </Layer>
      </Stage>
    );
  }
}

export default ModelView;
