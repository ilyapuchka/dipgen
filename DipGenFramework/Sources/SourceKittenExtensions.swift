//
//  SourceKittenExtensions.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import SourceKittenFramework

extension Structure {
    
    enum Key {
        static let substructure     = "key.substructure"
        static let kind             = "key.kind"
        static let offset           = "key.offset"
        static let name             = "key.name"
        static let typename         = "key.typename"
    }
    
}

extension Structure {
    
    ///Returns structure's subscructure
    var substructure: [SourceKitRepresentable]? {
        return dictionary[Key.substructure] as? [SourceKitRepresentable]
    }
    
}

extension SyntaxMap {
    func imports(content: String) -> [String] {
        return tokens.enumerate()
            .filter { (_, token) -> Bool in
                token.type == SyntaxKind.Keyword.value &&
                    content.substringWithByteRange(start: token.offset, length: token.length) == "import"
            }
            .map { index, _ in tokens[index + 1] }
            .flatMap { token in content.substringWithByteRange(start: token.offset, length: token.length) }
    }
}

extension File {
    
    public func imports() -> [String] {
        return SyntaxMap(file: self).imports(contents)
    }
    
}

public typealias SourceKitDeclaration = [String: SourceKitRepresentable]
private let docCommentCharacterSet = NSCharacterSet(charactersInString: "/*\t\n")
public typealias DocGenerator = (SourceKitDeclaration)->(String?)

extension File {
    
    //getDocumentationCommentBody from SourceKittenFramework does not work correctly in Xcode 8
    func getDocumentationCommentBody(syntaxMap: SyntaxMap, inout lastProcessedDocRange: Range<Int>) -> DocGenerator {
        return { structure in
            guard let offset = (structure[Structure.Key.offset] as? Int64).map({ Int($0) }) else { return nil }
            guard let range = syntaxMap.commentRangeBeforeOffset(offset) else { return nil }
            //check if we already processed this range
            guard range.startIndex >= lastProcessedDocRange.endIndex else { return nil }
            
            lastProcessedDocRange = range
            return self.contents
                .substring(in: lastProcessedDocRange)
                .trimmed(docCommentCharacterSet)
        }
    }
    
}

extension Line {
    
    func contains(dipAnnotation annotation: DipAnnotation, modifier: ((String?)->Void)? = nil) -> Bool {
        let content = self.content
        guard let annotationRange = content.rangeOfString(annotation.description)
            where annotationRange.endIndex <= content.endIndex else { return false }
        
        if let modifier = modifier {
            let annotationEnd = content.rangeOfString("*/")?.startIndex ?? content.endIndex
            if annotationRange.endIndex < content.endIndex {
                let modifiedStart = annotationRange.endIndex.advancedBy(1)
                if modifiedStart < annotationEnd {
                    let modified = String(content[modifiedStart..<annotationEnd]).trimmed(.whitespaceCharacterSet())
                    modifier(modified.isEmpty ? nil : modified)
                }
            }
            else {
                modifier(nil)
            }
        }
        return true
    }
    
}

extension SourceKitRepresentable {
    
    var kind: SwiftDeclarationKind? {
        guard let declaration = self as? SourceKitDeclaration else { return nil }
        guard let kind = declaration[Structure.Key.kind] as? String else { return nil }
        return SwiftDeclarationKind(rawValue: kind)
    }
}
