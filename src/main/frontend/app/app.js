import React from 'react';
import Icon from 'antd/lib/icon';
import 'antd/lib/tabs/style/css';
import Workplace from './workplace';
import Uploader from './upload';
import Landingpage from './landingpage';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedTab: '0',
      model: 'simple.kmv',
      activeComponent: <Landingpage />,
    };
    App.propTypes = {
      model: String.isRequired,
      onModelSelect: Function.isRequired,
    };
    this.handleSelect = this.handleSelect.bind(this);
  }
  onChange = activeKey => {
    this.setState({
      selectedTab: activeKey,
    });
  };
  handleSelect(model) {
    console.log('Selecting model! ', model);
    this.setState({ model });
  }
  loadWorkspace() {
    console.log('Load workspace!');
    this.setState({ activeComponent: <Workplace model={this.state.model} /> });
  }
  render() {
    const comp = this.state.activeComponent;
    return (
      <div>
        <ul className="landing-page-navigation">
          <div className="nav-inner">
            <li className="nav-item nav-brand">
              <a className="nav-link"
                onClick={() => this.setState({
                  activeComponent: <Landingpage handleSelect={this.handleSelect} /> })}
              >
                DOVCAP
              </a>
            </li>
            <li className="nav-item">
              <a className="nav-link"
                onClick={() =>
                  this.setState({ activeComponent: <Workplace model={this.state.model} /> })}
              >Workplace</a>
            </li>
            <li className="nav-item">
              <a className="nav-link"
                onClick={() => this.setState({ activeComponent: <Uploader /> })}
              ><Icon type="file-add" />Upload</a>
            </li>
          </div>
        </ul>
          { comp }
      </div>
    );
  }
}
export default App;
