import Foundation

class Fastfile: LaneFile {
    private let project = "Mindbox.xcodeproj"

    func buildLane() {
        desc("Build for testing")
        scan(
            project: .userDefined(project),
            scheme: "Mindbox",
            xcodebuildFormatter: "",
            derivedDataPath: "derivedData",
            buildForTesting: .userDefined(true),
            xcargs: "CI=true"
        )
    }

    func unitTestLane() {
        desc("Run unit tests")
        gym(
            project: .userDefined(project), // Используем gym для сборки
            scheme: "Mindbox",
            clean: true,
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
        scan(
            project: .userDefined(project),
            scheme: "Mindbox",
            onlyTesting: ["MindboxTests"],
            clean: false,
            xcodebuildFormatter: "xcpretty",
            skipBuild: true,
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
    }
}
