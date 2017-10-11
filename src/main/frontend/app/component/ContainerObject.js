import React from 'react';
import ReactDOM from 'react-dom';
import { Layer, Rect, Stage, Group, Text, Image } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';

function importAll(r) {
  let images = {};
  r.keys().map((item, index) => {
    images[item.replace('./', '')] = r(item);
  });
  return images;
}

const images = importAll(require.context('../image/', false, /\.(png|jpe?g|svg)$/));

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
      id: containerJson.objectReference.id
    };

    if (containerJson.objectReference.valueset.icon) {
      const image = new window.Image();

      image.src = images[containerJson.objectReference.valueset.icon];
      image.onload = () => {
        this.setState({
          image: image
        });
        this.drawImage();
      };
    }
  }

  handleDragMove = (e) => {
  this.state.x = e.target.position()["x"]
  this.state.y = e.target.position()["y"]

  var emitter = ObjectEmitter;
  emitter.emit(this.state.id, this.state.x, this.state.y, this.state.width, this.state.height);
}

  drawImage() {
    var ratio = this.state.width / this.state.image.naturalWidth / 3;
    var width = this.state.image.naturalWidth * ratio;
    var height = this.state.image.naturalHeight * ratio;
    if (height > this.state.height) height = this.state.height;
    var x = this.state.x;
    var y = this.state.y;
    y = y + (this.state.height - height) / 2;

    this.setState({
      imageWidth: width,
      imageHeight: height,
      imageX: x,
      imageY: y
    });
  }

  componentWillReceiveProps(nextProps) {
    var containerJson = nextProps.container;

    this.setState({
      width: containerJson.attributes.scaleWidth * nextProps.parentWidth,
      height: containerJson.attributes.scaleHeight * nextProps.parentHeight,
      x: nextProps.parentX + containerJson.attributes.scaleX * nextProps.parentWidth,
      y: nextProps.parentY + containerJson.attributes.scaleY * nextProps.parentHeight
    });
    //fix undefined

    if (this.state.image) {
      this.drawImage();
    }
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
          onDragMove={this.handleDragMove}
        />
        <Image
          x={this.state.imageX}
          y={this.state.imageY}
          width={this.state.imageWidth}
          height={this.state.imageHeight}
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
          fontFamily="Arial"
        />
      </Group>
    );
  }
}

export default ContainerObject;
