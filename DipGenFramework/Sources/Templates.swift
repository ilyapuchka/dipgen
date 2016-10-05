//
//  DipTemplate.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

public struct Container {
    let name: String
    var isUIContainer: Bool
    var registrations: [Registration]
    
    public var contextValue: [String: Any] {
        var contextValue: [String: Any] = ["name": name]
        if isUIContainer {
            contextValue["isUIContainer"] = isUIContainer
        }
        contextValue["registrations"] = registrations.map({ $0.contextValue })
        return contextValue
    }
}

public struct Registration {
    let name: String
    let scope: String
    let registerAs: String?
    let tag: String?
    let factory: Factory
    let implements: [String]
    let resolvingProperties: [ResolvingProperty]
    let storyboardInstantiatable: Bool
    
    var contextValue: [String: Any] {
        var contextValue: [String: Any] = ["name": name, "scope": scope]
        if let registerAs = registerAs {
            contextValue["registerAs"] = registerAs
        }
        if let tag = tag {
            contextValue["tag"] = tag
        }
        contextValue["factory"] = factory.contextValue
        if !implements.isEmpty {
            contextValue["implements"] = implements.map({ "\($0).self" }).joinWithSeparator(", ")
        }
        if !resolvingProperties.isEmpty {
            contextValue["resolvingProperties"] = resolvingProperties.map({ $0.contextValue })
        }
        return contextValue
    }
}

struct ResolvingProperty {
    let name: String
    let resolveAs: String?
    let tag: String?
    
    var contextValue: [String: Any] {
        var contextValue: [String: Any] = ["name": name]
        if let resolveAs = resolveAs {
            contextValue["resolveAs"] = resolveAs
        }
        if let tag = tag {
            contextValue["tag"] = tag
        }
        return contextValue
    }
}

struct Factory {
    let type: String
    let arguments: [Argument]
    let constructor: String?
    let closure: Closure?
    
    var contextValue: [String: Any] {
        var contextValue: [String: Any] = [
            "type": type,
            "arguments": arguments.map({ $0.contextValue })
            ]
        if let constructor = constructor {
            contextValue["constructor"] = constructor
        }
        if let closure = closure {
            contextValue["closure"] = closure.contextValue
        }
        return contextValue
    }
}

struct Argument {
    let name: String
    let type: String
    
    var contextValue: [String: Any] {
        return ["name": name, "type": type]
    }
}

struct Closure {
    let arguments: [String]
    let constructor: String
    let type: String
    
    var contextValue: [String: Any] {
        let body = Closure.body(self.constructor, type: self.type, insertingArguments: self.arguments)
        return [
            "body": body,
            "arguments": arguments.joinWithSeparator(", ")
        ]
    }
    
    static func body(constructor: String, type: String, insertingArguments: [String]) -> String {
        guard let argumentsStart = constructor.rangeOfString("(")?.startIndex else { return constructor }
        guard let argumentsEnd = constructor.rangeOfString(")")?.startIndex else { return constructor }
        guard argumentsStart.successor() < argumentsEnd else { return constructor }
        let constructorArgumentsString = constructor.substringWithRange(argumentsStart.successor()..<argumentsEnd)
        let constructorName = constructor.substringToIndex(argumentsStart)
        let constructorArguments = constructorArgumentsString.componentsSeparatedByString(":")
        var insertingArguments = insertingArguments
        var constructorArgumentsPairs = [String]()
        var addTry = false
        for argument in constructorArguments {
            guard !argument.isEmpty else { break }
            if let index = insertingArguments.indexOf(argument) {
                insertingArguments.removeAtIndex(index)
                constructorArgumentsPairs.append("\(argument): \(argument)")
            }
            else {
                addTry = true
                constructorArgumentsPairs.append("\(argument): container.resolve()")
            }
        }
        return "\(addTry ? "try " : "")\(type).\(constructorName)(\(constructorArgumentsPairs.joinWithSeparator(", ")))"
    }

}

public func renderDipTemplate(containers: [Container], imports: Set<String>) throws -> String {
    var imports = imports
    if !containers.filter({ $0.isUIContainer }).isEmpty {
        imports.insert("import DipUI")
    }
    else {
        imports.insert("import Dip")
    }

    let context = Context(dictionary: ["containers": containers.map({ $0.contextValue }), "imports": Array(imports)])
    let template = try Template(named: "Dip.generated.stencil", inBundle: NSBundle(forClass: FileProcessor.self))
    return try template.render(context)
}
