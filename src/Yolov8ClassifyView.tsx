import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { ViewProps } from "react-native";

export type OnResultEvent = {
  classification: string;
};

export type Props = {
  onResult?: (event: { nativeEvent: OnResultEvent }) => void;
} & ViewProps;

const NativeView: React.ComponentType =
  requireNativeViewManager("Yolov8Classify");

export default function Yolov8ClassifyView(props: Props) {
  return <NativeView {...props} />;
}
