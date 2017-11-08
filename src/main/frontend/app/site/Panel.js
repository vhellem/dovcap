import React from 'react';
import '../../style/bootstrap.css';
import Tabs from 'antd/lib/tabs'; // for js
import TreeView from './treeview.js';
import TypeView from './typeview.js';
import CreateView from './createview.js';
import LoadView from './loadview.js';

const TabPane = Tabs.TabPane;

class Panel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      treeView: false,
      typeView: false,
      createView: false,
      loadView: false

    };
    this.toggle = this.toggle.bind(this);
    this.loadModel = this.loadModel.bind(this);
  }

  loadModel(files) {
    console.log("Load file");

  }

  toggle(name) {
    if (name === "TreeView") {
      this.setState({
        treeView: !this.state.treeView
      });
    }
    else if (name === "TypeView") {
      this.setState({
        typeView: !this.state.typeView
      });
    }
    else if (name === "CreateView") {
      this.setState({
        createView: !this.state.createView
      });
    }
    else if (name === "LoadView") {
      this.setState({
        loadView: !this.state.loadView
      });
    }
  }

  render() {
    return (
      <div className="col-12 header">
        {this.state.treeView ?
          <TreeView toggle={this.toggle} fullData={this.props.fullData} renderEnvironment={this.props.renderEnvironment} propertiesView={this.props.propertiesView} visibility={this.props.visibility} hiddenObjects={this.state.hiddenObjects}></TreeView>
          : null}

        {this.state.typeView ?
          <TypeView toggle={this.toggle} fullData={this.props.fullData} renderEnvironment={this.props.renderEnvironment}></TypeView>
          : null}

        {this.state.createView ?
          <CreateView toggle={this.toggle} fullData={this.props.fullData} renderEnvironment={this.props.renderEnvironment}></CreateView>
          : null}

          {this.state.loadView ?
            <LoadView toggle={this.toggle} fullData={this.props.fullData} renderEnvironment={this.props.renderEnvironment}></LoadView>
            : null}

        <div className="row">

          <div className="col-3">
            <Tabs
              activeKey={this.props.selectedModel.toString()}
              onChange={this.props.onChange}
            >
              {this.props.modelViews.map((modelView, index) => (
                <TabPane tab={modelView.attributes.title} key={index} />
              ))}
            </Tabs>
          </div>

          <div className="col-6">
            <button className="btn button" onClick={() => this.toggle("TreeView")}>
              Element view
      </button>
            {/*<button className="btn button" onClick={() => this.toggle("TypeView")}>
              Type view
            </button>*/}
            <button className="btn button" onClick={() => this.toggle("CreateView")}>
              Create object
    </button>
            <button className="btn button" onClick={() => this.props.clearVisibility()}>
              Reset visibility
</button>
            <button className="btn button" onClick={() => this.props.saveModel()}>
              Save
  </button>
  <button className="btn button" onClick={() => this.toggle("LoadView")}>
  Load
</button>
         </div>

          <div className="col-3 icons">

            <div className="zoom">
              <i className="fa fa-plus" onClick={() => this.props.zoom(0.25)}></i>
              <i className="fa fa-minus" onClick={() => this.props.zoom(-0.25)}></i>
            </div>
            <div className="move">
              <i className="fa fa-arrow-left" onClick={() => this.props.offsetRight(-50)}></i>
              <i className="fa fa-arrow-right" onClick={() => this.props.offsetRight(50)}></i>
              <i className="fa fa-arrow-up" onClick={() => this.props.offsetDown(-50)}></i>
              <i className="fa fa-arrow-down" onClick={() => this.props.offsetDown(50)}></i>
            </div>
          </div>
        </div>

      </div>
    )
  }
}


export default Panel;
