import Dip

extension DependencyContainer {

    static func configureAll() { 
        let _ = baseContainer
        let _ = listModuleContainer
    }

    static func bootstrapAll() throws { 
        try baseContainer.bootstrap()
        try listModuleContainer.bootstrap()
    }

}
