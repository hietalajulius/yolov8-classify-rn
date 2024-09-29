import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  Image,
  TouchableOpacity,
  Linking,
} from "react-native";
import { Yolov8ClassifyView } from "yolov8-classify";
import { useState } from "react";

const formatClassification = (classification: string) => {
  return classification
    .split("_") // split the string into words
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()) // capitalize the first letter of each word
    .join(" "); // join the words back into a string with spaces
};

export default function App() {
  const [classification, setClassification] = useState<string | null>(null);
  const openSourceCode = () => {
    const url = "https://www.juliushietala.com/"; // replace with your source code URL
    Linking.canOpenURL(url).then((supported) => {
      if (supported) {
        Linking.openURL(url);
      } else {
        console.log(`Don't know how to open URL: ${url}`);
      }
    });
  };

  return (
    <View style={styles.container}>
      <Yolov8ClassifyView
        style={styles.camera}
        onResult={(result) =>
          setClassification(result.nativeEvent.classification)
        }
      >
        <View style={styles.overlay}>
          {classification && (
            <Text style={styles.classification}>
              {formatClassification(classification)}
            </Text>
          )}
        </View>
      </Yolov8ClassifyView>
      <View style={styles.menuContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <TouchableOpacity style={styles.menu} onPress={openSourceCode}>
            <Image
              style={styles.menuInner}
              source={require("./assets/logo.webp")}
            />
          </TouchableOpacity>
        </ScrollView>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
  overlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.1)",
    justifyContent: "center",
    alignItems: "center",
  },
  classification: {
    color: "white",
    fontSize: 24,
  },
  menuContainer: {
    position: "absolute",
    top: 50,
    left: 10,
    right: 10,
    height: 50,
    flexDirection: "row",
  },
  menu: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: "white",
    marginHorizontal: 5,
    justifyContent: "center",
    alignItems: "center",
  },
  menuInner: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: "grey",
  },
});
