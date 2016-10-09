//
//  CodeGenerator.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation
import SourceKittenFramework

///Merges two processing results into one
public func +(lhs: [String: Container], rhs: [String: [Registration]]) -> [String: Container] {
    var lhs = lhs
    for (containerName, registrations) in rhs {
        var container = lhs[containerName] ?? Container(name: containerName, isUIContainer: false, registrations: [])
        if !container.isUIContainer {
            container.isUIContainer = !registrations.filter({ $0.storyboardInstantiatable }).isEmpty
        }
        container.registrations.appendContentsOf(registrations)
        lhs[containerName] = container
    }
    return lhs
}

typealias MethodProcessingResult = (name: String, designated: Bool, arguments: [Argument], registrationArguments: [Argument])

public class FileProcessor {
    
    enum Error: ErrorType, CustomStringConvertible {
        case failedToParse(String)
        
        var description: String {
            switch self {
            case let .failedToParse(file):
                return "Failed to parse structure of \(file)"
            }
        }
    }
    
    public let file: File
    
    lazy var structure: Structure = Structure(file: self.file)
    lazy var syntaxMap: SyntaxMap = SyntaxMap(file: self.file)
    lazy var docs: DocGenerator = self.file.getDocumentationCommentBody(self.syntaxMap, lastProcessedDocRange: &self.lastProcessedDocRange)

    var lastProcessedDocRange: Range<Int> = 0..<1

    public init(file: File) {
        self.file = file
    }
    
    public convenience init?(path: String) {
        guard let file = File(path: path) else { return nil }
        self.init(file: file)
    }
    
    /**
     Process all declarations in a file.
     
     - returns: Processing result
     */
    public func process() throws -> [String: [Registration]] {
        guard let substructure = structure.substructure else {
            throw Error.failedToParse(file.path!)
        }
        var containers: [String: [Registration]] = [:]
        lastProcessedDocRange = 0..<1
        
        for declaration in substructure {
            guard declaration.kind == .Class || declaration.kind == .Extension else { continue }
            let classDecl = declaration as! SourceKitDeclaration
            
            if let (containerName, registration) = process(class: classDecl) {
                let key = containerName.camelCased
                containers[key] = containers[key] ?? []
                containers[key]?.append(registration)
            }
        }
        return containers
    }
    
    /**
     Process class declaration.
     
     - parameters:
     - classDecl: Class declaration
     - docs: Closure to generate documentation from declaration
     
     - returns: A template for class registration and the name of container to register it in
     or `nil` if class should not be registered.
     */
    func process(class declaration: SourceKitDeclaration) -> (String, Registration)? {
        guard let classDocs = docs(declaration) else { return nil }
        
        let type = declaration[Structure.Key.name] as! String
        var containerName: String = "base"
        var definitionName: String?
        var registerAs: String?
        var constructorToRegister: String?
        var tagToRegister: String?
        var scopeToRegister: String?
        var implementsToRegister = [String]()
        var storyboardInstantiatable: Bool = false
        var shouldRegister = false
        
        for line in classDocs.lines() {
            if (line.contains(dipAnnotation: .register, modifier: { registerAs = $0 }) ||
                line.contains(dipAnnotation: .factory, modifier: { containerName = $0 ?? containerName }) ||
                line.contains(dipAnnotation: .scope, modifier: { scopeToRegister = $0 ?? scopeToRegister }) ||
                line.contains(dipAnnotation: .name, modifier: { definitionName = $0 ?? definitionName }) ||
                line.contains(dipAnnotation: .constructor, modifier: { constructorToRegister = $0 }) ||
                line.contains(dipAnnotation: .tag, modifier: { tag in
                    tagToRegister = tag?.trimmed("\"")
                    if tagToRegister?.isEmpty == true {
                        tagToRegister = nil
                    }
                }) ||
                line.contains(dipAnnotation: .implements, modifier: { implements in
                    implementsToRegister = implements?
                        .componentsSeparatedByString(",")
                        .map({ $0.trimmed(.whitespaceCharacterSet()) }) ?? []
                }) ||
                line.contains(dipAnnotation: .storyboardInstantiatable, modifier: { _ in
                    storyboardInstantiatable = true
                })) {
                shouldRegister = true
                continue
            }
        }
        
        let propertiesToResolve: [ResolvingProperty]
        let constructor: MethodProcessingResult?
        let registrationArguments: [Argument]
        let allConstructorArguments: [Argument]
        if let substructure = declaration[Structure.Key.substructure] as? [SourceKitRepresentable] {
            propertiesToResolve = process(properties: substructure)
            shouldRegister = shouldRegister || !propertiesToResolve.isEmpty
            
            constructor = process(methods: substructure)
            if constructor?.designated == true {
                shouldRegister = shouldRegister || constructor != nil
            }
            registrationArguments = constructor?.registrationArguments ?? []
            allConstructorArguments = constructor?.arguments ?? []
        }
        else {
            propertiesToResolve = []
            constructor = nil
            registrationArguments = []
            allConstructorArguments = []
        }
        
        if shouldRegister, let constructorName = constructorToRegister ?? constructor?.name {
            let closure = Closure(runtimeArguments: registrationArguments, constructorName: constructorName, constructorArguments: allConstructorArguments, type: type)
            let factory = Factory(type: type, arguments: registrationArguments, constructor: constructorName, closure: closure)
            return (containerName, Registration(name: definitionName ?? type, scope: scopeToRegister, registerAs: registerAs, tag: tagToRegister, factory: factory, implements: implementsToRegister, resolvingProperties: propertiesToResolve, storyboardInstantiatable: storyboardInstantiatable))
        }
        
        //TODO: if constructor is not defined in current class/extension
        //search for it in other class/extensions for the same type
        //if it is not there do not create factory (if it requires runtime arguments)
        
        return nil
    }
    
    /**
     Process all properties in a class. Returns all templates for resolving properties.
     
     - parameters:
     - properties: class declaration substructure containing properties declarations
     - docs: Closure to generate documentation from declaration
     */
    func process(properties declarations: [SourceKitRepresentable]) -> [ResolvingProperty] {
        return declarations
            .filter({ $0.kind == .VarInstance })
            .map({ $0 as! SourceKitDeclaration })
            .flatMap(process(property:))
    }
    
    /**
     Process single property declaration.
     
     - returns: A template for resolving the property if it is annotated with `"@dip.inject"` or `nil` otherwise.
     */
    func process(property declaration: SourceKitDeclaration) -> ResolvingProperty? {
        guard let propertyDocs = docs(declaration) else { return nil }
        
        let name = declaration[Structure.Key.name] as! String
        var injectAs: String?
        var tagToInject: String?
        
        for line in (propertyDocs as String).lines() {
            line.contains(dipAnnotation: .inject, modifier: { injectAs = $0 })
            line.contains(dipAnnotation: .tag, modifier: { tagToInject = $0 })
        }
        return ResolvingProperty(name: name, resolveAs: injectAs, tag: tagToInject)
    }
    
    /**
     Process all methods in a class.
     
     - returns: The name of constructor to use as a factory.
        * if declaration contains a single constructor returns its name and `false`.
        * if declaration contains several constructors and one of them is annotated with `@dip.designated` returns its name and `true`.
        * if declaration contains several constructors and none of them is marked with `@dip.designated` returns `nil`.
     */
    func process(methods declarations: [SourceKitRepresentable]) -> MethodProcessingResult? {
        var constructors: [MethodProcessingResult] = []
        for declaration in declarations {
            guard
                declaration.kind == .FunctionMethodInstance ||
                    declaration.kind == .FunctionMethodStatic ||
                    declaration.kind == .FunctionMethodClass else { continue }
            let declaration = declaration as! SourceKitDeclaration
            
            if let method = process(method: declaration) {
                if method.designated {
                    return method
                }
                else {
                    constructors.append(method)
                }
            }
        }
        
        return constructors.count > 1 ? nil : constructors.first
    }
    
    /**
     Process single method declaration.
     
     - returns: Constructor name and `true` if it is marked as designated
                or `nil` if method is not a constructor.
     */
    func process(method declaration: SourceKitDeclaration) -> MethodProcessingResult? {
        let name = declaration[Structure.Key.name] as! String
        if (declaration.kind == .FunctionMethodInstance && name.hasPrefix("init")) ||
            declaration.kind == .FunctionMethodStatic || declaration.kind == .FunctionMethodClass,
            let docs = docs(declaration)
        {
            var designated = false
            var registrationArgumentsNames = [String]()
            for line in docs.lines() {
                designated = line.contains(dipAnnotation: .designated)
                line.contains(dipAnnotation: .arguments, modifier: { arguments in
                    registrationArgumentsNames = arguments?
                        .componentsSeparatedByString(",")
                        .map({ $0.trimmed(.whitespaceCharacterSet()) }) ?? []
                })
            }
            var methodArguments: [Argument] = []
            let externalNames = name.methodArgumentsExternalNames()
            if let arguments = declaration[Structure.Key.substructure] as? [SourceKitRepresentable] {
                for (index, argument) in arguments.enumerate() {
                    guard argument.kind == .VarParameter else { continue }
                    let argument = argument as! SourceKitDeclaration
                    methodArguments.append(Argument(name: externalNames[index], internalName: argument[Structure.Key.name] as? String, type: argument[Structure.Key.typename] as! String))
                }
            }
            let registrationArguments = registrationArgumentsNames.flatMap(externalNames.indexOf).map({ methodArguments[$0] })
            return (name, designated, methodArguments, registrationArguments)
        }
        return nil
    }

}

extension String {
    func methodArgumentsExternalNames() -> [String] {
        guard let argumentsStart = rangeOfString("(")?.startIndex else { return [] }
        guard let argumentsEnd = rangeOfString(")")?.startIndex else { return [] }
        guard argumentsStart.successor() < argumentsEnd else { return [] }
        let constructorArgumentsString = substringWithRange(argumentsStart.successor()..<argumentsEnd)
        return constructorArgumentsString.componentsSeparatedByString(":")
    }
}
