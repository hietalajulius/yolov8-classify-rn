import { withInfoPlist, ConfigPlugin } from "expo/config-plugins";

const withCameraUsageDescription: ConfigPlugin<{
  cameraUsageDescription?: string;
}> = (config, { cameraUsageDescription }) => {
  config = withInfoPlist(config, (config) => {
    config.modResults["NSCameraUsageDescription"] =
      cameraUsageDescription ??
      "The camera is used to stream video for classification.";
    return config;
  });

  return config;
};

export default withCameraUsageDescription;
