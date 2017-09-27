import React from 'react';
import ReactDOM from 'react-dom';

class Container extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: [],
      scaleWidth: 0,
      scaleHeight: 0,
      scaleX: 0,
      scaleY: 0,
      width: 0,
      height: 0,
      x: 0,
      y: 0
    };
  }

  render() {
    var containerJson = this.props.container;
    this.setState({
      scaleWidth: containerJson.scaleWidth,
      scaleHeight: containerJson.scaleHeight,
      scaleX: containerJson.scaleX,
      scaleY: containerJson.scaleY,
      width: containerJson.scaleWidth * props.parentWidth,
      height: containerJson.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.scaleX * props.parentWidth,
      y: props.parentY + containerJson.scaleY * props.parentHeight
    });

    return (
      <Rect x={this.state.x} y={this.state.y} width={this.state.width} height={this.state.height} />
    );
  }
}

export default Container;
