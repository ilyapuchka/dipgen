import Dip

extension DependencyContainer {

    static func configureAll() { 
        _ = baseContainer
        _ = listModuleContainer
    }

    static func bootstrapAll() throws { 
        try baseContainer.bootstrap()
        try listModuleContainer.bootstrap()
    }

}
