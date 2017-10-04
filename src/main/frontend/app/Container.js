import React from 'react';
import ReactDOM from 'react-dom';
import { Layer, Rect, Stage, Group, Text } from 'react-konva';
import ContainerObject from './ContainerObject.js';

class Container extends React.Component {
  constructor(props) {
    super(props);

    var containerJson = props.container;
    console.log(containerJson);

    this.state = {
      width: containerJson.attributes.scaleWidth * props.parentWidth,
      height: containerJson.attributes.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.attributes.scaleX * props.parentWidth,
      y: props.parentY + containerJson.attributes.scaleY * props.parentHeight,
      name: containerJson.name
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
    //console.log(this.state, 'container');
    var children =
      this.props.container.children.length > 0
        ? this.props.container.children.map(child => {
            if (child.type === 'Container') {
              return (
                <Container
                  container={child}
                  parentWidth={this.state.width}
                  parentHeight={this.state.height}
                  parentX={this.state.x}
                  parentY={this.state.y}
                  key={child.id}
                />
              );
            } else if (child.type !== 'Action Button') {
              return (
                <ContainerObject
                  container={child}
                  parentWidth={this.state.width}
                  parentHeight={this.state.height}
                  parentX={this.state.x}
                  parentY={this.state.y}
                  key={child.id}
                />
              );
            }
          })
        : null;
    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y}
          width={this.state.width}
          height={this.state.height}
          stroke={1}
          cornerRadius={10}
        />
        <Text
          x={this.state.x + 10}
          y={this.state.y + 10}
          width={this.state.width - 10}
          text={this.state.name}
          fontSize={14}
          fontFamily="Arial"
        />
        {children}
      </Group>
    );
  }
}

export default Container;
