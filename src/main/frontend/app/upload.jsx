import React, { Component } from 'react';
import { getModelNamesFromBackend } from './utlities';

class Uploader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: [],
    };
  }
  componentWillMount() {
    fetch('http://localhost:8080/api/getModelNames')
      .then(response => response.json())
      .then(data => {
        console.log('Data:', data);
        this.setState({ data });
      }).catch(err => console.error(err.toString()));
  }
  sendFile() {
    const data = new FormData();
    const fileData = document.querySelector('input[type="file"]').files[0];
    data.append(fileData);
    fetch('http://localhost:8080/api/uploadModel', {
      method: 'POST',
      body: data,
    }).then(res => {
      if (res.ok) {
        console.log('Upload: Perfect!');
      } else if (res.status === 401) {
        console.log('Upload: OOPS!');
      }
    }, err => {
      console.log('Error submitting form!', err);
    });
  }

  render() {
    const fileNames = this.state.data.map((file) =>
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
        <form encType="multipart/form-data" action="">
          <input type="file" name="filename" defaultValue="fileName" />
          <input type="button" value="upload" />
        </form>
      </div>
    );
  }
}
export default Uploader;
