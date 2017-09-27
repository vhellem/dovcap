import React from 'react';
//import Container from './container.js';
import View from './view.js';

class Workspace extends React.Component {
  constructor(props, name) {
    super(props);
    this.state = {
      name: name
    };
  }
  /*componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);
      console.log(json);
    });
  }*/
  render() {
    let views = [];
    for (let i=0; i < 6; i++) {
      views.push(<View id={i} key={i}/>);
    }
    return (
      <div id="site">
        <header id="mainHeader">
          <h1>Header</h1>
        </header>
        <aside id="taskbar"><h3>Aside</h3></aside>
        <main id="content">
          {views}
        </main>
      </div>
    )
  }
}
export default Workspace;
