import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

do {
    let environment = try Environment(processInfo: NSProcessInfo())
    let project = try XCProjectFile(path: environment.projectFilePath)
    let files = try project.sourceFilesPaths(environment)
        .filter({ $0.isSwiftFile() == true &&
            !($0 as NSString).lastPathComponent.hasPrefix("Dip.")
        })
        .flatMap(File.init(path:))
    let processingResult = try files
        .map(FileProcessor.init(file:))
        .map({ try $0.process() })
        .reduce([String: Container](), combine: +)
        .map({ $0.1 })
    let imports = Set(files.flatMap({ $0.imports() }))
    for container in processingResult {
        let content = try renderContainerTemplate(container, imports: imports)
        let containerFileURL = NSURL(fileURLWithPath: "Dip.\(container.name).swift", relativeToURL: NSURL(fileURLWithPath: environment.outputPath))
        try content.writeToURL(containerFileURL, atomically: true, encoding: NSUTF8StringEncoding)
    }
    let content = try renderCommonTemplate(processingResult)
    let commonFileURL = NSURL(fileURLWithPath: "Dip.generated.swift", relativeToURL: NSURL(fileURLWithPath: environment.outputPath))
    try content.writeToURL(commonFileURL, atomically: true, encoding: NSUTF8StringEncoding)
    
} catch {
    print(error)
}

