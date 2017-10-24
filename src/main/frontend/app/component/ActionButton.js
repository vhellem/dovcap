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
    console.log(x);
    //debugger;
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
          stroke="#b47f10"
          strokeWidth={1}
          cornerRadius={0}
          onClick={this.handleClick}
          fillLinearGradientStartPoint= {{ x : 0, y : 0}}
          fillLinearGradientEndPoint= {{ x : 0, y : 50}}
          fillLinearGradientColorStops= {[0, "#f4cb23", 1, "#f0ae1b"]}
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
