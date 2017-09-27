import React from 'react';
import ReactDOM from 'react-dom';
import { Layer, Rect, Stage, Group } from 'react-konva';

class Container extends React.Component {
  constructor(props) {
    super(props);

    var containerJson = props.container;

    this.state = {
      width: containerJson.attributes.scaleWidth * props.parentWidth,
      height: containerJson.attributes.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.attributes.scaleX * props.parentWidth,
      y: props.parentY + containerJson.attributes.scaleY * props.parentHeight
    };
  }
  componentWillReceiveProps(nextProps) {
    var containerJson = nextProps.container;

    this.setState({
      width: containerJson.attributes.scaleWidth * nextProps.parentWidth,
      height: containerJson.attributes.scaleHeight * nextProps.parentHeight,
      x: nextProps.parentX + containerJson.attributes.scaleX * nextProps.parentWidth,
      y: nextProps.parentY + containerJson.attributes.scaleY * nextProps.parentHeight
    });
  }

  render() {
    console.log(this.state, 'container');
    return (
      <Rect
        x={this.state.x}
        y={this.state.y}
        width={this.state.width}
        height={this.state.height}
        fill={'red'}
        shadowBlur={5}
      />
    );
  }
}

export default Container;
