//
//  Environment.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Xcode

struct Environment {
    
    let projectFilePath: String
    let buildProductsDir: String
    let developerDir: String
    let sdkRoot: String
    let sourceRoot: String
    let targetName: String
    
    init(environment: [String: String]) throws {
        guard
            let projectFilePath = environment["PROJECT_FILE_PATH"],
            let buildProductsDir = environment["BUILT_PRODUCTS_DIR"],
            let developerDir = environment["DEVELOPER_DIR"],
            let sdkRoot = environment["SDKROOT"],
            let sourceRoot = environment["SOURCE_ROOT"],
            let targetName = environment["TARGET_NAME"] else {
                //TODO: throw error
                throw NSError(domain: "", code: 0, userInfo: nil)
        }
        self.projectFilePath = projectFilePath
        self.buildProductsDir = buildProductsDir
        self.developerDir = developerDir
        self.sdkRoot = sdkRoot
        self.sourceRoot = sourceRoot
        self.targetName = targetName
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
