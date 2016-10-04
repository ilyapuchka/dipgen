import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

do {
    let outputFileName = "Dip.generated.swift"
    let environment = try Environment(processInfo: NSProcessInfo())
    let project = try XCProjectFile(path: environment.projectFilePath)
    let files = try project.sourceFilesPaths(environment)
        .filter({ $0.isSwiftFile() == true })
        .flatMap(File.init(path:))
    let processingResult = try files
        .map(FileProcessor.init(file:))
        .map({ try $0.process() })
        .reduce(FileProcessingResult(), combine: +)
    let content = String(containers: processingResult, files: files)
    let outoutURL = NSURL(fileURLWithPath: outputFileName, relativeToURL: NSURL(fileURLWithPath: environment.outputPath))
    try content.writeToURL(outoutURL, atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

