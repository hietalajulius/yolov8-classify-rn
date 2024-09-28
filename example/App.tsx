import { StyleSheet, Text, View } from 'react-native';

import * as Yolov8Classify from 'yolov8-classify';

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{Yolov8Classify.hello()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
