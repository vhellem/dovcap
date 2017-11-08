import React from 'react';

class CreateView extends React.Component {
  constructor(props) {
    super(props);
    this.createObject = this.createObject.bind(this);
    this.searchTree = this.searchTree.bind(this);
  }

  createObject2() {
    console.log("createObject");
    var full = this.props.fullData;
    var targetModelView = this.props.fullData.modelViewL[0].children[0].children[2].children;
    var objectObject = this.props.fullData.objectL[10];
    var objectView = this.props.fullData.viewL[9];
    //assign
    targetModelView.push(objectView);
    full.objectL.push(objectObject);
    full.viewL.push(objectView);
    this.props.renderEnvironment(full);
  }

  createObject() {
    console.log("Create object");
    var id = Math.floor((Math.random() * 100000000) + 1).toString();
    var targetId = document.getElementById("targets").value;
    var typeName = document.getElementById("types").value;
    var name = document.getElementById("name").value;
    console.log("Prepared", id, targetId, typeName, name);
    var full = this.props.fullData;
    //assign target
    var result = this.searchTree(this.props.fullData.modelViewL[0].children[0], targetId);
    var targetModelView = result.children;
    //object view
    var objectObject;
    for (var key in this.props.fullData.objectL) {
      if (this.props.fullData.objectL[key].type === typeName) {
        // objectObject = Object.assign({}, this.props.fullData.objectL[key]);
        objectObject = JSON.parse(JSON.stringify(this.props.fullData.objectL[key]));
        break;
      }
    }
    objectObject.id = id;
    objectObject.name = name;
    //view view
    var objectView;
    for (var key in this.props.fullData.viewL) {
      if (this.props.fullData.viewL[key].type === typeName) {
        // objectView = Object.assign({}, this.props.fullData.viewL[key]);
        objectView = JSON.parse(JSON.stringify(this.props.fullData.viewL[key]));
        break;
      }
    }
    objectView.id = id;
    objectView.attributes.id = id;
    objectView.attributes["xlink:href"] = "#"+id;
    objectView.objectReference.id = id;
    objectView.name = name;

    console.log("Creating", full, targetModelView, objectObject, objectView);

    //assign
    targetModelView.push(objectView);
    full.objectL.push(objectObject);
    full.viewL.push(objectView);
    this.props.renderEnvironment(full);
  }

  searchTree(element, match) {
    if (element.id == match) {
      return element;
    } else if (element.children != null) {
      var i;
      var result = null;
      for (i = 0; result == null && i < element.children.length; i++) {
        result = this.searchTree(element.children[i], match);
      }
      return result;
    }
    return null;
  }

  render() {
    //fill selects
    var targets = [];
    var typesMix = [];

    for (var key in this.props.fullData.viewL) {
      if (this.props.fullData.viewL[key].type === "Container") {
        targets.push(<option value={this.props.fullData.viewL[key].id}>{this.props.fullData.viewL[key].name}</option>);
      }
      if (this.props.fullData.viewL[key].type !== "Container" && this.props.fullData.viewL[key].type !== "Action Button") {
        typesMix.push(this.props.fullData.viewL[key].type);
      }
    }
    var typesTemp = typesMix.filter((v, i, a) => a.indexOf(v) === i);
    var types = [];
    for (var key in typesTemp) {
      types.push(<option value={typesTemp[key]}>{typesTemp[key]}</option>);
    }

    return (
      <div className="dialog" style={{ width: this.props.width }}>
        <div className="close">
          <i className="fa fa-times" onClick={() => this.props.toggle("CreateView")}></i>
        </div>
        <div className="content">
          <label>Target</label>
          <select id='targets'>
            {targets}
          </select>
          <label>Type</label>
          <select id='types'>
            {types}
          </select>
          <label>Name</label>
          <input type="text" id="name" />
          <button className="btn button" onClick={this.createObject}>Create object</button>
        </div>
      </div>
    )
  }

}

export default CreateView;
