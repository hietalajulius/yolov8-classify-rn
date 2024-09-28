import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to Yolov8Classify.web.ts
// and on native platforms to Yolov8Classify.ts
import Yolov8ClassifyModule from './Yolov8ClassifyModule';
import Yolov8ClassifyView from './Yolov8ClassifyView';
import { ChangeEventPayload, Yolov8ClassifyViewProps } from './Yolov8Classify.types';

// Get the native constant value.
export const PI = Yolov8ClassifyModule.PI;

export function hello(): string {
  return Yolov8ClassifyModule.hello();
}

export async function setValueAsync(value: string) {
  return await Yolov8ClassifyModule.setValueAsync(value);
}

const emitter = new EventEmitter(Yolov8ClassifyModule ?? NativeModulesProxy.Yolov8Classify);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { Yolov8ClassifyView, Yolov8ClassifyViewProps, ChangeEventPayload };
