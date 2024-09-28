import * as React from 'react';

import { Yolov8ClassifyViewProps } from './Yolov8Classify.types';

export default function Yolov8ClassifyView(props: Yolov8ClassifyViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
