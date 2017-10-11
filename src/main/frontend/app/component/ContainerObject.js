import React from 'react';
import ReactDOM from 'react-dom';
import { Layer, Rect, Stage, Group, Text, Image } from 'react-konva';
import ActionButton from './ActionButton.js';
import Container from '../Container.js';
function importAll(r) {
  let images = {};
  r.keys().map((item, index) => {
    images[item.replace('./', '')] = r(item);
  });
  return images;
}

const images = importAll(
  require.context('../image/', false, /\.(png|jpe?g|svg)$/),
);

import org from '../image/networkdevice.svg';

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
      imageWidth: 1,
      imageHeight: 1,
    };
    if (containerJson.objectReference.valueset.iconProp) {
      var img = containerJson.objectReference.valueset.iconProp;
      img = img.substring(img.lastIndexOf('/') + 1, img.lastIndexOf('.') + 4);
      console.log(img);
      // TODO: Has to set a generic icon value
    }
    if (containerJson.objectReference.valueset.icon) {
      const image = new window.Image();

      image.src = images[containerJson.objectReference.valueset.icon];
      image.onload = () => {
        this.setState({
          image,
        });
        this.drawImage();
      };
    }

    this.drawImage = this.drawImage.bind(this);
  }

  drawImage() {
    console.log('kake');

    var x = this.state.x;
    var y = this.state.y;

    this.setState({
      imageWidth: this.state.image.naturalHeight,
      imageHeight: this.state.image.naturalWidth,
    });
  }

  componentWillReceiveProps(nextProps) {
    var containerJson = nextProps.container;

    this.setState({
      width: containerJson.attributes.scaleWidth * nextProps.parentWidth,
      height: containerJson.attributes.scaleHeight * nextProps.parentHeight,
      x:
        nextProps.parentX +
        containerJson.attributes.scaleX * nextProps.parentWidth,
      y:
        nextProps.parentY +
        containerJson.attributes.scaleY * nextProps.parentHeight,
    });
    // fix undefined

    if (this.state.image) {
      this.drawImage();
    }
  }

  render() {
    var children =
      this.props.container.children.length > 0
        ? this.props.container.children.map(child => {
            if (child.type !== 'Action Button') {
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
              } else {
                  return (
                <ActionButton
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
          dash={[10, 10]}
          cornerRadius={0}
        />
        <Image
          x={this.state.x}
          y={this.state.y}
          height={this.state.height}
          width={
            this.state.imageHeight / this.state.imageWidth * this.state.height
          }
          image={this.state.image}
        />
        <Text
          width={this.state.width * (2 / 3)}
          height={this.state.height}
          align="center"
          x={this.state.x + this.state.width * (1 / 3)}
          y={this.state.y + this.state.height / 2 - 7}
          text={this.state.name}
          witdth={14}
          fontSize={7}
          fontFamily="Arial"
        />
        {children}
      </Group>
    );
  }
}

export default ContainerObject;
