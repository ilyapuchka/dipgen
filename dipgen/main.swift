import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

do {
    let processInfo = NSProcessInfo()
    let arguments = processInfo.arguments
    var outputPath: String
    if let outputArgumentIndex = arguments.indexOf("-o") ?? arguments.indexOf("--output") {
        outputPath = arguments[outputArgumentIndex.successor()]
    }
    else {
        outputPath = ""
    }
    let outputFileName = "Dip.generated.swift"
    let environment = try Environment(environment: processInfo.environment)
    let project = try XCProjectFile(path: environment.projectFilePath)
    let files = try project.sourceFilesPaths(environment)
        .filter({ $0.isSwiftFile() == true })
        .flatMap(File.init(path:))
    let processingResult = try files
        .map(FileProcessor.init(file:))
        .map({ try $0.process() })
        .reduce(FileProcessingResult(), combine: +)
    let content = String(containers: processingResult, files: files)
    let outoutURL = NSURL(fileURLWithPath: outputFileName, relativeToURL: NSURL(fileURLWithPath: outputPath))
    try content.writeToURL(outoutURL, atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

