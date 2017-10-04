import React from 'react';
import ReactDOM from 'react-dom';
import Container from './Container.js';
import { Layer, Arrow, Stage, Group, Text } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';

class Relationship extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      id: '',
      name: '',
      children: null,
      fromPos: { left: 30, top: 30, width: 100, height: 100 },
      toPos: { left: 200, top: 200, width: 100, height: 100 },
      minFrom: [0, 0],
      minTo: [0, 0],
      data: props.data,
      fromId: props.data['valueset']['origin_href'].substring(1),
      toId: props.data['valueset']['target_href'].substring(1),
      textFrom: [0, 0],
      textTo: [0, 0]
    };
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }
  componentDidMount() {
    console.log('hdlfalskjdfklsdf');
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);

    var emitter = ObjectEmitter;
    console.log('lolol fromId: ', this.state.fromId);
    console.log('lolol toId:', this.state.toId);

    emitter.addListener(this.state.fromId, (x, y, width, height) => {
      console.log('theeee position of from: ', x, y, width, height);
      this.setState({
        fromPos: { left: x, top: y, width: width, height }
      });
    });

    emitter.addListener(this.state.toId, (x, y, width, height) => {
      console.log('theeee position of to: ', x, y, width, height);
      this.setState({
        toPos: { left: x, top: y, width: width, height }
      });
    });
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({ width: window.innerWidth * 0.9, height: window.innerHeight * 0.9 });
  }
  render() {
    function getRectangleNodes(left, top, width, height) {
      return [
        [left + width / 2, top],
        [left + width, top + height / 2],
        [left + width / 2, top + height],
        [left, top + height / 2]
      ];
    }

    function squareDistance(x1, y1, x2, y2) {
      return Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2);
    }

    function getTextPosition(x1, y1, x2, y2, distanceFromObject, rightPerpendicular) {
      const perpendicularDistanceFromLine = 20;

      var a = Math.sqrt(distanceFromObject ** 2 / (2 * ((x2 - x1) * 2 + (y2 - y1) ** 2)));
      var x = x1 + (x2 - x1) * a;
      var y = y1 + (y2 - y1) * a;
      //console.log(a);

      var a2 = Math.sqrt(
        perpendicularDistanceFromLine ** 2 / (2 * ((x2 - x1) * 2 + (y2 - y1) ** 2))
      );

      if (rightPerpendicular) {
        x += (y2 - y1) * a2;
        y += (x1 - x2) * a2;
      } else {
        x += (y1 - y2) * a2;
        y += (x2 - x1) * a2;
      }

      //console.log('a2:', a2);

      return [x, y];
    }
    var fromNodes = getRectangleNodes(
      this.state.fromPos.left,
      this.state.fromPos.top,
      this.state.fromPos.width,
      this.state.fromPos.height
    );

    var toNodes = getRectangleNodes(
      this.state.toPos.left,
      this.state.toPos.top,
      this.state.toPos.width,
      this.state.toPos.height
    );

    var minDistance = 999999999;

    for (var i = 0; i < fromNodes.length; i++) {
      for (var j = 0; j < toNodes.length; j++) {
        var d = squareDistance(fromNodes[i][0], fromNodes[i][1], toNodes[j][0], toNodes[j][1]);
        if (d < minDistance) {
          minDistance = d;
          this.state.minFrom = fromNodes[i];
          this.state.minTo = toNodes[j];
        }
      }
    }

    //todo: make more general
    var rightPerpendicular = true;
    if (this.state.minTo[1] < this.state.minFrom[1]) {
      rightPerpendicular = false;
    }

    var toDist = 100;
    if (this.state.minTo[0] < this.state.minFrom[1]) {
      toDist = 20;
    }

    this.state.textFrom = getTextPosition(
      this.state.minFrom[0],
      this.state.minFrom[1],
      this.state.minTo[0],
      this.state.minTo[1],
      30,
      rightPerpendicular
    );
    this.state.textTo = getTextPosition(
      this.state.minTo[0],
      this.state.minTo[1],
      this.state.minFrom[0],
      this.state.minFrom[1],
      toDist,
      !rightPerpendicular
    );
    console.log('textFrom', this.state.textFrom);

    return (
      <Group>
        <Arrow
          x={this.state.minFrom[0]}
          y={this.state.minFrom[1]}
          points={[
            0,
            0,
            this.state.minTo[0] - this.state.minFrom[0],
            this.state.minTo[1] - this.state.minFrom[1]
          ]}
          pointerLength={5}
          pointerWidth={5}
          fil="black"
          stroke="black"
          strokeWidth={2}
        />
        <Text
          align="center"
          x={this.state.textFrom[0]}
          y={this.state.textFrom[1]}
          text={'Arrowtekst 1'}
          witdth={14}
          fontFamily="Calibri"
        />

        <Text
          align="center"
          x={this.state.textTo[0]}
          y={this.state.textTo[1]}
          text={'Arrowtekst 2'}
          witdth={14}
          fontFamily="Calibri"
        />
      </Group>
    );
  }
}

export default Relationship;
