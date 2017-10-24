import React from 'react';

class TreeView extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return(
      <div className="dialog" style={{width: this.props.width, height: this.props.height}}>
      <button onClick={() => this.props.toggle("TreeView")}> Close
      </button>
Tree view aa
      </div>
    )
  }
}


export default TreeView;
