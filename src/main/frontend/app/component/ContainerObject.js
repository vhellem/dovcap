import React from 'react';
import { Rect, Group, Text, Image } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';
import ActionButton from './ActionButton.js';
import Container from '../Container.js';

function importAll(r) {
  const images = {};
  r.keys().map(item => {
    images[item.replace('./', '')] = r(item);
    return null;
  });
  return images;
}

const images = importAll(require.context('../image/', false, /\.(png|jpe?g|svg)$/));

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
      id: containerJson.objectReference.id
    };

    // console.log(this.props.container.name);

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
          image
        });
        this.drawImage();
      };
    }

    this.drawImage = this.drawImage.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    const containerJson = nextProps.container;
    const width = containerJson.attributes.scaleWidth * nextProps.parentWidth;
    const height = containerJson.attributes.scaleHeight * nextProps.parentHeight;
    const x = nextProps.parentX + containerJson.attributes.scaleX * nextProps.parentWidth;
    const y = nextProps.parentY + containerJson.attributes.scaleY * nextProps.parentHeight;

    this.setState({
      width,
      height,
      x,
      y
    });
    // fix undefined

    if (this.state.image) {
      this.drawImage();
    }

    const emitter = ObjectEmitter;
    emitter.emit(this.state.id, x, y, width, height);
  }


  componentWillUnMount() {
    // This does not work, but should be fixed in relationships?
    const emitter = ObjectEmitter;
    emitter.emit(this.state.id, -1, -1, -1, -1);
  };

  handleClick = () => {
    const emitter = ObjectEmitter;
    if (this.state.name === 'Tasks') {
      emitter.emit('tasks');
    }
    if (this.state.name === 'Users') {
      emitter.emit('Users');
    }
  };

  componentWillMount() {
    const emitter = ObjectEmitter;
    emitter.emit(this.state.id, this.state.x, this.state.y, this.state.width, this.state.height);
  }

  handleDragMove = e => {
    this.setState({
      x: e.target.position().x,
      y: e.target.position().y
    });

    const emitter = ObjectEmitter;
    emitter.emit(this.state.id, this.state.x, this.state.y, this.state.width, this.state.height);
  };

  drawImage() {
    this.setState({
      imageWidth: this.state.image.naturalHeight,
      imageHeight: this.state.image.naturalWidth
    });
  }

  render() {
    const children =
      this.props.container.children.length > 0
        ? this.props.container.children.map(child => {
            if (child.type === 'test') {
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
    let imageHeight = this.state.height;
    let imageWidth = this.state.imageHeight / this.state.imageWidth * this.state.height;

    const ratio = imageWidth / (this.state.width / 2);
    if (ratio > 1) {
      imageHeight = imageHeight / ratio;
      imageWidth = imageWidth / ratio;
    } else {
      imageHeight = imageHeight / 1.3;
      imageWidth = imageWidth / 1.3;
    }

    let col = '#FFFFFF';
    let fontSize = 7;
    let offSetX = 0;

    if (this.props.container.type === 'Role (Actor)') {
      col = '#FFEEAA';
    } else if (this.props.container.type === 'Property (EKA)') {
      col = '#bed08c';
    } else if (this.props.container.type === 'Button (CVW)') {
      col = 'lightblue';
    }

    if (this.props.container.name === 'CVW_LeftPane') {
      col = 'FF0000';
    }
    if (this.props.container.name === 'CVW_MenuLevel1') {
      col = 'PowderBlue';
      fontSize = 0;
    }
    if (this.props.container.name === 'CVW_Workspace') {
      col = 'PowderBlue';
    }

    if (
      this.props.container.name === 'Cost Estimator' ||
      this.props.container.name === 'Dicipline Lead' ||
      this.props.container.name === 'Concept Designer' ||
      this.props.container.name === 'Project Leader'
    ) {
      offSetX = 15;
    }

    if (
      this.props.container.name === 'Type' ||
      this.props.container.name === 'TypeId' ||
      this.props.container.name === 'TypeName' ||
      this.props.container.name === 'Description' ||
      this.props.container.name === 'Name'
    ) {
      offSetX = 7;
    }

    if (
      isNaN(this.state.x)
    ) {
      return <Group />;
    }

    return (
      <Group>
        <Rect
          x={this.state.x}
          y={this.state.y}
          width={this.state.width}
          height={this.state.height}
          stroke={'DimGray'}
          cornerRadius={0}
          draggable
          onDragMove={this.handleDragMove}
          fill={col}
          onClick={this.handleClick}
        />
        <Image
          x={this.state.x + (this.state.width / 2 - imageWidth) / 2}
          y={this.state.y + (this.state.height - imageHeight) / 2}
          height={imageHeight}
          width={imageWidth}
          image={this.state.image}
          offsetX={offSetX}
          onClick={this.handleClick}
        />
        <Text
          width={this.state.width * (1 / 2)}
          height={this.state.height}
          align="center"
          x={this.state.x + this.state.width * (1 / 2)}
          y={this.state.y + this.state.height / 2 - 7}
          text={this.state.name}
          witdth={14}
          fontSize={fontSize}
          fontFamily="Arial"
        />
        {children}
      </Group>
    );
  }
}

export default ContainerObject;
