import React from 'react';
import '../../style/bootstrap.css';
import Tabs from 'antd/lib/tabs'; // for js
import TreeView from './treeview.js';
import TypeView from './typeview.js';

const TabPane = Tabs.TabPane;

class Panel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      treeView: false,
      typeView: false
    };
    this.toggle = this.toggle.bind(this);
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
  }

  render() {
    return (
      <div className="col-12 header">
        {this.state.treeView ?
          <TreeView width={300} height={400} toggle={this.toggle}></TreeView>
          : null}

        {this.state.typeView ?
          <TypeView width={300} height={400} toggle={this.toggle}></TypeView>
          : null}

        <div className="row">

          <div className="col-4">
            <Tabs
              activeKey={this.props.selectedModel.toString()}
              onChange={this.props.onChange}
            >
              {this.props.modelViews.map((modelView, index) => (
                <TabPane tab={modelView.attributes.title} key={index} />
              ))}
            </Tabs>
          </div>

          <div className="col-4">
            <button className="btn button" onClick={() => this.toggle("TreeView")}>
              Tree view
      </button>
            <button className="btn button" onClick={() => this.toggle("TypeView")}>
              Type view
    </button>
            <button className="btn button">
              Save
  </button>
          </div>

          <div className="col-4 icons">

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
