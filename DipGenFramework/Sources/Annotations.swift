//
//  Annotations.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

public enum DipAnnotation: String, CustomStringConvertible {
    ///Marks component to be registered in container. Can have optional type to register.
    case register
    ///Factory and container name to register component in.
    ///For example using name "root" will generate "rootContainer" and "RootFactory".
    ///By default will register in "base" container.
    case factory
    ///Marks constructor as designated. It will be used by component's definition as a factory.
    ///Required if type has more than one constructor.
    ///Will be ignored if type is already annotated with @dip.constructor.
    case designated
    ///Constructor to use as factory.
    case constructor
    ///List of runtime arguments for registration. Should match external names of arguments.
    ///Can be used only on method declaration (constructors or sattic/class methods).
    case arguments
    ///Name of factory method.
    case name
    ///Optional tag to register component for.
    case tag
    ///List of types implementd by component that can be resolved by the same definition.
    case implements
    ///Scope to register component in.
    case scope
    ///Marks property to be injected in `resolveDependencies` block.
    ///Should be settable property on resolved type.
    case inject
    ///Marks class to implement StoryboardInstantiatable protocol.
    case storyboardInstantiatable
    
    public var description: String {
        return "@dip.\(rawValue)"
    }
    
    public static let allValues: [DipAnnotation] = [.register, .factory, .designated, .constructor, .arguments, .name, .tag, .implements, .scope, .inject, .storyboardInstantiatable]
    
    public var help: String {
        switch self {
        case .register: return "- register [TypeName] -- Marks component to be registered in container. Can have optional type to register"
        case .factory: return "- factory Name -- Factory and container name to register component in. For example using name \"root\" will generate \"rootContainer\" and \"RootFactory\". By default will register in \"base\" container."
        case .designated: return "- designated -- Marks constructor as designated. It will be used by component's definition as a factory. Required if annotated code defines more than one constructor. Will be ignored if constructor annotation is used."
        case .constructor: return "- constructor ConstructorName - Constructor to use as factory. Will ignore designated annotation."
        case .arguments: return "- arguments -- list of runtime arguments for registration. Should match external names of arguments. Can be used only on method declaration (constructors or sattic/class methods)."
        case .name: return "- name Name -- Name of factory method. By default will use camelcased type name."
        case .tag: return "- tag Tag -- Optional tag to register component for. If no custom name provided tag will be appended to default factory name."
        case .implements: return "- implements TypeName[, TypeName] -- List of types implementd by component that can be resolved by the same definition."
        case .scope: return "- scope Scope -- Scope to register component in."
        case .inject: return "- inject [TypeName] -- Marks property to be injected in resolveDependencies block. Property should have accessible setter."
        case .storyboardInstantiatable: return "- storyboardInstantiatable -- Marks class to implement StoryboardInstantiatable protocol. Container that contains definition for this class will be added to ui containers."
        }
    }

}

