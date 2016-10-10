# dipgen
Code generator for [Dip](https://github.com/AliSoftware/Dip). It generates code that creates dependecy containers and registers components.

## Usage
1. Install dipgen. See *Installation* section for more detail
2. Annotate your code. See *Annotations* section for more details
3. Add new `Run Script` phase to your target, add the following script: `dipgen`. This will create `Dip.generated.swift` file in your `$SRCROOT`. Optionally you can add `-o` (or `--output`) argument and provide relative path to generated file
4. Build the project. That will generate the `Dip.generated.swift` that you can now add to your target


### Annotations
dipgen uses code comments as a source for annotations. You need to use at least one annotation in a your class source code if you want to generate registration code for it. dipgen will scan all the swift source files in the target and generate registration code for all annotated classes. You can annotate classes and their extensions (that can be usefull if the class that you want to register comes from another target, i.e. third party framework).

* `@dip.register [type_name]` - Marks component to be registered in container. Can have optional type to register
* `@dip.factory [name] Factory and container name to register component in. For example using name "root" will generate "rootContainer" and "RootFactory". By default will register in "base" container.
* `@dip.designated` - Marks constructor as designated. It will be used by component's definition as a factory. Required if annotated code defines more than one constructor. Will be ignored if `@dip.constructor` is used.
* `@dip.constructor constructor_name` - Constructor to use as factory. Will ignore `@dip.designated` annotation.
* `@dip.arguments` - list of runtime arguments for registration. Should match external names of arguments. Can be used only on method declaration (constructors or sattic/class methods).
* `@dip.name name` - Name of registration
* `@dip.tag tag` - Optional tag to register component for
* `@dip.implements type_name[, type_name]` - List of types implementd by component that can be resolved by the same definition.
* `@dip.scope scope` - Scope to register component in
* `@dip.inject [type_name]` - Marks property to be injected in `resolveDependencies` block. Property should have accessible setter.
* `@dip.storyboardInstantiatable` - Marks class to implement StoryboardInstantiatable protocol. Container that contains definition for this class will be added to ui containers.

See test project for another example of using annotations.

<details>
<summary>Annotations example</summary>

```swift
import UIKit

/**
 @dip.storyboardInstantiatable
 @dip.constructor init
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

	container.register(.Shared, factory: ListViewController.init)
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

	let listWireframe = container.register(.Unique, type: ListWireframe.self, tag: "some tag", factory: ListWireframe.init(rootWireframe:addWireframe:listPresenter:))
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

Dip.generated.swift

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
- [ ] Improve documentation, add annotations to cli help
- [x] Move to some templates engine, i.e. [Stencil](https://github.com/kylef/Stencil)
- [x] Move to some cli frameworks, i.e. Commandant
- [ ] Installing via Homebrew 
