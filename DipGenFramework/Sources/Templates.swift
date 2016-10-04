//
//  Template.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

public indirect enum Template {
    
    case content(imports: [String], containers: [String: [Template]])
    case container(name: String, registrations: [Template], uiContainer: Bool)
    case registration(name: String?, scope: String, registerAs: String?, tag: String?, factory: (type: String, constructor: String, arguments: [String]), implements: [String], resolvingProperties: [PropertyProcessingResult], storyboardInstantiatable: Bool)
    case implements(types: [String])
    case resolvingProperties(type: String, registeredAs: String, properties: [(name: String, tag: String?, injectAs: String?)])
    case resolveProperty(name: String, tag: String?, injectAs: String?)
    
    enum Format: String {
        case container              = "let %@ = DependencyContainer { container in \n\tunowned let container = container\n%@\n%@}\n"
        case uiContainer            = "DependencyContainer.uiContainers.append(container)\n"
        case registration           = "%@container.register(.%@, %@%@factory: %@)\n"
        case implements             = ".implements(%@)\n"
        case resolvingProperties    = ".resolvingProperties { container, resolved in \n%@%@}\n"
        case resolveProperty        = "resolved.%@ = try container.resolve(%@)%@\n"
        case factory                = "%@.%@"
        case argumentsFactory       = "{ %@ in %@ }"
        case storyboardInstantiatable   = "extension %@: StoryboardInstantiatable {}\n"
        case configureAll           = "static func configureAll() {\n%@}\n"
        case configureContainer     = "let _ = %@\n"
        case bootstrapAll           = "static func bootstrapAll() throws {\n%@}\n"
        case bootstrapContainer     = "try %@.bootstrap()\n"
        case containerExtension     = "extension DependencyContainer {\n\n%@\n}\n"
        case resolvedCast           = "let resolved = resolved as! %@\n\n"
    }
    
    func description(indent: Int = 0) -> String {
        switch self {
        case let .content(imports, containers):
            var imports = imports
            var storyboardInstantiatables: [String] = []
            var uiContainers: [String] = []
            for (container, registrations) in containers {
                for registration in registrations {
                    guard case let .registration(_, _, _, _, (type, _, _), _, _, storyboardInstantiatable) = registration else { continue }
                    if storyboardInstantiatable {
                        storyboardInstantiatables.append(type)
                        uiContainers.append(container)
                    }
                }
            }
            if !storyboardInstantiatables.isEmpty {
                imports.append("import DipUI")
            }
            else {
                imports.append("import Dip")
            }

            let comment = "// This is a generated file, do not edit!\n// Generated by dipgen, see https://github.com/ilyapuchka/dipgen\n\n"
            var extensions: [String] = []
            
            if !storyboardInstantiatables.isEmpty {
                extensions.append(storyboardInstantiatables.map({ String(.storyboardInstantiatable, $0, indent: indent) }).joinWithSeparator(""))
            }
            
            let configureContainers = containers.keys.map({ String(.configureContainer, $0, indent: indent + 2) })
            let bootstrapContainers = containers.keys.map({ String(.bootstrapContainer, $0, indent: indent + 2) })
            let configureAll = String(.configureAll, configureContainers.joinWithSeparator(""), indent: indent + 1)
            let bootstrapAll = String(.configureAll, bootstrapContainers.joinWithSeparator(""), indent: indent + 1)
            extensions.append(String(.containerExtension, [configureAll, bootstrapAll].joinWithSeparator("\n")))
            
            let content = containers.map({ name, registrations in
                Template.container(
                    name: name,
                    registrations: registrations,
                    uiContainer: uiContainers.contains(name)
                )
            })
            return "\(comment)\(Set(imports).joinWithSeparator("\n"))\n\n\(String(content, separator: "\n"))\n\n\(extensions.joinWithSeparator("\n"))"

        case let .container(name, registrations, uiContainer):
            let uiContainer = uiContainer ? String(.uiContainer, indent: indent + 1) : ""
            return String(.container, name, uiContainer, String(registrations, indent: indent + 1))
            
        case let .registration(name, scope, registerAs, tag, factory, implements, resolvingProperties, _):
            let implements = Template.implements(types: implements)
            let resolvingProperties = Template.resolvingProperties(type: factory.type, registeredAs: registerAs ?? factory.type, properties: resolvingProperties)
            let factoryString: String
            if factory.arguments.isEmpty {
                factoryString = String(.factory, factory.type, factory.constructor)
            }
            else {
                factoryString = String(
                    .argumentsFactory,
                    "(\(factory.arguments.joinWithSeparator(", ")))",
                    constructor(factory.constructor, type: factory.type, insertingArguments: factory.arguments)
                )
            }
            
            return String(.registration,
                (name != nil ? "let \(name!) = " : ""),
                scope,
                (registerAs != nil ? "type: \(registerAs!).self, " : ""),
                (tag != nil ? "tag: \"\(tag!)\", " : ""),
                factoryString,
                indent: indent)
                .appending(implements, indent: indent + 1)
                .appending(resolvingProperties, indent: indent + 1)

        case let .implements(types):
            guard !types.isEmpty else { return "" }
            let types = types.map({ "\($0).self" }).joinWithSeparator(", ")
            return String(.implements, types, indent: indent)
            
        case let .resolvingProperties(type, registeredAs, properties):
            guard !properties.isEmpty else { return "" }
            let properties = properties.map(Template.resolveProperty)
            let resolvedCast = type != registeredAs ? String(.resolvedCast, type, indent: indent + 1) : ""
            return String(.resolvingProperties, resolvedCast, String(properties, indent: indent + 1), indent: indent)
            
        case let .resolveProperty(name, tag, injectAs):
            return String(.resolveProperty, name,
                (tag != nil ? "tag: \"\(tag!)\"" : ""),
                (injectAs != nil ? " as \(injectAs!)" : ""),
                indent: indent)
        }
    }
    
    func constructor(constructor: String, type: String, insertingArguments: [String]) -> String {
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

extension String {

    init(_ format: Template.Format, _ arguments: String..., indent: Int = 0) {
        var format = String(format: format.rawValue, arguments: arguments.map(({ $0 as CVarArgType })))
        let indentation = indent.indentation
        if format.hasSuffix("}\n") && indent > 0 {
            format = format.inserting(indentation, at: format.endIndex.advancedBy(-2))
        }
        self = "\(indentation)\(format)"
    }
    
    init(_ templates: [Template], separator: String = "", indent: Int = 0) {
        self = templates.map({ $0.description(indent) }).joinWithSeparator(separator)
    }
    
    func appending(template: Template?, indent: Int = 0) -> String {
        guard let template = template else { return self }
        return stringByAppendingString(template.description(indent))
    }
    
    func inserting(subscring: String, at: Index) -> String {
        return String([
            characters.prefixUpTo(at),
            subscring.characters,
            characters.suffixFrom(at)
            ].flatten()
        )
    }
    
}

extension Int {
    var indentation: String {
        return (0..<self).reduce("", combine: { $0.0 + "\t" })
    }
}
