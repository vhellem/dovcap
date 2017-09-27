import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import {Layer, Rect, Stage, Group} from 'react-konva';
import MyRect from './MyRect.js'


class App extends React.Component {
  componentWillMount() {
    getModelsFromBackend().then(res => {
      const json = JSON.parse(res.text);

      console.log(json);
    });
  }
  render() {
    return (
      <Stage width={700} height={700}>
        <Layer>
          <MyRect />
        </Layer>
      </Stage>
    )
  }
}
export default App;
