//
//  DipTemplate.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

public struct Container {
    public let name: String
    var isUIContainer: Bool
    var registrations: [Registration]
    
    init(name: String, isUIContainer: Bool, registrations: [Registration]) {
        self.name = name.camelCased
        self.isUIContainer = isUIContainer
        self.registrations = registrations
    }
    
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
    let scope: String?
    let registerAs: String?
    let tag: String?
    let factory: Factory
    let implements: [(String, String?)]
    let resolvingProperties: [ResolvingProperty]
    let storyboardInstantiatable: Bool
    
    var contextValue: [String: Any] {
        var contextValue: [String: Any] = ["name": name]
        if let scope = scope {
            contextValue["scope"] = scope
        }
        if let registerAs = registerAs {
            contextValue["registerAs"] = registerAs
        }
        if registerAs != factory.type {
            contextValue["instanceType"] = factory.type
        }
        if let tag = tag {
            contextValue["tag"] = tag
        }
        contextValue["factory"] = factory.contextValue
        if !implements.isEmpty {
            contextValue["implements"] = implements.map({ (type, tag) -> [String: String] in
                var value: [String: String] = ["type": "\(type).self"]
                if let tag = tag {
                    value["tag"] = tag
                }
                return value
            })
        }
        if !resolvingProperties.isEmpty {
            contextValue["resolvingProperties"] = resolvingProperties.map({ $0.contextValue })
        }
        if storyboardInstantiatable {
            contextValue["storyboardInstantiatable"] = true
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
            "arguments": arguments.map({ $0.contextValue }),
            "methodArguments": arguments.map({ $0.signature })
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

struct Argument: Equatable {
    let name: String
    let internalName: String
    let type: String
    var _internalName: String {
        return internalName == name ? "_\(name)" : internalName
    }
    
    var contextValue: [String: Any] {
        return [
            "name": name,
            "type": type,
            "internalName": _internalName
        ]
    }
    var signature: String {
        return "\([name, _internalName].flatMap({ $0 }).joinWithSeparator(" ")): \(type)"
    }
}

func ==(lhs: Argument, rhs: Argument) -> Bool {
    return lhs.name == rhs.name && lhs.type == rhs.type
}

struct Closure {
    let runtimeArguments: [Argument]
    let constructorName: String
    let constructorArguments: [Argument]
    let type: String
    
    var contextValue: [String: Any] {
        return [
            "body": body,
            "arguments": runtimeArguments.map({ $0.contextValue }),
            "argumentsNames": runtimeArguments.map({ $0.name }),
            "internalArgumentsNames": runtimeArguments.map({ $0._internalName })
        ]
    }
    
    var body: String {
        var constructorName = self.constructorName
        let argumentsToResolve = constructorArguments.filter({ !runtimeArguments.contains($0) })
        let addTry = !argumentsToResolve.isEmpty
        for argument in runtimeArguments {
            constructorName = constructorName.stringByReplacingOccurrencesOfString("\(argument.name):", withString: "\(argument.name): \(argument.name), ")
        }
        for argument in argumentsToResolve {
            constructorName = constructorName.stringByReplacingOccurrencesOfString("\(argument.name):", withString: "\(argument.name): container.resolve(), ")
        }
        constructorName =  constructorName.stringByReplacingOccurrencesOfString(", )", withString: ")")
        return "\(addTry ? "try " : "")\(type).\(constructorName)"
    }

}

enum FilterError: ErrorType {
    case InvalidInputType
}

struct StringFilters {
    static func titlecase(value: Any?) throws -> Any? {
        guard let string = value as? String else { throw FilterError.InvalidInputType }
        let strings = string.componentsSeparatedByString(" ")
        return strings.map({ $0.titleCased }).joinWithSeparator("")
    }
    static func camelcase(value: Any?) throws -> Any? {
        guard let string = value as? String else { throw FilterError.InvalidInputType }
        return string.camelCased
    }
}

struct ArrayFilters {
    static func join(value: Any?) throws -> Any? {
        guard let array = value as? [Any] else { throw FilterError.InvalidInputType }
        let strings = array.flatMap { $0 as? String }
        guard array.count == strings.count else { throw FilterError.InvalidInputType }
        
        return strings.joinWithSeparator(", ")
    }
}

let namespace: Namespace = {
    let namespace = Namespace()
    namespace.registerFilter("titlecase", filter: StringFilters.titlecase)
    namespace.registerFilter("camelcase", filter: StringFilters.camelcase)
    namespace.registerFilter("join", filter: ArrayFilters.join)
    return namespace
}()

public func renderContainerTemplate(container: Container, imports: Set<String>, swiftVersion: String, noFactories: Bool) throws -> String {
    namespace.registerFilter("scope", filter: (swiftVersion >= "3.0") ? StringFilters.camelcase : StringFilters.titlecase)

    var imports = imports
    if container.isUIContainer {
        imports.insert("DipUI")
    }
    else {
        imports.insert("Dip")
    }

    var contextDictionary: [String: Any] = ["container": container.contextValue, "imports": Array(imports)]
    if noFactories {
        contextDictionary["noFactories"] = noFactories
    }
    let context = Context(dictionary: contextDictionary)
    let template = try Template(named: "Dip.container.stencil", inBundle: NSBundle(forClass: FileProcessor.self))
    return try template.render(context, namespace: namespace)
}

public func renderCommonTemplate(containers: [Container]) throws -> String {
    let context = Context(dictionary: ["containers": Array(Set(containers.map({ $0.name })))])
    let template = try Template(named: "Dip.configure.stencil", inBundle: NSBundle(forClass: FileProcessor.self))
    return try template.render(context, namespace: namespace)
}
