//
//  Annotations.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

enum DipAnnotation: String, CustomStringConvertible {
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
    
    #if !os(Linux)
    ///Marks class to implement StoryboardInstantiatable protocol.
    case storyboardInstantiatable
    #endif
    
    var description: String {
        return "@dip.\(rawValue)"
    }
}

