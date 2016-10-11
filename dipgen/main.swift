import Foundation
import DipGenFramework
import SourceKittenFramework
import Xcode

let main = command(
    Option("output", ".", description: "Path to generated files."),
    Flag("verbose", description: "Prints process information."),
    help: "Annotations: \n\n\(DipAnnotation.allValues.map({ $0.help }).joinWithSeparator("\n\n"))"
) { (outputPath, verbose) in
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
            .map({
                if verbose { print("Processing \($0.file.path!)") }
                return try $0.process()
            })
            .reduce([String: Container](), combine: +)
            .map({ $0.1 })
        
        let imports = Set(files.flatMap({ $0.imports() }))
        
        if verbose { print("") }
        for container in processingResult {
            let fileName = "Dip.\(container.name).swift"
            if verbose { print("Generating \(fileName)")}
            let content = try renderContainerTemplate(container, imports: imports)
            let containerFileURL = NSURL(fileURLWithPath: fileName, relativeToURL: NSURL(fileURLWithPath: outputPath))
            try content.writeToURL(containerFileURL, atomically: true, encoding: NSUTF8StringEncoding)
        }
        
        let content = try renderCommonTemplate(processingResult)
        if verbose { print("Generating Dip.configure.swift")}
        let commonFileURL = NSURL(fileURLWithPath: "Dip.configure.swift", relativeToURL: NSURL(fileURLWithPath: outputPath))
        try content.writeToURL(commonFileURL, atomically: true, encoding: NSUTF8StringEncoding)
    } catch {
        print(error)
    }
}

let version = NSBundle.mainBundle()
    .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
main.run("dipgen v\(version)")


