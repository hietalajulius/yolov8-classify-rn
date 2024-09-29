import ExpoModulesCore

public class Yolov8ClassifyModule: Module {
  public func definition() -> ModuleDefinition {
    Name("Yolov8Classify")

    View(Yolov8ClassifyView.self) {
      Events("onResult")
    }
  }
}