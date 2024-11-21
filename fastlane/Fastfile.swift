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
            project: project, // Используем gym для сборки
            scheme: "Mindbox",
            clean: true,
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
        scan(
            project: project,
            scheme: "Mindbox",
            onlyTesting: ["MindboxTests"],
            skipBuild: true, // Пропускаем сборку перед тестами
            clean: false,    // clean перед skipBuild
            xcodebuildFormatter: "xcpretty",
            xcargs: "CI=true CODE_SIGNING_ALLOWED=NO"
        )
    }
}
