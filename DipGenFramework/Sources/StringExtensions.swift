//
//  StringExtensions.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

extension String {
    
    func stringRange(range: Range<Int>) -> Range<Index> {
        return startIndex.advancedBy(range.startIndex)..<startIndex.advancedBy(range.endIndex)
    }
    
    func substring(in range: Range<Int>) -> String {
        return substringWithRange(stringRange(range))
    }
    
    func contains(annotation annotation: DipAnnotation) -> Bool {
        return containsString(annotation.description)
    }
    
    func trimmed(characters: String) -> String {
        return trimmed(NSCharacterSet(charactersInString: characters))
    }
    
    func trimmed(charactersSet: NSCharacterSet) -> String {
        return stringByTrimmingCharactersInSet(charactersSet)
    }

    var camelCased: String {
        return String(characters.prefix(1)).lowercaseString + String(characters.dropFirst())
    }

}
