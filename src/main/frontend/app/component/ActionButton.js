/* eslint no-debugger: 0 */
/* eslint no-eval: 0 */
import React from 'react';
import { Rect, Group, Text } from 'react-konva';

class ActionButton extends React.Component {
  constructor(props) {
    super(props);

    const containerJson = props.container;

    this.state = {
      width: containerJson.attributes.scaleWidth * props.parentWidth,
      height: containerJson.attributes.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.attributes.scaleX * props.parentWidth,
      y: props.parentY + containerJson.attributes.scaleY * props.parentHeight,
      name: containerJson.name,
      type: containerJson.type,
      action: containerJson.objectReference.valueset.description,
    };
  }
  componentWillReceiveProps(nextProps) {
    const containerJson = nextProps.container;
    this.setState({
      width: containerJson.attributes.scaleWidth * nextProps.parentWidth,
      height: containerJson.attributes.scaleHeight * nextProps.parentHeight,
      x:
        nextProps.parentX +
        containerJson.attributes.scaleX * nextProps.parentWidth,
      y:
        nextProps.parentY +
        containerJson.attributes.scaleY * nextProps.parentHeight,
      action: containerJson.objectReference.valueset.description,
    });
  }

  handleClick = () => {
    const x = String(this.state.action).trim();
    debugger;
    eval(x);
  };

  render() {
    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y}
          width={this.state.width}
          height={this.state.height}
          stroke={1}
          cornerRadius={0}
          onClick={this.handleClick}
          fill="green"
        />
        <Text
          width={this.state.width}
          height={this.state.height}
          align="center"
          x={this.state.x}
          y={this.state.y + 10}
          text={this.state.name}
          fontSize={8}
          fontFamily="Arial"
          onClick={this.handleClick}
        />
      </Group>
    );
  }
}

export default ActionButton;
