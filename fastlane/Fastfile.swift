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
//             forceQuitSimulator: .userDefined(true),
//             resetSimulator: .userDefined(true),
//             prelaunchSimulator: .userDefined(true),
             onlyTesting: ["MindboxTests"],
             clean: false,
//             includeSimulatorLogs: true,
             xcodebuildFormatter: "xcpretty",
             disableConcurrentTesting: true,
             skipBuild: true,
//             testWithoutBuilding: .userDefined(true),
             xcargs: "CI=true",
             destination: "platform=iOS Simulator,name=iPhone SE (3rd generation),OS=latest",
             numberOfRetries: 3
        )
    }
}
