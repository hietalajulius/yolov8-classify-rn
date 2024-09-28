import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { Yolov8ClassifyViewProps } from './Yolov8Classify.types';

const NativeView: React.ComponentType<Yolov8ClassifyViewProps> =
  requireNativeViewManager('Yolov8Classify');

export default function Yolov8ClassifyView(props: Yolov8ClassifyViewProps) {
  return <NativeView {...props} />;
}
