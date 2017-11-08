import React from 'react';
import { Rect, Group, Text } from 'react-konva';
import ContainerObject from './component/ContainerObject.js';
import ActionButton from './component/ActionButton.js';

class Container extends React.Component {
  constructor(props) {
    super(props);

    const containerJson = props.container;

    this.state = {
      width: containerJson.attributes.scaleWidth * props.parentWidth,
      height: containerJson.attributes.scaleHeight * props.parentHeight,
      x: props.parentX + containerJson.attributes.scaleX * props.parentWidth,
      y: props.parentY + containerJson.attributes.scaleY * props.parentHeight,
      name: containerJson.name,
    };
  }
  componentWillReceiveProps(nextProps) {
    const containerJson = nextProps.container;

    this.setState({
      width: containerJson.attributes.scaleWidth * nextProps.parentWidth,
      height: containerJson.attributes.scaleHeight * nextProps.parentHeight,
      x: nextProps.parentX + containerJson.attributes.scaleX * nextProps.parentWidth,
      y: nextProps.parentY + containerJson.attributes.scaleY * nextProps.parentHeight,
    });
  }

  handleClick() {
    console.log("click", this, this.state);
    console.log("data", this.props.fullData);
    // this.setState({
    //   name: "Pes"
    // })
    var newJson = this.props.fullData;
    var properties = null;
    //find properties
    for (let prop of this.props.fullData.viewL) {
      if (prop.objectReference.id === this.state.id) {
        properties = prop.objectReference;
      }
    }

    //newJson.modelViewL[0].children[0].children[1].children[1].children[0].name="kk"

    console.log("Properties", properties);
    //this.props.propertiesView(properties);

  }


  render() {
    const children =
      this.props.container.children.length > 0
        ? this.props.container.children.map(child => {
            if (child.type === 'View') {
              return (
                <Container
                  container={child}
                  parentWidth={this.state.width}
                  parentHeight={this.state.height}
                  parentX={this.state.x}
                  parentY={this.state.y}
                  key={child.id}
                  fullData={this.props.fullData}
                  propertiesView={this.props.propertiesView}
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
                  fullData={this.props.fullData}
                  propertiesView={this.props.propertiesView}
                />
              );
            } else {
              return (
                <ActionButton
                  container={child}
                  parentWidth={this.state.width}
                  parentHeight={this.state.height}
                  parentX={this.state.x}
                  parentY={this.state.y}
                  key={child.id}
                  fullData={this.props.fullData}
                  propertiesView={this.props.propertiesView}
                />
              );
            }
          })
        : null;

    let col = 'white';
    let fontSize = 7;
    let textColor = 'black';
    let fontStyle = 'normal';
    let align = 'left';
    let padding = 0;
    let strokeColor = 'DimGray';
    let rectangleYPadding = 0;

    if (this.props.container.name === 'AKM Solution Developer Workplace') {
      col = '#bfd4d9';
      fontSize = 20;
      textColor = '#666666';
    }
    if (this.props.container.name === 'DOVCAP Project : Buttons / Close workarea ') {
      col = '#9cc7ce';
      fontStyle = 'bold';
      padding = -3;
    }
    if (
      this.props.container.name ===
      'Copyright (c) 2008 Active Knowledge Modeling. All Rights Reserved.'
    ) {
      col = '#9cc7ce';
      fontStyle = 'bold';
      fontSize = 10;
      align = 'center';
      padding = -6;
    }
    if (this.props.container.name === 'Workplace') {
      col = '#9cc7ce';
    }
    if (this.props.container.name === 'CVW_ShortCutBar') {
      //return <Group />;
      col = '#bfd4d9';
      strokeColor = 0
      fontSize = 0;
      rectangleYPadding = 10

    }

    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y + rectangleYPadding}
          width={this.state.width}
          height={this.state.height}
          cornerRadius={5}
          stroke={strokeColor}
          draggable
          fill={col}
        />
        <Text
          x={this.state.x + 10}
          y={this.state.y + 10}
          width={this.state.width - 10}
          text={this.state.name}
          fontSize={fontSize}
          fontFamily="Arial"
          fill={textColor}
          fontStyle={fontStyle}
          align={align}
          padding={padding}
        />
        {children}
      </Group>
    );
  }
}

export default Container;
