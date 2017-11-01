import React from 'react';
import { Arrow, Group, Text } from 'react-konva';
import ObjectEmitter from './ObjectEmitter';

class Relationship extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      id: props.data.id,
      name: '',
      children: null,
      data: props.data,
      fromId: props.data.valueset.origin_href.substring(1),
      toId: props.data.valueset.target_href.substring(1),
      text1: ' ',
      text2: ' ',
      fromPos: { left: -1, top: -1, width: -1, height: -1 },
      toPos: { left: -1, top: -1, width: -1, height: -1 },
      visible: props.visible,
    };
  }

  componentWillMount() {
    const emitter = ObjectEmitter;
    const num = this.props.data.type.split(' ').length;
    const name = this.props.data.type
      .split(' ')
      .slice(2, num - 1)
      .join(' ');
    this.setState({
      text1: `has ${name}`,
      text2: `is ${name} of`,
    });

    // REMOVE THIS LATER!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! and fix correct relationship text
    this.setState({
      text1: '',
      text2: '',
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

    emitter.addListener('forceUpdate', bol => {
      if (bol) {
        this.setState({
          fromPos: { left: -1, top: -1, width: -1, height: -1 },
          toPos: { left: -1, top: -1, width: -1, height: -1 },
        });
      }
    });
  }

  componentWillReceiveProps(newProps) {
    this.setState({
      id: newProps.data.id,
      data: newProps.data,
      fromId: newProps.data.valueset.origin_href.substring(1),
      toId: newProps.data.valueset.target_href.substring(1),
      visible: newProps.visible,
    });
  }

  render() {
    if (!this.state.visible.includes(this.state.data.type)) {
      return <Group />;
    }

    const minFrom = { pos: [0, 0], node: 0 };
    const minTo = { pos: [0, 0], node: 0 };
    let textFrom = [0, 0];
    let textTo = [0, 0];

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

    function getPerpendicularity(x1, y1, x2, y2, node) {
      if (node === 0 && y2 > y1) {
        return 0;
      }
      if (node === 1 && x1 > x2) {
        return 0;
      }
      if (node === 2 && y1 > y2) {
        return 0;
      }
      if (node === 3 && x2 > x1) {
        return 0;
      }

      if (node % 2 === 0) {
        return Math.abs(y2 - y1) / (Math.abs(x2 - x1) + Math.abs(y2 - y1));
      } else {
        return Math.abs(x2 - x1) / (Math.abs(x2 - x1) + Math.abs(y2 - y1));
      }
    }

    function getTextPosition(x1, y1, x2, y2, distanceFromObject, rightPerpendicular) {
      let perpendicularDistanceFromLine = 30;
      if (rightPerpendicular) {
        perpendicularDistanceFromLine += 20;
      }

      const a = Math.sqrt(distanceFromObject ** 2 / (2 * ((x2 - x1) ** 2 + (y2 - y1) ** 2)));
      let x = x1 + (x2 - x1) * a;
      let y = y1 + (y2 - y1) * a;
      const a2 = Math.sqrt(
        perpendicularDistanceFromLine ** 2 / (2 * ((x2 - x1) ** 2 + (y2 - y1) ** 2))
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
      return array.sort((a, b) => {
        const x = a[key];
        const y = b[key];
        return x < y ? -1 : x > y ? 1 : 0;
      });
    }

    function rightOrLeft(x1, y1, x2, y2, fromNode) {
      let angle = 0;
      if (fromNode === 0) {
        angle = Math.atan2(y1 - y2, x2 - x1);
      } else if (fromNode === 1) {
        angle = Math.atan2(x2 - x1, y2 - y1);
      } else if (fromNode === 2) {
        angle = Math.PI - Math.atan2(y2 - y1, x2 - x1);
      } else if (fromNode === 3) {
        angle = Math.atan2(x1 - x2, y1 - y2);
      }

      if (angle < Math.PI / 2) {
        return false;
      } else {
        return true;
      }
    }

    const fromNodes = getRectangleNodes(
      this.state.fromPos.left,
      this.state.fromPos.top,
      this.state.fromPos.width,
      this.state.fromPos.height
    );

    const toNodes = getRectangleNodes(
      this.state.toPos.left,
      this.state.toPos.top,
      this.state.toPos.width,
      this.state.toPos.height
    );

    let possiblePositions = [];

    for (let i = 0; i < fromNodes.length; i++) {
      for (let j = 0; j < toNodes.length; j++) {
        const d = squareDistance(fromNodes[i][0], fromNodes[i][1], toNodes[j][0], toNodes[j][1]);
        possiblePositions.push({
          dist: d,
          from: fromNodes[i],
          to: toNodes[j],
          fromNode: i,
          toNode: j,
        });
      }
    }
    possiblePositions = sortByKey(possiblePositions, 'dist');
    possiblePositions = possiblePositions.slice(0, 3);
    let bestPerpendiculatiry = 0;

    for (let i = 0; i < possiblePositions.length; i++) {
      const fromNode = possiblePositions[i].fromNode;
      const toNode = possiblePositions[i].toNode;

      if (possiblePositions[i].fromNode === possiblePositions[i].toNode) {
        if (this.state.width !== -1) {
          continue;
        }
      }

      const fromP = getPerpendicularity(
        possiblePositions[i].from[0],
        possiblePositions[i].from[1],
        possiblePositions[i].to[0],
        possiblePositions[i].to[1],
        fromNode
      );
      const toP = getPerpendicularity(
        possiblePositions[i].to[0],
        possiblePositions[i].to[1],
        possiblePositions[i].from[0],
        possiblePositions[i].from[1],
        toNode
      );
      const currentP = Math.min(fromP, toP);
      if (currentP / bestPerpendiculatiry > 1.2 && currentP > bestPerpendiculatiry) {
        bestPerpendiculatiry = currentP;
        minFrom.pos = possiblePositions[i].from;
        minTo.pos = possiblePositions[i].to;
        minFrom.node = possiblePositions[i].fromNode;
        minTo.node = possiblePositions[i].toNode;
      }
    }
    // todo: make more general
    let rightPerpendicular = true;
    if (minTo.pos[1] < minFrom.pos[1]) {
      rightPerpendicular = false;
    }

    let toDist = 100;
    if (minTo.pos[0] < minFrom.pos[1]) {
      toDist = 20;
    }
    toDist = 50;

    const right = rightOrLeft(
      minFrom.pos[0],
      minFrom.pos[1],
      minTo.pos[0],
      minTo.pos[1],
      minFrom.node
    );
    if (right) {
      rightPerpendicular = false;
    } else {
      rightPerpendicular = true;
    }

    textFrom = getTextPosition(
      minFrom.pos[0],
      minFrom.pos[1],
      minTo.pos[0],
      minTo.pos[1],
      toDist,
      rightPerpendicular
    );
    textTo = getTextPosition(
      minTo.pos[0],
      minTo.pos[1],
      minFrom.pos[0],
      minFrom.pos[1],
      toDist,
      !rightPerpendicular
    );

    if (minFrom.pos[0] <= 0 || minFrom.pos[1] <= 0 || minTo.pos[0] <= 0 || minTo.pos[1] <= 0) {
      return <Group />;
    }

    // console.log(this.state.data.type);

    return (
      <Group>
        <Arrow
          x={minFrom.pos[0]}
          y={minFrom.pos[1]}
          points={[0, 0, minTo.pos[0] - minFrom.pos[0], minTo.pos[1] - minFrom.pos[1]]}
          pointerLength={5}
          pointerWidth={5}
          fil="black"
          stroke="black"
          strokeWidth={2}
        />
        <Text
          x={textFrom[0]}
          y={textFrom[1]}
          text={this.state.text1}
          align="center"
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
