import React, { Component } from 'react';
const Dropzone = require('react-dropzone');
const request = require('superagent');

class Uploader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      fileNames: [],
    };
  }
  componentWillMount() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(fileNames => {
        //  console.log('Data:', data);
        this.setState({ fileNames });
      }).catch(err => console.error(err.toString()));
  }
  dropHandler(file) {
    const modelFile = file[0];
    const modelFileRequest = new FormData();
    modelFileRequest.append('file', modelFile);
    modelFileRequest.append('name', modelFile.name);
    console.log('Post:', modelFile.name, modelFile);
    request.post('/api/uploadFile')
      .send(modelFileRequest)
      .end((err, res) => {
        if (err) {
          console.log(err);
        }
        return res;
      }
    );
  }
  updateModelList() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(fileNames => {
        //  console.log('Data:', data);
        this.setState({ fileNames });
      }).catch(err => console.error(err.toString()));
  }

  render() {
    const fileNames = this.state.fileNames.map((file) =>
      <tr key={file}>
        <td>{file}</td>
        <td><button>Delete</button></td>
      </tr>);

    return (
      <div className="upload-container">
        <h1>Model Upload</h1>
        <h3>Current models</h3>
        <table className="model-table table">
          <thead>
            <tr className="theader">
              <td><strong>Model name</strong></td>
              <td><strong>Delete model</strong></td>
            </tr>
          </thead>
          <tbody>
            {fileNames}
          </tbody>
        </table>
        <h3>Select model to be uploaded: </h3>
        <Dropzone
          className="dropzone-container"
          multiple={false}
          onDrop={this.dropHandler}
        >
          <div>Drop a file, or click to add!</div>
        </Dropzone>
      </div>
    );
  }
}
export default Uploader;
