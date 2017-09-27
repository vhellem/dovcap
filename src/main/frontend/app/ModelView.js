import React from 'react';
import ReactDOM from 'react-dom';
import Container from './Container.js';

class ModelView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: [],
      width: 0,
      height: 0,
      x: 0,
      y: 0
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
    this.setState({ width: window.innerWidth, height: window.innerHeight });
  }
  render() {
    var modelView = this.props.modelView;
    this.setState({ children: modelView.children });
    return (
      <Stage width={this.width} height={this.height}>
        <Layer>
          <Container
            container={this.state.children[0]}
            parentWidth={this.state.width}
            parentHeight={this.state.height}
          />
        </Layer>
      </Stage>
    );
  }
}

export default ModelView;
