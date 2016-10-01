import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

do {
    let environment = try Environment(environment: NSProcessInfo().environment)
    let project = try XCProjectFile(path: environment.projectFilePath)
    let processingResult = try project.sourceFilesPaths(environment)
        .filter({ $0.isSwiftFile() == true })
        .flatMap(FileProcessor.init(path:))
        .map({ try $0.process() })
        .reduce(FileProcessingResult(), combine: +)
    let content = String(containers: processingResult)
    try content.writeToFile("./output.swift", atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

