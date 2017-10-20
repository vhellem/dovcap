import React, { Component } from 'react';
import Navigation from './component/navigation';
import { selectModelFromBackend } from './utlities';
const request = require('superagent');

class Landingpage extends Component {
  constructor(props) {
    super(props);
    this.state = {
      fileNames: [],
      selectedModel: '',
    };
  }
  componentWillMount() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(fileNames => {
        this.setState({ fileNames });
      }).catch(err => console.error(err.toString()));
  }
  handleSelect(model) {
    this.setState({ selectedModel: model });
  }
  createGroupedArray = (arr, chunkSize) => {
    const groups = [];
    let i;
    for (i = 0; i < arr.length; i += chunkSize) {
      groups.push(arr.slice(i, i + chunkSize));
    }
    return groups;
  }
  render() {
    const groups = this.createGroupedArray(this.state.fileNames, 30);
    const groupLists = groups.map(ls =>
        <ul key={ls[0]} className="landing-page-list">
          {ls.map(val =>
              <li key={val} onClick={() => this.handleSelect(val)}>
              {val}
              </li>
          )}
        </ul>
    );
    return (
      <div className="landing-page-container">
        <h3> Select a model: </h3>
        <hr />
        <div className="landing-page-list-container">{groupLists}</div>
        <div className="landing-page-selected">
          <h3>Selected model:</h3>
          <hr />
          { this.state.selectedModel ? (
            <div>
              <h4><strong>{this.state.selectedModel}</strong></h4>
              <button className="button" onClick={() => this.props.handleSelect(this.state.selectedModel)}> Load model in workplace</button>
            </div>
          ) : (
            'No model selected'
          )}
        </div>
      </div>
    );
  }
}
export default Landingpage;
