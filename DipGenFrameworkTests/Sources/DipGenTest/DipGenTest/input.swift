import UIKit

protocol SomeProtocol {}
class RootWireframe {}
class AddWireframe {}
class ListPresenter {}

/**
 @dip.storyboardInstantiatable
 
 @dip.constructor init(nibName:bundle:)
 @dip.arguments nibName
 @dip.factory BaseFactory
 */
class ListViewController: UIViewController {}

/**
 Some Real docs
 */
/**
 @dip.register SomeProtocol
 @dip.name listWireframe
 @dip.scope Unique
 @dip.container listModule
 @dip.tag some tag
 @dip.implements NSObject, SomeProtocol
 */
class ListWireframe: NSObject {
    
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
        self.listPresenter = ListPresenter()
    }

    /**
     Designated initializer.
     */
    /**
     @dip.designated
     */
    init(rootWireframe: RootWireframe, addWireframe: AddWireframe, listPresenter: ListPresenter) {
        self.rootWireframe = rootWireframe
        self.addWireframe = addWireframe
        self.listPresenter = listPresenter
    }
    
}
