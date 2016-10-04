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
    ///Container to register component in. By default will register in "baseContainer".
    case container
    ///Marks constructor as designated. It will be used by component's definition as a factory.
    ///Required if type has more than one constructor.
    ///Will be ignored if type is already annotated with @dip.constructor.
    case designated
    ///Constructor to use as factory.
    ///Will ignore @dip.designated annotation.
    case constructor
    ///List of factory runtime arguments. Should match external names of arguments. 
    ///Not listed arguments will be resolved by container.
    ///Can be used on a class/extension or on method declaration.
    ///Method annotation will be ignored if class/extension is annotated already.
    case arguments
    ///Name of registration.
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

