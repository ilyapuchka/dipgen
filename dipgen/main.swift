import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

do {
    let environment = try Environment(environment: NSProcessInfo().environment)
    let project = try XCProjectFile(path: environment.projectFilePath)
    let files = try project.sourceFilesPaths(environment)
        .filter({ $0.isSwiftFile() == true })
        .flatMap(File.init(path:))
    let processingResult = try files
        .map(FileProcessor.init(file:))
        .map({ try $0.process() })
        .reduce(FileProcessingResult(), combine: +)
    let content = String(containers: processingResult, files: files)
    try content.writeToFile("./output.swift", atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

