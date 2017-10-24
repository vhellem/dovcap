import React from 'react';
import { Rect, Group, Text, Image } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';
import ActionButton from './ActionButton.js';

function importAll(r) {
  const images = {};
  r.keys().map(item => {
    images[item.replace('./', '')] = r(item);
    return null;
  });
  return images;
}

const images = importAll(
  require.context('../image/', false, /\.(png|jpe?g|svg)$/),
);

class ContainerObject extends React.Component {
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
      imageWidth: 1,
      imageHeight: 1,
      id: containerJson.objectReference.id,
    };
    if (containerJson.objectReference.valueset.iconProp) {
      let img = containerJson.objectReference.valueset.iconProp;
      img = img.substring(img.lastIndexOf('/') + 1, img.lastIndexOf('.') + 4);
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

  componentWillReceiveProps(nextProps) {
    const containerJson = nextProps.container;
    const width = containerJson.attributes.scaleWidth * nextProps.parentWidth;
    const height =
      containerJson.attributes.scaleHeight * nextProps.parentHeight;
    const x =
      nextProps.parentX +
      containerJson.attributes.scaleX * nextProps.parentWidth;
    const y =
      nextProps.parentY +
      containerJson.attributes.scaleY * nextProps.parentHeight;

    this.setState({
      name: containerJson.name
    })

    this.setState({
      width,
      height,
      x,
      y,
    });
    // fix undefined

    if (this.state.image) {
      this.drawImage();
    }

    const emitter = ObjectEmitter;
    emitter.emit(this.state.id, x, y, width, height);
  }

  handleDragMove = e => {
    this.setState({
      x: e.target.position().x,
      y: e.target.position().y,
    });

    const emitter = ObjectEmitter;
    emitter.emit(
      this.state.id,
      this.state.x,
      this.state.y,
      this.state.width,
      this.state.height,
    );
  };

  drawImage() {
    this.setState({
      imageWidth: this.state.image.naturalHeight,
      imageHeight: this.state.image.naturalWidth,
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

    this.props.propertiesView(properties);

  }

  render() {
    const children =
      this.props.container.children.length > 0
        ? this.props.container.children.map(child => {
          if (child.type !== 'Action Button') {
            return (
              <ContainerObject
                container={child}
                parentWidth={this.state.width}
                parentHeight={this.state.height}
                parentX={this.state.x}
                parentY={this.state.y}
                key={child.id}
                fullData={this.props.fullData}
                renderEnvironment={this.props.renderEnvironment}
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
              />
            );
          }
        })
        : null;
    let imageHeight = this.state.height;
    let imageWidth =
      this.state.imageHeight / this.state.imageWidth * this.state.height;

    const ratio = imageWidth / (this.state.width / 2);
    if (ratio > 1) {
      imageHeight = imageHeight / ratio;
      imageWidth = imageWidth / ratio;
    } else {
      imageHeight = imageHeight / 1.3;
      imageWidth = imageWidth / 1.3;
    }

    //distinguisher
    var strokeWidth = 0.3;
    var stroke = "black";
    var color1;
    var color2;
    if (this.props.container.type === "Container") {
      color1 = "#ffffff";
      color2 = "#e5e5e5";
      stroke = "#7b7d81";
      strokeWidth = 0.7;
    }
    else if (this.props.container.type === "Organization") {
      color1 = "#d7e4fc";
      color2 = "#91ace5";
      stroke = "#5f7ca5";
      strokeWidth = 1;
    }
    else if (this.props.container.type === "Person") {
      color1 = "#d3e6d3";
      color2 = "#a7d082";
      stroke = "#7aab5e";
      strokeWidth = 1;
    }
    else {
      color1 = "black";
      color2 = "black";
    }

    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y}
          width={this.state.width}
          height={this.state.height}
          strokeWidth={strokeWidth}
          stroke={stroke}
          cornerRadius={0}
          draggable
          onDragMove={this.handleDragMove}
          onClick={this.handleClick.bind(this)}

          fillLinearGradientStartPoint= {{ x : 0, y : 0}}
          fillLinearGradientEndPoint= {{ x : 0, y : 50}}
          fillLinearGradientColorStops= {[0, color1, 1, color2]}
        />
        <Image
          x={this.state.x + (this.state.width / 2 - imageWidth) / 2}
          y={this.state.y + (this.state.height - imageHeight) / 2}
          height={imageHeight}
          width={imageWidth}
          image={this.state.image}
        />
        <Text
          width={this.state.width * (1 / 2)}
          height={this.state.height}
          align="center"
          x={this.state.x + this.state.width * (1 / 2)}
          y={this.state.y + this.state.height / 2 - 7}
          text={this.state.name}
          witdth={14}
          fontSize={12}
          fontFamily="Arial"
        />
        {children}
      </Group>
    );
  }
}

export default ContainerObject;
