import React from 'react';
import { getModelsFromBackend } from './utlities.js';
import {Layer, Rect, Stage, Group} from 'react-konva';


class App extends React.Component {
    render() {
      return (
        <Stage width={700} height={700}>
          <Layer>
            <Rect
              x={10}
              y={10}
              width={50}
              height={50}
               fill={"red"}
              shadowBlur={5}
            />
          </Layer>
        </Stage>

          );
    }
  }



export default App;
