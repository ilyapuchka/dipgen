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
        .reduce([String: Container](), combine: +)
        .map({ $0.1 })
    let imports = Set(files.flatMap({ $0.imports() }))
    let content = try renderDipTemplate(processingResult, imports: imports)
    let outoutURL = NSURL(fileURLWithPath: outputFileName, relativeToURL: NSURL(fileURLWithPath: environment.outputPath))
    try content.writeToURL(outoutURL, atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

