//
//  Annotations.swift
//  dipgen
//
//  Created by Ilya Puchka on 01.10.16.
//  Copyright © 2016 Ilya Puchka. All rights reserved.
//

import Foundation

enum DipAnnotation: String, CustomStringConvertible {
    ///Marks component to be registered in container. Can have optional type to register
    case register
    ///Container to register component in. By default will register in "baseContainer"
    case container
    ///Marks constructor as designated. It will be used by component's definition as a factory.
    ///Required if type has more than one constructor
    case designated
    case name
    ///Optional tag to register component for
    case tag
    ///List of types implementd by component that can be resolved by the same definition.
    case implements
    ///Scope to register component in
    case scope
    ///Marks property to be injected in `resolveDependencies` block.
    ///Should be settable property on resolved type.
    case inject
    
    #if !os(Linux)
    ///Marks class to implement StoryboardInstantiatable protocol
    case storyboardInstantiatable
    #endif
    
    var description: String {
        return "@dip.\(rawValue)"
    }
}

