//
//  XCProjectFileExtensions.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Xcode

extension XCProjectFile {
    
    convenience init(path: String) throws {
        try self.init(xcodeprojURL: NSURL(fileURLWithPath: path))
    }
    
    func sourceFilesPaths(environment: Environment) throws -> [String] {
        let allTargets = project.targets
        guard let target = allTargets.filter({ $0.name == environment.targetName }).first else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let sourceFileRefs = target.buildPhases
            .flatMap({ $0 as? PBXSourcesBuildPhase })
            .flatMap({ $0.files })
            .map({ $0.fileRef })
        
        let fileRefPaths = sourceFileRefs
            .flatMap({ $0 as? PBXFileReference })
            .map({ $0.fullPath })
        
        let swiftFilesURLs = fileRefPaths.map(pathResolver(with: environment.url))
            .flatMap({ $0?.path })
        
        return swiftFilesURLs
    }
    
}

private func pathResolver(with URLForSourceTreeFolder: (SourceTreeFolder) -> NSURL) -> (Path) -> NSURL? {
    return { path in
        switch path {
        case let .Absolute(absolutePath):
            return NSURL(fileURLWithPath: absolutePath)
        case let .RelativeTo(sourceTreeFolder, relativePath):
            let sourceTreeURL = URLForSourceTreeFolder(sourceTreeFolder)
            return sourceTreeURL.URLByAppendingPathComponent(relativePath)
        }
    }
}
