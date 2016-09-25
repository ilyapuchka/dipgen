//
//  SourceKitTests.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import Foundation
@testable import SourceKittenFramework
import XCTest

private func run(executable: String, arguments: [String]) -> String? {
    let task = NSTask()
    task.launchPath = executable
    task.arguments = arguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()
    return output as String?
}

private func sourcekitStringsStartingWith(pattern: String) -> Set<String> {
    let sourceKitServicePath = (((run("/usr/bin/xcrun", arguments: ["-f", "swiftc"])! as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByAppendingPathComponent("lib/sourcekitd.framework/XPCServices/SourceKitService.xpc/Contents/MacOS/SourceKitService")
    let strings = run("/usr/bin/strings", arguments: [sourceKitServicePath])
    return Set(strings!.componentsSeparatedByString("\n").filter { string in
        return string.rangeOfString(pattern)?.startIndex == string.startIndex
    })
}

class SourceKitTests: XCTestCase {

    func testStatementKinds() {
        let expected: [StatementKind] = [
            .Brace,
            .Case,
            .For,
            .ForEach,
            .Guard,
            .If,
            .RepeatWhile,
            .Switch,
            .While,
        ]

        let actual = sourcekitStringsStartingWith("source.lang.swift.stmt.")
        let expectedStrings = Set(expected.map { $0.rawValue })
        XCTAssertEqual(
            actual,
            expectedStrings
        )
        if actual != expectedStrings {
            print("the following strings were added: \(actual.subtract(expectedStrings))")
            print("the following strings were removed: \(expectedStrings.subtract(actual))")
        }
    }

    func testSyntaxKinds() {
        let expected: [SyntaxKind] = [
            .Argument,
            .AttributeBuiltin,
            .AttributeID,
            .BuildconfigID,
            .BuildconfigKeyword,
            .Comment,
            .CommentMark,
            .CommentURL,
            .DocComment,
            .DocCommentField,
            .Identifier,
            .Keyword,
            .Number,
            .ObjectLiteral,
            .Parameter,
            .Placeholder,
            .String,
            .StringInterpolationAnchor,
            .Typeidentifier
        ]
        let actual = sourcekitStringsStartingWith("source.lang.swift.syntaxtype.")
        let expectedStrings = Set(expected.map { $0.rawValue })
        XCTAssertEqual(
            actual,
            expectedStrings
        )
        if actual != expectedStrings {
            print("the following strings were added: \(actual.subtract(expectedStrings))")
            print("the following strings were removed: \(expectedStrings.subtract(actual))")
        }
    }

    func testSwiftDeclarationKind() {
        let expected: [SwiftDeclarationKind] = [
            .Associatedtype,
            .Class,
            .Enum,
            .Enumcase,
            .Enumelement,
            .Extension,
            .ExtensionClass,
            .ExtensionEnum,
            .ExtensionProtocol,
            .ExtensionStruct,
            .FunctionAccessorAddress,
            .FunctionAccessorDidset,
            .FunctionAccessorGetter,
            .FunctionAccessorMutableaddress,
            .FunctionAccessorSetter,
            .FunctionAccessorWillset,
            .FunctionConstructor,
            .FunctionDestructor,
            .FunctionFree,
            .FunctionMethodClass,
            .FunctionMethodInstance,
            .FunctionMethodStatic,
            .FunctionOperatorInfix,
            .FunctionOperatorPostfix,
            .FunctionOperatorPrefix,
            .FunctionSubscript,
            .GenericTypeParam,
            .Module,
            .Protocol,
            .Struct,
            .Typealias,
            .VarClass,
            .VarGlobal,
            .VarInstance,
            .VarLocal,
            .VarParameter,
            .VarStatic
        ]
        let actual = sourcekitStringsStartingWith("source.lang.swift.decl.")
        let expectedStrings = Set(expected.map { $0.rawValue })
        XCTAssertEqual(
            actual,
            expectedStrings
        )
        if actual != expectedStrings {
            print("the following strings were added: \(actual.subtract(expectedStrings))")
            print("the following strings were removed: \(expectedStrings.subtract(actual))")
        }
    }

    func testLibraryWrappersAreUpToDate() {
        let sourceKittenFrameworkModule = Module(xcodeBuildArguments: ["-workspace", "SourceKitten.xcworkspace", "-scheme", "SourceKittenFramework"], name: nil, inPath: projectRoot)!
        let modules: [(module: String, path: String, spmModule: String)] = [
            ("CXString", "libclang.dylib", "Clang_C"),
            ("Documentation", "libclang.dylib", "Clang_C"),
            ("Index", "libclang.dylib", "Clang_C"),
            ("sourcekitd", "sourcekitd.framework/Versions/A/sourcekitd", "SourceKit")
        ]
        for (module, path, spmModule) in modules {
            let wrapperPath = "\(projectRoot)/Source/SourceKittenFramework/library_wrapper_\(module).swift"
            let existingWrapper = try! String(contentsOfFile: wrapperPath)
            let generatedWrapper = libraryWrapperForModule(module, loadPath: path, spmModule: spmModule, compilerArguments: sourceKittenFrameworkModule.compilerArguments)
            XCTAssertEqual(existingWrapper, generatedWrapper)
            let overwrite = false // set this to true to overwrite existing wrappers with the generated ones
            if existingWrapper != generatedWrapper && overwrite {
                generatedWrapper.dataUsingEncoding(NSUTF8StringEncoding)?.writeToFile(wrapperPath, atomically: true)
            }
        }
    }

    func testIndex() {
        let file = "\(fixturesDirectory)Bicycle.swift"
        let indexJSON = NSMutableString(string: toJSON(toAnyObject(Request.Index(file: file).send())) + "\n")

        func replace(pattern: String, withTemplate template: String) {
            try! NSRegularExpression(pattern: pattern, options: []).replaceMatchesInString(indexJSON, options: [], range: NSRange(location: 0, length: indexJSON.length), withTemplate: template)
        }

        // Replace the parts of the output that are dependent on the environment of the test running machine
        replace("\"key\\.filepath\"[^\\n]*", withTemplate: "\"key\\.filepath\" : \"\",")
        replace("\"key\\.hash\"[^\\n]*", withTemplate: "\"key\\.hash\" : \"\",")

        compareJSONStringWithFixturesName("BicycleIndex", jsonString: indexJSON as String)
    }
}

extension String: CustomStringConvertible {
    public var description: String {
        return self
    }
}
