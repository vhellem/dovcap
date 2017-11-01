import React from 'react';
import Container from './Container.js';
import Relationship from './component/Relationship.js';
import { Layer, Stage } from 'react-konva';
import Select from 'react-select';
import 'react-select/dist/react-select.css';

let options = []; // those we initialy want 2 see
const alreadyAppendedOptions = [];

class ModelView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      children: props.modelView.children,
      relationships: props.relationships,
      x: 5, // Some space in between stage and top-container is needed
      y: 5,
      zoom: props.zoom,
      xOffset: props.xOffset,
      yOffset: props.yOffset,
      width: props.width,
      height: props.height,
      relTypesSelected: [
        { value: 'Relationship', label: 'Relationship' }, // those we initialy want 2 see
        { value: 'Has property', label: 'Has property' },
      ],
    };
    this.handleSelectChange = this.handleSelectChange.bind(this);
  }

  componentWillReceiveProps(newProps) {
    this.setState({
      children: newProps.modelView.children,
      relationships: newProps.relationships,
      zoom: newProps.zoom,
      xOffset: newProps.xOffset,
      yOffset: newProps.yOffset,
      width: newProps.width,
      height: newProps.height,
    });

    for (let i = 0; i < this.state.relationships.length; i++) {
      const opt = {
        value: this.state.relationships[i].type,
        label: this.state.relationships[i].type,
      };
      if (!alreadyAppendedOptions.includes(opt.value)) {
        options.push(opt);
        alreadyAppendedOptions.push(opt.value);
      }
    }
  }

  handleSelectChange(val) {
    this.setState({ relTypesSelected: val });
  }

  render() {
    const visible = this.state.relTypesSelected.map(o => o.value);
    return (
      <div>
        <center>
          <div style={{ width: 500 }}>
            <h3> Show relationship types:</h3>
            <Select
              name="form-field-name"
              value={this.state.relTypesSelected}
              options={options}
              onChange={this.handleSelectChange}
              multi
            />
          </div>
        </center>
        <Stage width={this.state.width} height={this.state.height}>
          <Layer>
            <Container
              container={this.state.children[0]}
              parentWidth={this.state.width * this.state.zoom}
              parentHeight={this.state.height * this.state.zoom}
              parentX={this.state.x + this.state.xOffset}
              parentY={this.state.y + this.state.yOffset}
            />
            {this.state.relationships.map(a => <Relationship data={a} visible={visible} />)}
          </Layer>
        </Stage>
      </div>
    );
  }
}

export default ModelView;
