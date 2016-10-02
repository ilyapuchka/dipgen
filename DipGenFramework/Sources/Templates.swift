//
//  Template.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

public indirect enum Template {
    
    case container(name: String, registrations: [Template], uiContainer: Bool)
    case registration(name: String?, scope: String, registerAs: String?, tag: String?, factory: (type: String, constructor: String), implements: [String], resolvingProperties: [PropertyProcessingResult], storyboardInstantiatable: Template?)
    case implements(types: [String])
    case resolvingProperties(properties: [(name: String, tag: String?, injectAs: String?)])
    case resolveProperty(name: String, tag: String?, injectAs: String?)
    case factory(type: String, constructor: String)
    case storyboardInstantiatable(type: String)
    case uiContainer()
    
    case configureAll(containers: [String])
    case configureContainer(name: String)
    case bootstrapAll(containers: [String])
    case bootstrapContainer(name: String)
    case containerExtension([Template])
    
    enum Format: String {
        case container              = "let %@ = DependencyContainer { container in \n\tunowned let container = container\n%@\n%@}\n"
        case uiContainer            = "DependencyContainer.uiContainers.append(container)\n"
        case registration           = "%@container.register(.%@, %@%@factory: %@)\n"
        case implements             = ".implements(%@)\n"
        case resolvingProperties    = ".resolvingProperties { container, resolved in \n%@}\n"
        case resolveProperty        = "resolved.%@ = try container.resolve(%@)%@\n"
        case factory                = "%@.%@"
        case storyboardInstantiatable   = "extension %@: StoryboardInstantiatable {}\n"
        case configureAll           = "static func configureAll() {\n%@}\n"
        case configureContainer     = "let _ = %@\n"
        case bootstrapAll           = "static func bootstrapAll() throws {\n%@}\n"
        case bootstrapContainer     = "try %@.bootstrap()\n"
        case containerExtension     = "extension DependencyContainer {\n\n%@\n}\n"
    }
    
    func description(indent: Int = 0) -> String {
        switch self {
        case let .container(name, registrations, uiContainer):
            let uiContainer = uiContainer ? Template.uiContainer().description(indent) : ""
            return String(.container, name, uiContainer, String(registrations, indent: indent + 1))
            
        case .uiContainer:
            return String(.uiContainer, indent: indent + 1)
            
        case let .registration(name, scope, registerAs, tag, factory, implements, resolvingProperties, _):
            let implements = Template.implements(types: implements)
            let resolvingProperties = Template.resolvingProperties(properties: resolvingProperties)
            let factory = Template.factory(type: factory.type, constructor: factory.constructor)
            
            return String(.registration,
                (name != nil ? "let \(name!) = " : ""),
                scope,
                (registerAs != nil ? "type: \(registerAs!).self, " : ""),
                (tag != nil ? "tag: \"\(tag!)\", " : ""),
                factory.description(),
                indent: indent)
                .appending(implements, indent: indent + 1)
                .appending(resolvingProperties, indent: indent + 1)

        case let .implements(types):
            guard !types.isEmpty else { return "" }
            let types = types.map({ "\($0).self" }).joinWithSeparator(", ")
            return String(.implements, types, indent: indent)
            
        case let .resolvingProperties(properties):
            guard !properties.isEmpty else { return "" }
            let properties = properties.map(Template.resolveProperty)
            return String(.resolvingProperties, String(properties, indent: indent + 1), indent: indent)
            
        case let .resolveProperty(name, tag, injectAs):
            return String(.resolveProperty, name,
                (tag != nil ? "tag: \"\(tag!)\"" : ""),
                (injectAs != nil ? " as \(injectAs!)" : ""),
                indent: indent)
            
        case let factory(type, constructor):
            return String(.factory, type, constructor)
            
        case let .storyboardInstantiatable(type):
            return String(.storyboardInstantiatable, type)
        
        case let configureAll(containers):
            let containers = containers.map(Template.configureContainer)
            return String(.configureAll, String(containers, indent: indent + 1), indent: indent)
        case let configureContainer(name):
            return String(.configureContainer, name, indent: indent)
        
        case let bootstrapAll(containers):
            let containers = containers.map(Template.bootstrapContainer)
            return String(.bootstrapAll, String(containers, indent: indent + 1), indent: indent)
        case let bootstrapContainer(name):
            return String(.bootstrapContainer, name, indent: indent)
            
        case let containerExtension(extensions):
            return String(.containerExtension, String(extensions, separator: "\n", indent: indent + 1))
        }
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
