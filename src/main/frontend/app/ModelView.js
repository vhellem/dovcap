import React from 'react';
import Container from './Container.js';
import Relationship from './component/Relationship.js';
import { Layer, Stage } from 'react-konva';
import Select from 'react-select';
import 'react-select/dist/react-select.css';

var options = [
  { value: 'Relationship', label: 'Relationship' },
  { value: 'works on', label: 'works on' },
  { value: 'Is', label: 'Is' },
  { value: 'Member', label: 'Member' },
  { value: 'Has property', label: 'Has property' },
  { value: 'Depends on', label: 'Depends on' },
];

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
      relTypesSelected: ["Has property"],
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
  }

  handleSelectChange (val) {
		this.setState({ relTypesSelected: val});
	}

  render() {
    return (
      <div>
        <div style={{marginRight: "700", marginLeft: "60"}}>
          <h3>  Relationship types:</h3>
            <Select
              name="form-field-name"
              value={this.state.relTypesSelected}
              options={options}
              onChange={this.handleSelectChange}
              multi={true}
            />
        </div>
        <Stage width={this.state.width} height={this.state.height}>
          <Layer>
            <Container
              container={this.state.children[0]}
              parentWidth={this.state.width * this.state.zoom}
              parentHeight={this.state.height * this.state.zoom}
              parentX={this.state.x + this.state.xOffset}
              parentY={this.state.y + this.state.yOffset}
            />
            {this.state.relationships.map(a => <Relationship data={a} />)}
          </Layer>
        </Stage>
      </div>
    );
  }
}

export default ModelView;
