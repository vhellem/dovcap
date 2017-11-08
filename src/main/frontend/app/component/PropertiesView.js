import React from 'react';

class PropertiesView extends React.Component {
  constructor(props) {
    super(props);
    console.log("ready", this.props.properties)
    this.state = { properties: this.props.properties };
    this.onClose = this.onClose.bind(this);
  }

  onChange(event, key) {
    let properties = Object.assign({}, this.state.properties);    //creating copy of object
    properties[key] = event.target.value;                        //updating value
    this.setState({ properties });
  }

  onClose() {
    console.log("Close", this.state)
    this.props.toggle(this.state.properties, true);
  }

  render() {

    const formHtml = Object.keys(this.state.properties).map(key =>
      <div><label>{key}</label><input type='text' value={this.state.properties[key]} onChange={(e) => this.onChange(e, key)} /></div>

    )

    return (
      <div className="dialog" style={{ width: this.props.width }}>
        <div className="close">
          <i className="fa fa-times" onClick={this.onClose}></i>
        </div>
        <div className="content">
          {formHtml}
        </div>
      </div>
    )
  }
}


export default PropertiesView;
