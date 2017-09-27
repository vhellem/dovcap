import React from 'react';
import { Layer, Rect, Stage, Group } from 'react-konva';

export default class Container extends React.Component {
  render() {
    return (
      <div>
        <h1>{this.props.title}</h1>
        <Stage width={700} height={700}>
          <Layer>
            <Rect x={10} y={10} width={200} height={500} shadowBlur={5} stroke={2} />
          </Layer>
        </Stage>
      </div>
    );
  }
}
