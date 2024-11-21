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
        scan(project: .userDefined(project),
             scheme: "Mindbox",
             clean: true,
             testWithoutBuilding: .userDefined(false),
             forceQuitSimulator: .userDefined(true),
             resetSimulator: .userDefined(true),
             prelaunchSimulator: .userDefined(true),
             onlyTesting: ["MindboxTests"],
             disableConcurrentTesting: true,
             includeSimulatorLogs: true,
             xcodebuildFormatter: "xcpretty",
             xcargs: "CI=true CODE_SIGNING_ALLOWED=NO",
             destination: "platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.1"
        )
    }
}
