import React from 'react';
import ReactDOM from 'react-dom';
import Container from './Container.js';
import Relationship from './Relationship.js';
import { Layer, Rect, Stage, Group } from 'react-konva';

class ModelView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: props.modelView.children,
      relationships: props.relationships,
      width: 0,
      height: 0,
      x: 5, //Some space in between stage and top-container is needed
      y: 5
    };
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }
  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({ width: window.innerWidth * 0.9, height: window.innerHeight * 0.9 });
  }
  render() {
    console.log('lol: ', this.props);
    console.log('wtf: ', this.state.relationships);
    return (
      <div>
        {this.state.relationships.map(a => <h1>{a['id']}</h1>)}
        <Stage width={this.state.width} height={this.state.height}>
          <Layer>
            <Container
              container={this.state.children[0]}
              parentWidth={this.state.width * 0.99} //Some space in between stage and top-container is needed
              parentHeight={this.state.height * 0.99}
              parentX={this.state.x}
              parentY={this.state.y}
            />
            {this.state.relationships.map(a => <Relationship data={a} />)}
          </Layer>
        </Stage>
      </div>
    );
  }
}

export default ModelView;
