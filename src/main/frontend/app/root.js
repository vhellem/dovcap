import React from 'react';
import Icon from 'antd/lib/icon';
import 'antd/lib/tabs/style/css';
import App from './app';
import Uploader from './upload';
import Landingpage from './landingpage';
import Main from './main.js';
import { Link } from 'react-router-dom';

class Root extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedTab: '0',
      model: 'simple.kmv',
      activeComponent: <Landingpage handleButtonSelect={model => this.handleSelect(model)} />
    };
  }
  /*
  onChange = activeKey => {
    this.setState({
      selectedTab: activeKey
    });
  };
  handleSelect(model) {
    console.log('Selecting model! ', model);
    this.setState({ model, activeComponent: <App model={model} /> });
  }
  renderWorkspace() {
    console.log('Load workspace!');
    this.setState({
      activeComponent: <Workplace model={this.state.model} />
    });
  }
  renderLandingpage() {
    this.setState({
      activeComponent: <Landingpage handleButtonSelect={model => this.handleSelect(model)} />
    });
  }
  renderUploader() {
    this.setState({
      activeComponent: <Uploader handleButtonSelect={model => this.handleSelect(model)} />
    });
  }
  */
  render() {
    const comp = this.state.activeComponent;
    return (
      <div>
        <ul className="landing-page-navigation">
          <div className="nav-inner">
            <li className="nav-item nav-brand">
              <Link className="nav-link" to="/">
                DOVCAP
              </Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/upload">
                Upload
              </Link>
            </li>
          </div>
        </ul>
        <Main />
      </div>
    );
  }
}
export default Root;
