//
//  Environment.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Xcode

struct Environment {
    
    enum Error: ErrorType, CustomStringConvertible {
        case missing(String)
        
        var description: String {
            switch self {
            case let .missing(variable):
                return "Missing environment variable \(variable)"
            }
        }
    }
    
    let projectFilePath: String
    let buildProductsDir: String
    let developerDir: String
    let sdkRoot: String
    let sourceRoot: String
    let targetName: String
    let outputPath: String
    let dipVersion: String
    let dipUIVersion: String
    
    init(processInfo: NSProcessInfo) throws {
        let arguments = processInfo.arguments
        outputPath = get(arguments, name: "-o", fullName: "--output", defaultValue: "")
        dipVersion = get(arguments, name: "-dip", fullName: "--dip-version", defaultValue: "5.0")
        dipUIVersion = get(arguments, name: "-dipui", fullName: "--dipui-version", defaultValue: "1.0")
        
        let environment = processInfo.environment
        projectFilePath    = try get(environment, "PROJECT_FILE_PATH")
        buildProductsDir   = try get(environment, "BUILT_PRODUCTS_DIR")
        developerDir       = try get(environment, "DEVELOPER_DIR")
        sdkRoot            = try get(environment, "SDKROOT")
        sourceRoot         = try get(environment, "SOURCE_ROOT")
        targetName         = try get(environment, "TARGET_NAME")
    }
    
    func url(forSourceTreeFolder sourceTreeFolder: SourceTreeFolder) -> NSURL {
        let path: String
        switch sourceTreeFolder {
        case .BuildProductsDir:
            path = buildProductsDir
        case .DeveloperDir:
            path = developerDir
        case .SDKRoot:
            path = sdkRoot
        case .SourceRoot:
            path = sourceRoot
        }
        return NSURL(fileURLWithPath: path)
    }
    
}

private func get(environment: [String: String], _ name: String) throws -> String {
    guard let value = environment[name] else { throw Environment.Error.missing(name) }
    return value
}

private func get(arguments: [String], name: String, fullName: String, defaultValue: String) -> String {
    if let outputArgumentIndex = arguments.indexOf(name) ?? arguments.indexOf(fullName) {
        return arguments[outputArgumentIndex.successor()]
    }
    else {
        return defaultValue
    }
}

