import React, { Component } from 'react';
import { selectModelFromBackend } from './utlities';
import Navigation from './component/navigation'
const Dropzone = require('react-dropzone');
const request = require('superagent');


class Uploader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      fileNames: [],
      selected: '',
    };
  }
  componentWillMount() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(fileNames => {
        this.setState({ fileNames });
      }).catch(err => console.error(err.toString()));
  }
  getFileNameRows() {
    const fileNames = this.state.fileNames.map((file) =>
      <tr key={file}>
        <td>{file}</td>
        <td><button o nClick={() => this.handleDelete(file)}>Delete</button></td>
      </tr>);
    return fileNames;
  }
  updateModels() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(fileNames => {
        this.setState({ fileNames });
      }).catch(err => console.error(err.toString()));
  }
  dropHandler(files) {
    const file = files[0];
    // const allowedFileExt = ['kmv', 'kmd'];
    // const valid = (allowedFileExt.indexOf(file.name.split('.')[1]) > -1);
    // if (valid) {
    const fileRequest = new FormData();
    fileRequest.append('file', file);
    fileRequest.append('name', file.name);
    request.post('/api/uploadModel')
      .send(fileRequest)
      .end((err, res) => {
        if (err) {
          console.log(err);
        }
        console.log(res);
        this.updateModels();
        return res;
      }
    );
  }
    /* else {
      console.log('File type illegal!');
    }
  }*/
  handleSelect(model) {
    const req = new FormData();
    req.append('name', model);
    console.log(selectModelFromBackend(model));
    /* request.post('/api/selectModel')
      .send(req)
      .end((err, res) => {
        if (err) {
          console.log(err);
        }
        console.log(res.text);
      }); */
    this.props.onModelSelect(model);
  }
  handleDelete(fileName) {
    const req = new FormData();
    req.append('name', fileName.toString());
    request.post('/api/deleteModel')
      .send(req)
      .end((err, res) => {
        if (err) {
          console.log(err);
        }
        this.updateModels();
        return res;
      }
    );
  }
  render() {
    return (
      <div className="upload-container">

        <h1>Model Upload</h1>

        <h3>Select model to be uploaded: </h3>
        <Dropzone
          className="dropzone-container"
          multiple={false}
          onDrop={() => this.dropHandler}
        >
          <div>Drop a file, or click to add!</div>
        </Dropzone>

        <h3>Current models</h3>
        <table className="model-table table">
          <thead>
            <tr className="theader">
              <td><strong>Model name</strong></td>
              <td><strong>Delete model</strong></td>
            </tr>
          </thead>
          <tbody id="upload-table-body">
            {this.state.fileNames.map(file => {
              return (<tr key={file}>
                      <td>{file}</td>
                      <td><button onClick={() => this.handleSelect(file)}>Select</button></td>
                      <td><button onClick={() => this.handleDelete(file)}>Delete</button></td>
                    </tr>);
            })}
          </tbody>
        </table>
      </div>
    );
  }
}
export default Uploader;
