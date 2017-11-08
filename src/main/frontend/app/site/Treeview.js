import React from 'react';

class TreeView extends React.Component {
  constructor(props) {
    super(props);
    this.properties = this.properties.bind(this);
    this.visibility = this.visibility.bind(this);
  }

  properties(id) {
    console.log("click", this, this.state);
    console.log("data", this.props.fullData);
    var newJson = this.props.fullData;
    var properties = null;
    //find properties
    for (let prop of this.props.fullData.viewL) {
      console.log(prop.objectReference.id, id);
      if (prop.id === id) {
        properties = prop.objectReference;
      }
    }

    this.props.propertiesView(properties);
  }

  visibility(id) {
    var objectId = null;
    for (let prop of this.props.fullData.viewL) {
      if (prop.id === id) {
        objectId = prop.objectReference.id;
      }
    }
    this.props.visibility(objectId);
  }


  recurse(data) {
    var html = "<ul>";
    for (var key in data) {
      html += ("<li><span>" + data[key].name + "</span><i class='fa fa-pencil'></i><i class='fa fa-eye'></i></li>");
      if (data[key].children.length > 0) {
        html += "<ul>";
        html += this.recurse(data[key].children);
        html += "</ul>";
      }
    }
    html += '</ul >';
    return (html);
  }

  flattner(data) {
    var flat = [];
    for (var key in data) {
      flat.push(data[key]);
      if (data[key].children.length > 0) {
        var temp = this.flattner(data[key].children);
        for (var k in temp) {
          flat.push(temp[k]);
        }
      }
    }
    return flat;
  }

  render() {
    console.log("open", this.props.fullData);
    var html = "";
    //var html = this.recurse(this.props.fullData.modelViewL[0].children[0].children);
    var data = this.flattner(this.props.fullData.modelViewL[0].children[0].children);
    console.log("End", data);

    const listItems = data.map((item) =>
        <li><span>{item.name}</span><i className='fa fa-pencil' onClick={() => this.properties(item.id)}></i><i className='fa fa-eye' onClick={() => this.visibility(item.id)}></i></li>
    );

    return (
      <div className="dialog">
        <div className="close">
          <i className="fa fa-times" onClick={() => this.props.toggle("TreeView")}></i>
        </div>
        <div className="content tree">
          <ul>
            {listItems}
          </ul>
        </div>
      </div>
    )
  }
}


export default TreeView;
