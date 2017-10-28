import React from 'react';
import Renderer from 'react-test-renderer';
import ModelView from '../ModelView.js';

const mockModel = {
  children: []
};

const mockRelationships = {
  relationships: []
};

describe('<ModelView />', () => {
  it('should not change unexpectedly', () => {
    const tree = Renderer.create(
      <ModelView
        modelView={mockModel}
        relationships={mockRelationships}
        zoom={0}
        xOffset={5}
        yOffset={5}
        width={800}
        height={800}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
