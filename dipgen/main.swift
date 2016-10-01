import Foundation
import DipGenFramework

do {
    let files = try NSFileManager.defaultManager().swiftFiles(at: ".")
    let processingResult = files
        .map({ FileProcessor(file: $0).process() })
        .reduce(FileProcessingResult(), combine: +)
    let content = String(containers: processingResult)
    try content.writeToFile("./output.swift", atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

