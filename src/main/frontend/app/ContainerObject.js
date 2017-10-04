import React from 'react';
import ReactDOM from 'react-dom';
import { Layer, Rect, Stage, Group, Text } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';

class ContainerObject extends React.Component {
  constructor(props) {
    super(props);

    var containerJson = props.container;

    this.state = {
      width: containerJson.attributes.scaleWidth * props.parentWidth,
      height: containerJson.attributes.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.attributes.scaleX * props.parentWidth,
      y: props.parentY + containerJson.attributes.scaleY * props.parentHeight,
      name: containerJson.name,
      type: containerJson.type,
      id: containerJson.objectReference.id
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
    var emitter = ObjectEmitter;
    console.log('yoyoyo: ', this.state.x);
    console.log('tilsvarende ting: ', this.state.id, this.state.name);
    emitter.emit(this.state.id, this.state.x, this.state.y, this.state.width, this.state.height);
    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y}
          width={this.state.width}
          height={this.state.height}
          stroke={1}
          dash={[10, 10]}
          cornerRadius={0}
          draggable={true}
        />
        <Text
          width={this.state.width}
          height={this.state.height}
          align="center"
          x={this.state.x}
          y={this.state.y + 10}
          text={this.state.name}
          witdth={14}
          fontFamily="Arial"
        />
      </Group>
    );
  }
}

export default ContainerObject;
