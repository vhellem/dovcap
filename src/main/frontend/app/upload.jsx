import React, { Component } from 'react';
const request = require('superagent');

class Uploader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      fileNames: '',
    };
  }
  componentWillMount() {
    const res = request.get('/api/getModels');
    console.log('Res: ', res);
    /*  this.setState({
      fileNames: json,
    });*/
  }
  render() {
    return (
      <div className="container-fluid">
        <h1>Upload files</h1>
        <form>
          <label>
            <input type="file" />
          </label>
          <button type="submit">Last opp fil</button>
        </form>
      </div>
    );
  }
}
export default Uploader;
