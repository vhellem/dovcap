import React from 'react';
import ReactDOM from 'react-dom';
import Container from '../Container.js';
import { Layer, Arrow, Stage, Group, Text } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';

class Relationship extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      id: '',
      name: '',
      children: null,
      data: props.data,
      fromId: props.data['valueset']['origin_href'].substring(1),
      toId: props.data['valueset']['target_href'].substring(1),
      text1: ' ',
      text2: ' ',
      fromPos: { left: 30, top: 30, width: 100, height: 100 },
      toPos: { left: 200, top: 200, width: 100, height: 100 },
    };
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }
  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);

    var emitter = ObjectEmitter;
    var num = this.props.data['type'].split(' ').length;
    var x = this.props.data['type']
      .split(' ')
      .slice(2, num - 1)
      .join(' ');
    this.setState({
      text1: 'has ' + x,
      text2: 'is ' + x + ' of',
    });

    emitter.addListener(this.state.fromId, (x, y, width, height) => {
      this.setState({
        fromPos: { left: x, top: y, width, height },
      });
    });

    emitter.addListener(this.state.toId, (x, y, width, height) => {
      this.setState({
        toPos: { left: x, top: y, width, height },
      });
    });
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({
      width: window.innerWidth * 0.9,
      height: window.innerHeight * 0.9,
    });
  }
  render() {
    var minFrom = [0, 0];
    var minTo = [0, 0];

    var textFrom = [0, 0];
    var textTo = [0, 0];

    function getRectangleNodes(left, top, width, height) {
      return [
        [left + width / 2, top],
        [left + width, top + height / 2],
        [left + width / 2, top + height],
        [left, top + height / 2],
      ];
    }

    function squareDistance(x1, y1, x2, y2) {
      return Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2);
    }

    function getPerpendicularity(x1, y1, x2, y2, horizontal) {
      if (!horizontal) {
        return Math.abs(y2 - y1) / (Math.abs(x2 - x1) + Math.abs(y2 - y1));
      } else {
        return Math.abs(x2 - x1) / (Math.abs(x2 - x1) + Math.abs(y2 - y1));
      }
    }

    function getTextPosition(
      x1,
      y1,
      x2,
      y2,
      distanceFromObject,
      rightPerpendicular,
    ) {
      const perpendicularDistanceFromLine = 20;

      var a = Math.sqrt(
        distanceFromObject ** 2 / (2 * ((x2 - x1) ** 2 + (y2 - y1) ** 2)),
      );
      var x = x1 + (x2 - x1) * a;
      var y = y1 + (y2 - y1) * a;
      var a2 = Math.sqrt(
        perpendicularDistanceFromLine ** 2 /
          (2 * ((x2 - x1) ** 2 + (y2 - y1) ** 2)),
      );

      if (rightPerpendicular) {
        x += (y2 - y1) * a2;
        y += (x1 - x2) * a2;
      } else {
        x += (y1 - y2) * a2;
        y += (x2 - x1) * a2;
      }

      return [x, y];
    }

    function sortByKey(array, key) {
      return array.sort(function(a, b) {
        var x = a[key];
        var y = b[key];
        return x < y ? -1 : x > y ? 1 : 0;
      });
    }

    var fromNodes = getRectangleNodes(
      this.state.fromPos.left,
      this.state.fromPos.top,
      this.state.fromPos.width,
      this.state.fromPos.height,
    );

    var toNodes = getRectangleNodes(
      this.state.toPos.left,
      this.state.toPos.top,
      this.state.toPos.width,
      this.state.toPos.height,
    );

    var possiblePositions = [];
    var minDistance = 999999999;

    for (var i = 0; i < fromNodes.length; i++) {
      for (var j = 0; j < toNodes.length; j++) {
        var fromHori = true;
        var toHori = true;
        if (i % 2 == 0) {
          fromHori = false;
        }
        if (j % 2 == 0) {
          toHori = false;
        }
        var d = squareDistance(
          fromNodes[i][0],
          fromNodes[i][1],
          toNodes[j][0],
          toNodes[j][1],
        );
        possiblePositions.push({
          dist: d,
          from: fromNodes[i],
          to: toNodes[j],
          fromHori,
          toHori,
        });
      }
    }
    possiblePositions = sortByKey(possiblePositions, 'dist');
    possiblePositions = possiblePositions.slice(0, 3);
    var bestPerpendiculatiry = 0;

    for (var i = 0; i < possiblePositions.length; i++) {
      var fromP = getPerpendicularity(
        possiblePositions[i]['from'][0],
        possiblePositions[i]['from'][1],
        possiblePositions[i]['to'][0],
        possiblePositions[i]['to'][1],
        possiblePositions[i]['fromHori'],
      );
      var toP = getPerpendicularity(
        possiblePositions[i]['to'][0],
        possiblePositions[i]['to'][1],
        possiblePositions[i]['from'][0],
        possiblePositions[i]['from'][1],
        possiblePositions[i]['toHori'],
      );
      var currentP = Math.min(fromP, toP);
      if (currentP > bestPerpendiculatiry) {
        bestPerpendiculatiry = currentP;
        minFrom = possiblePositions[i]['from'];
        minTo = possiblePositions[i]['to'];
      }
    }

    // todo: make more general
    var rightPerpendicular = true;
    if (minTo[1] < minFrom[1]) {
      rightPerpendicular = false;
    }

    var toDist = 100;
    if (minTo[0] < minFrom[1]) {
      toDist = 20;
    }
    toDist = 30;

    textFrom = getTextPosition(
      minFrom[0],
      minFrom[1],
      minTo[0],
      minTo[1],
      toDist,
      rightPerpendicular,
    );
    textTo = getTextPosition(
      minTo[0],
      minTo[1],
      minFrom[0],
      minFrom[1],
      toDist,
      !rightPerpendicular,
    );

    return (
      <Group>
        <Arrow
          x={minFrom[0]}
          y={minFrom[1]}
          points={[0, 0, minTo[0] - minFrom[0], minTo[1] - minFrom[1]]}
          pointerLength={5}
          pointerWidth={5}
          fil="black"
          stroke="black"
          strokeWidth={2}
        />
        <Text
          align="center"
          x={textFrom[0]}
          y={textFrom[1]}
          text={this.state.text1}
          witdth={14}
          fontFamily="Calibri"
        />

        <Text
          align="center"
          x={textTo[0]}
          y={textTo[1]}
          text={this.state.text2}
          witdth={14}
          fontFamily="Calibri"
        />
      </Group>
    );
  }
}

export default Relationship;
