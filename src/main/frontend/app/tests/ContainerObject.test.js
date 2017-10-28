import React from 'react';
import Renderer from 'react-test-renderer';
import ContainerObject from '../components/ContainerObject.js';

const mockContainer = {
  objectReference: {
    id: 2
  },
  type: "Mock",
  name: "Mock",
  attributes: {
    scaleX: 5,
    scaleY: 5,
    scaleWidth: 10,
    scaleHeight: 10,
  },
}



describe('<ContainerObject />', () => {
  it('should not change unexpectedly', () => {
    const tree = Renderer.create(
      <ContainerObject
        container={mockContainer}
        parentWidth={600}
        parentHeight={600
        parentX={5}
        parentY={5}
        key={4}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
