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
        build_app(
            project: project,
            scheme: "Mindbox",
            clean: true,
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
        scan(
            project: project,
            scheme: "Mindbox",
            onlyTesting: ["MindboxTests"],
            skipBuild: true,
            clean: false,
            xcodebuildFormatter: "xcpretty",
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
    }
}
