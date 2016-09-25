import Foundation
import SourceKittenFramework

indirect enum Template {
    
    case container(name: String, registrations: [Template])
    case registration(name: String, scope: String, registerAs: String, tag: String?, type: String, constructor: String, implements: Template?, resolvingProperties: Template?, storyboardInstantiatable: Template?)
    case implements(types: String)
    case resolvingProperties(properties: [Template])
    case resolveProperty(name: String, tag: String?, injectAs: String?)
    case storyboardInstantiatable(type: String)
    
    func description(tabs: Int = 0) -> String {
        let indentation = (0..<tabs).reduce("", combine: { $0.0 + "\t" })
        switch self {
        case let .container(name, registrations):
            let registrations = registrations.map({ $0.description(tabs + 1) }).joinWithSeparator("")
            return "public let \(name) = DependencyContainer { container in \n\tunowned let container = container\n\n\(registrations)}\n"
        case let .registration(name, scope, registerAs, tag, type, constructor, implements, resolvingProperties, _):
            let scope = ".\(scope)"
            let registerAs = "\(registerAs).self"
            let tag = tag != nil ? "\"\(tag!)\"" : "nil"
            let factory = "\(type).\(constructor)"
            var description = "\(indentation)let \(name) = container.register(\(scope), type: \(registerAs), tag: \(tag), factory: \(factory))\n"
            if let implements = implements {
                description.appendContentsOf(implements.description(tabs + 1))
            }
            if let resolvingProperties = resolvingProperties {
                description.appendContentsOf(resolvingProperties.description(tabs + 1))
            }
            return description
        case let .implements(types):
            return "\(indentation).implements(\(types))\n"
        case let .resolvingProperties(properties):
            let properties = properties.map({ $0.description(tabs + 1) }).joinWithSeparator("")
            return String(format: "\(indentation).resolvingProperties { container, resolved in \n\(properties)\(indentation)}\n")
        case let .resolveProperty(name, tag, injectAs):
            let tag = tag != nil ? "\"\(tag!)\"" : "nil"
            let injectAs = injectAs != nil ? " as \(injectAs!)" : ""
            return "\(indentation)resolved.\(name) = try container.resolve(tag: \(tag))\(injectAs)\n"
        case let .storyboardInstantiatable(type):
            return "extension \(type): StoryboardInstantiatable {}"
        }
    }
    
}

enum Key {
    static let substructure     = "key.substructure"
    static let kind             = "key.kind"
    static let offset           = "key.offset"
    static let name             = "key.name"
    static let typename         = "key.typename"
}

public enum Dip {
    ///Marks component to be registered in container. Can have optional type to register
    public static let register          = "@dip.register"
    ///Container to register component in. By default will register in "baseContainer"
    public static let container         = "@dip.container"
    ///Marks constructor as designated. It will be used by component's definition as a factory.
    ///Required if type has more than one constructor
    public static let designated        = "@dip.designated"
    public static let name              = "@dip.name"
    ///Optional tag to register component for
    public static let tag               = "@dip.tag"
    ///List of types implementd by component that can be resolved by the same definition.
    public static let implements        = "@dip.implements"
    ///Scope to register component in
    public static let scope             = "@dip.scope"
    ///Marks property to be injected in `resolveDependencies` block.
    ///Should be settable property on resolved type.
    public static let inject            = "@dip.inject"
    public static let storyboardInstantiatable = "@dip.storyboardInstantiatable"
}

typealias SourceKitDeclaration = [String: SourceKitRepresentable]

extension File {
    
    //getDocumentationCommentBody does not work correctly in xcode 8
    func getDocumentationCommentBody(syntaxMap: SyntaxMap, inout lastProcessedDocRange: Range<Int>) -> (structure: SourceKitDeclaration) -> String? {
        return { (structure: SourceKitDeclaration) -> String? in
            guard let offset = (structure[Key.offset] as? Int64).map({ Int($0) }) else { return nil }
            guard let range = syntaxMap.commentRangeBeforeOffset(offset) else { return nil }
            //check if we already processed this range
            guard range.startIndex >= lastProcessedDocRange.endIndex else { return nil }
            
            lastProcessedDocRange = range
            return self.contents.substringWithRange(self.contents.stringRange(lastProcessedDocRange)).stringByTrimmingCharactersInSet(docCommentCharacterSet)
        }
    }
    
}

extension String {
    
    func stringRange(range: Range<Int>) -> Range<Index> {
        return startIndex.advancedBy(range.startIndex)..<startIndex.advancedBy(range.endIndex)
    }
    
}

extension Line {
    
    func contains(dipAnnotation annotation: String, modifier: ((String?)->Void)? = nil) -> Bool {
        let content = self.content
        guard let annotationRange = content.rangeOfString(annotation)
            where annotationRange.endIndex <= content.endIndex else { return false }
        
        if let modifier = modifier {
            let annotationEnd = content.rangeOfString("*/")?.startIndex ?? content.endIndex
            if annotationRange.endIndex < content.endIndex {
                let modifiedStart = annotationRange.endIndex.advancedBy(1)
                if modifiedStart < annotationEnd {
                    let modified = String(content[modifiedStart..<annotationEnd]).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
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

extension NSFileManager {
    
    func swiftFiles(at path: String) throws -> [File] {
        let files = try contentsOfDirectoryAtPath(path)
        let swiftFiles = files.filter({ $0.isSwiftFile() })
        return swiftFiles.flatMap(File.init)
    }
    
}

extension Structure {
    
    var substructure: [SourceKitRepresentable] {
        return dictionary[Key.substructure] as! [SourceKitRepresentable]
    }
    
}

private let docCommentCharacterSet = NSCharacterSet(charactersInString: "/*\t\n")
typealias ProcessingResult = [String: [Template]]

/// Generates string to write into file from processing result.
func generate(containers: ProcessingResult) -> String {
    var content = containers.map({ Template.container(name: $0.0, registrations: $0.1).description() }).joinWithSeparator("\n")
    var storyboardInstantiatables: [Template] = []
    for registration in containers.values.flatten() {
        guard case let .registration(_, _, _, _, _, _, _, _, storyboardInstantiatable) = registration else { continue }
        if let storyboardInstantiatable = storyboardInstantiatable {
            storyboardInstantiatables.append(storyboardInstantiatable)
        }
    }
    if !storyboardInstantiatables.isEmpty {
        let extensions = storyboardInstantiatables.map({ $0.description() }).joinWithSeparator("\n")
        content = "import DipUI\n\n\(extensions)\n\n\(content)"
    }
    else {
        content = "import Dip\n\n\(content)"
    }
    print(content)
    return content
}

/// Process several files and returns conatiner-to-registrations dictioanry.
func process(files: [File]) -> ProcessingResult {
    var containers: ProcessingResult = [:]
    for file in files {
        process(file, containers: &containers)
    }
    return containers
}

/// Process all declarations in a file. Stores all registrations in `containers` dictionary.
func process(file: File, inout containers: ProcessingResult) {
    let structure = Structure(file: file)
    let syntaxMap = SyntaxMap(file: file)
    
    var lastProcessedDocRange: Range<Int> = 0..<1
    let docs = file.getDocumentationCommentBody(syntaxMap, lastProcessedDocRange: &lastProcessedDocRange)
    
    for classDecl in structure.substructure {
        let classDecl = classDecl as! SourceKitDeclaration
        guard classDecl[Key.kind]!.isEqualTo(SwiftDeclarationKind.Class.rawValue) else { continue }
        
        if let (containerName, registration) = processClass(classDecl, docs: docs) {
            containers[containerName] = containers[containerName] ?? []
            containers[containerName]?.append(registration)
        }
    }
}

/// Process class declaration. Returns a template for class registration and the name of container to register it in.
/// Returns nil if class should not be registered.
func processClass(classDecl: SourceKitDeclaration, docs: (SourceKitDeclaration)->(String?)) -> (String, Template)? {
    guard let classDocs = docs(classDecl) else { return nil }
    
    let type = classDecl[Key.name] as! String
    var containerName = "baseContainer"
    var definitionName = "_"
    var registerAs = classDecl[Key.name] as! String
    var tagToRegister: String?
    var scopeToRegister = "Shared"
    var implementsToRegister = ""
    var storyboardInstantiatable: Template?
    var shouldRegister = false
    
    for line in (classDocs as NSString).lines() {
        if (line.contains(dipAnnotation: Dip.register, modifier: { registerAs = $0 ?? registerAs }) ||
            line.contains(dipAnnotation: Dip.container, modifier: { containerName = $0 ?? containerName }) ||
            line.contains(dipAnnotation: Dip.scope, modifier: { scopeToRegister = $0 ?? scopeToRegister }) ||
            line.contains(dipAnnotation: Dip.name, modifier: { name in
                definitionName = name ?? String(type.characters.prefix(1)).lowercaseString + String(type.characters.dropFirst())
            }) ||
            line.contains(dipAnnotation: Dip.tag, modifier: { tag in
                tagToRegister = tag?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\""))
                if tagToRegister?.isEmpty == true {
                    tagToRegister = nil
                }
            }) ||
            line.contains(dipAnnotation: Dip.implements, modifier: { implements in
                implementsToRegister = implements?
                    .componentsSeparatedByString(",")
                    .map({ "\($0).self".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) })
                    .joinWithSeparator(", ") ?? ""
            }) ||
            line.contains(dipAnnotation: Dip.storyboardInstantiatable, modifier: { _ in
                storyboardInstantiatable = Template.storyboardInstantiatable(type: type)
            })) {
            shouldRegister = true
            continue
        }
    }
    
    let propertiesToResolve = processProperties(classDecl, docs: docs)
    shouldRegister = shouldRegister || !propertiesToResolve.isEmpty
    
    let (constructor, designated) = processMethods(classDecl, docs: docs)
    if designated {
        shouldRegister = shouldRegister || constructor != nil
    }

    if shouldRegister, let constructor = constructor {
        let registration = Template.registration(
            name: definitionName,
            scope: scopeToRegister,
            registerAs: registerAs,
            tag: tagToRegister,
            type: type,
            constructor: constructor,
            implements: Template.implements(types: implementsToRegister),
            resolvingProperties: Template.resolvingProperties(properties: propertiesToResolve),
            storyboardInstantiatable: storyboardInstantiatable
        )
        return (containerName, registration)
    }
    
    return nil
}

/// Process all properties in a class. Returns all templates for resolving properties.
func processProperties(classDecl: SourceKitDeclaration, docs: (SourceKitDeclaration)->(String?)) -> [Template] {
    var propertiesToResolve: [Template] = []
    for propertyDecl in classDecl[Key.substructure] as! [SourceKitRepresentable] {
        let propertyDecl = propertyDecl as! SourceKitDeclaration
        guard propertyDecl[Key.kind]!.isEqualTo(SwiftDeclarationKind.VarInstance.rawValue) else { continue }
        
        if let propertyToResolve = processProperty(propertyDecl, docs: docs) {
            propertiesToResolve.append(propertyToResolve)
        }
    }
    return propertiesToResolve
}

/// Process single property declaration. Returns template for resolving this property if it is annotated with `@dip.inject`.
func processProperty(propertyDecl: SourceKitDeclaration, docs: (SourceKitDeclaration)->(String?)) -> Template? {
    guard let propertyDocs = docs(propertyDecl) else { return nil }
    
    let name = propertyDecl[Key.name] as! String
    var injectAs: String?
    var tagToInject: String?
    
    for line in (propertyDocs as String).lines() {
        line.contains(dipAnnotation: Dip.inject, modifier: { injectAs = $0 })
        line.contains(dipAnnotation: Dip.tag, modifier: { tagToInject = $0 })
    }
    return Template.resolveProperty(name: name, tag: tagToInject, injectAs: injectAs)
}

/// Process all methods in a class. Returns name of constructor to use as a factory.
/// If htere is single constructor will return its name and `false`.
/// If there are several constructors and one of them is annotated with `@dip.designated` will return its name and `true`.
/// If there are several constructors and none of them is marked with `@dip.designated` will return `nil` and `false`.
func processMethods(classDecl: SourceKitDeclaration, docs: (SourceKitDeclaration)->(String?)) -> (name: String?, designated: Bool) {
    var constructors: [String] = []
    for methodDecl in classDecl[Key.substructure] as! [SourceKitRepresentable] {
        let methodDecl = methodDecl as! SourceKitDeclaration
        guard methodDecl[Key.kind]!.isEqualTo(SwiftDeclarationKind.FunctionMethodInstance.rawValue) else { continue }
        
        if let (name, designated) = processMethod(methodDecl, docs: docs) {
            if designated {
                return (name, true)
            }
            else {
                constructors.append(name)
            }
        }
    }
    return (constructors.count == 1 ? constructors.first : nil, false)
}

/// Process single method declaration. 
/// Returns constructor name and true if it is marked as designated.
/// If method is not a constructor returns nil.
func processMethod(methodDecl: SourceKitDeclaration, docs: (SourceKitDeclaration)->(String?)) -> (name: String, designated: Bool)? {
    let name = methodDecl[Key.name] as! String
    if name.hasPrefix("init") {
        if let methodDocs = docs(methodDecl) where methodDocs.containsString(Dip.designated) {
            return (name, true)
        }
        else {
            return (name, false)
        }
    }
    return nil
}

let files = try! NSFileManager.defaultManager().swiftFiles(at: ".")

do {
    let containers = process(files)
    let content = generate(containers)
    try content.writeToFile("./output.swift", atomically: true, encoding: NSUTF8StringEncoding)
} catch {
    print(error)
}

