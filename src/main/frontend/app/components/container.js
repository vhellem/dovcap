import React from 'react';
import View from './view.js';

class Container extends React.Component {

  render() {
    console.log(this.props.children);
    return (
      //<div>{this.props.children}</div>
      <View/>
    )

  }
}
export default Container;
