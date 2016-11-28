# dipgen
Code generator for [Dip](https://github.com/AliSoftware/Dip). It generates code (surprise-surprise) that creates DI containers with all required registrations and corresponding factories.

## Why

Some DI containers on platforms like .Net provide auto-registration feature that lets you easily register all the components in your module based on some code conventions so that you do not have to register all of them manually. For large projects with established code conventions (i.e. promoted by VIPER architecture) it can drastically decrese amount of boilerplate registration code. In Swift this is not (yet) possible. 

One option is to use code generators like Generamba, originally developed to support VIPER architecture. But if you don't have strict code conventions in your code it may not work for you that well. That is when dipgen will be helpful. 

dipgen uses SourceKittenFramework to process all your source code files. It recognizes annotated classes or extensions and uses those annotations to generate registration code. In majority of cases you will need just a few annotations to generate proper registration code. If you put dipgen in a Build Step (the default way to use it actually) you will always have an up to date registrations. 

dipgen also generates factories that use containers under the hood but provide nice factory methods interface so that you can completely abstract your code from Dip. 

In addition having annotations in the documentation comments vs relying on external specification files improves your documentation, directly tells you what is injected and how when you look at it, so that you don't need to consult with registration code, and is much easier to keep in sync with your code.

## Usage
1. Install dipgen. See *Installation* section for more detail;
2. Annotate your code. See *Annotations* section for more details;
3. Add new `Run Script` phase to your target, add the following script: `dipgen`. This will generate files in your `$SRCROOT` or at current path. Optionally you can add `--output` argument to provide relative path to generated file;
4. Build the project. That will generate the `Dip.configure.swift` and `Dip.{containerName}.swift` for each generated container. Add them to your target.


### Annotations
dipgen uses code comments as a source for annotations. You need to use at least one annotation in a your class source code if you want to generate registration code for it. dipgen will scan all the Swift source files in the target and generate registration code for all annotated classes. You can annotate classes and their extensions (that can be usefull if the class that you want to register comes from another target, i.e. third party framework).

Here is the list of available annotations:

- `register [TypeName]` -- Marks component to be registered in container. Can have optional type to register.

- `factory Name` -- Factory and container name to register component in. For example using name "root" will generate "rootContainer" and "RootFactory". By default will register in "base" container.

- `designated` -- Marks constructor or static factory method as designated. It will be used as a factory for component's definition. Required if annotated code defines more than one constructor. Will be ignored if `constructor` annotation is used on class/extension.

- `constructor ConstructorName` - Constructor or static factory method to use as factory. Will ignore `designated` annotation.

- `arguments ArgumentName, ...` -- list of runtime arguments for factory. Should match _external_ names of arguments. Can be used only on method declaration (constructors or sattic/class methods).

- `name Name` -- Name of factory method. By default will use camelcased type name.

- `tag Tag` -- Optional tag to register component for. If no `name` annotation provided tag will be appended to default factory name.

- `implements TypeName[(tag)], ...` -- List of types with optional tags implementd by component that can be resolved by the same definition. Will be used for type-forwarding.

- `scope Scope` -- Scope to register component in. If not provided default scope defined by Dip will be applied.

- `inject [TypeName]` -- Marks property to be injected in `resolvingProperties` block. Property should have an accessible setter in resolved instance type.

- `storyboardInstantiatable` -- Marks class to implement `StoryboardInstantiatable` protocol. Container that contains definition for this class will be added to UI containers.

See test project for another example of using annotations.

<details>
<summary>Annotations example</summary>

```swift
import UIKit

/**
 @dip.storyboardInstantiatable
 */
class ListViewController: UIViewController {}

/**
 Some Real docs
 */
/**
 @dip.register ListWireframe
 @dip.name listWireframe
 @dip.scope Unique
 @dip.factory listModule
 @dip.tag some tag
 @dip.implements SomeProtocol
 */
class ListWireframe: SomeProtocol {
    
    /**
     @dip.inject AddWireframe
     @dip.tag tag
     */
    var addWireframe: AddWireframe
    
    /**@dip.inject*/
    var listPresenter: ListPresenter?
    
    /**@dip.inject*/var rootWireframe: RootWireframe
    
    init(rootWireframe: RootWireframe, addWireframe: AddWireframe) {
        self.rootWireframe = rootWireframe
        self.addWireframe = addWireframe
    }

    /**
     Designated initializer.
     */
    /**@dip.designated*/
    init(rootWireframe: RootWireframe, addWireframe: AddWireframe, listPresenter: ListPresenter) {
        self.rootWireframe = rootWireframe
        self.addWireframe = addWireframe
        self.listPresenter = listPresenter
    }
    
}
```
</details>
<details>
<summary>Generated code example</summary>

Dip.base.swift

```swift
import UIKit
import DipUI

extension ListViewController: StoryboardInstantiatable {}

let baseContainer = DependencyContainer { container in 
	unowned let container = container
	DependencyContainer.uiContainers.append(container)

	container.register(.Shared, factory: {
        ListViewController.initi()
    })
}

class BaseFactory {

	private let container: DependencyContainer
	
	init(container: DependencyContainer = baseContainer) {
		self.container = container
	}

	func listViewController() -> ListViewController {
		return try! container.resolve()
	}
}

```

Dip.listModule.swift

```swift
import Dip

let listModuleContainer = DependencyContainer { container in 
	unowned let container = container

	let listWireframe = container.register(.Unique, type: ListWireframe.self, tag: "some tag", factory: { 
        try ListWireframe.init(rootWireframe: container.resolve(), addWireframe: container.resolve(), listPresenter: container.resolve())
    })
		.implements(SomeProtocol.self)
		.resolvingProperties { container, resolved in 
			resolved.addWireframe = try container.resolve(tag: "tag") as AddWireframe
			resolved.listPresenter = try container.resolve()
			resolved.rootWireframe = try container.resolve()
		}
}

class ListModuleFactory {

	private let container: DependencyContainer

	init(container: DependencyContainer = listModuleContainer) {
		self.container = container
	}

	func listWireframeSomeTag() -> ListWireframe {
		return try! container.resolve(tag: "some tag")
	}

}

```

Dip.configure.swift

```swift
extension DependencyContainer {

	static func configureAll() {
		_ = baseContainer
		_ = listModule
	}

	static func bootstrapAll() throws {
		try baseContainer.bootstrap()
		try listModule.bootstrap()
	}

}
```
</details>

## Installation

Download project and run `make install` from it's source root. You need [Carthage](https://github.com/Carthage/Carthage) to be installed.


###TODO:

- [ ] Add example for each annotation
- [ ] Tests
- [x] Improve documentation, add annotations to cli help
- [x] Move to some templates engine, i.e. [Stencil](https://github.com/kylef/Stencil)
- [x] Move to some cli frameworks, i.e. Commandant
