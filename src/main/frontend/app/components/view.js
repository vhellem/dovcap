import React from 'react';

class View extends React.Component {
  constructor(props) {
    super(props);
    this.state = {isToggleOn: true};

    this.clickety = this.clickety.bind(this);
  }
  clickety() {
    console.log(`HELLO to you too, View_${this.props.id}!`);
  }
  purpleTime() {
    this.setState(prevState => ({
      isToggleOn: !prevState.isToggleOn
    }));
    if (this.state.isToggleOn) {
      document.getElementById(`header_${this.props.id}`).style.color = 'purple';
    }
    else {
      document.getElementById(`header_${this.props.id}`).style.color = 'black';
    }

  }

  render() {
    return (
      <div className={"view_"+this.props.id}>
        <h3 id={"header_"+this.props.id}>view.id = {this.props.id}</h3>
        <button onClick={() => this.purpleTime()}>I have no purplose</button>
      </div>
    )
  }
}
export default View;
