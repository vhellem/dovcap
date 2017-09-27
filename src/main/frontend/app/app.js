import React from 'react';
import { getModelsFromBackend, getDummyData } from './utlities.js';
import { Layer, Rect, Stage, Group } from 'react-konva';
import Container from './Container';

class App extends React.Component {
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);
      console.log(json);
    });
  }

  render() {
    return <Container title="Top-Container2" />;
  }
}

export default App;
