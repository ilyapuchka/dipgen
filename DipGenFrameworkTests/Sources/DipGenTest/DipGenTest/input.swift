import UIKit

protocol SomeProtocol {}
class RootWireframe {}
class AddWireframe {}
class ListPresenter {}

/**
 @dip.storyboardInstantiatable
 
 @dip.constructor init(nibName:bundle:)
 */
class ListViewController: UIViewController {}

/**
 @dip.register
 */
extension NSObject: SomeProtocol {}

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
class ListWireframe: NSObject, SomeProtocol {
    
    /**
     @dip.inject SomeProtocol
     @dip.tag tag
     */
    let addWireframe: AddWireframe
    /**@dip.inject*/
    let listPresenter: ListPresenter?
    /**@dip.inject*/let rootWireframe: RootWireframe
    
//    private let _listViewController = InjectedWeak<ListViewController>(tag: ListViewControllerIdentifier)
//    var listViewController : ListViewController? { return _listViewController.value }
    
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
