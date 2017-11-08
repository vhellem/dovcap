import React from 'react';

class LoadView extends React.Component {
  constructor(props) {
    super(props);
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(input) {
    console.log(input);
    var ref = this;
    if (input.length == 1) {
      var file = input[0];
      var fr = new FileReader();
      fr.onload = receivedText;
      fr.readAsText(file);
    }
    else {
      console.log("No file chosen!");
    }

    function receivedText() {
      var json = JSON.parse(fr.result);
      console.log(ref, json);
      ref.props.renderEnvironment(json);
    }
  }

  render() {
    return (
      <div className="dialog" style={{ width: this.props.width, height: this.props.height }}>
        <div className="close">
          <i className="fa fa-times" onClick={() => this.props.toggle("LoadView")}></i>
        </div>
        <div className="content tree">
          <input type="file" onChange={(e) => this.handleChange(e.target.files)} />
        </div>
      </div>
    )
  }
}

export default LoadView;
