import React from 'react';

class TypeView extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return(
      <div className="dialog" style={{width: this.props.width, height: this.props.height}}>
      <button onClick={() => this.props.toggle("TypeView")}> Close
      </button>
      TypeView
      </div>
    )
  }
}


export default TypeView;
