import React from 'react';
import Tabs from 'antd/lib/tabs'; // for js
import Icon from 'antd/lib/icon';
import 'antd/lib/tabs/style/css';
import Workplace from './workplace';
import Uploader from './upload';
const TabPane = Tabs.TabPane;

class App extends React.Component {
  constructor() {
    super();
    this.state = {
      selectedTab: '0',
    };
  }
  onChange = activeKey => {
    this.setState({
      selectedTab: activeKey
    });
  };

  render() {
    return (
      <Tabs activeKey={this.state.selectedTab} onChange={this.onChange} type="card">
        <TabPane tab="Workplace" key="0"><Workplace /></TabPane>
        <TabPane tab={<span><Icon type="file-add" />Upload</span>} key="1">
          <Uploader />
        </TabPane>
      </Tabs>
    );
  }
}
export default App;
