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
    
    init(environment: [String: String]) throws {
        projectFilePath    = try get("PROJECT_FILE_PATH", environment)
        buildProductsDir   = try get("BUILT_PRODUCTS_DIR", environment)
        developerDir       = try get("DEVELOPER_DIR", environment)
        sdkRoot            = try get("SDKROOT", environment)
        sourceRoot         = try get("SOURCE_ROOT", environment)
        targetName         = try get("TARGET_NAME", environment)
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

private func get(name: String, _ environment: [String: String]) throws -> String {
    guard let value = environment[name] else { throw Environment.Error.missing(name) }
    return value
}

