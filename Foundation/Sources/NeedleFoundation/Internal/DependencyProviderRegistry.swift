//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Needle internal registry of dependency providers.
/// - note: This class is only needed until Swift supports extensions
/// overriding methods. This is an internal class to the Needle dependency
/// injection framework. Application code should never use this class
/// directly.
// TODO: Remove this once Swift supports extension overriding methods.
// Once that happens, we can declare an `open createDependencyProvider`
// method in the base component class. Generate extensions to all the
// component subclasses that override the method to instantiate the
// dependnecy providers.
public class __DependencyProviderRegistry {

    /// The singleton instance.
    public static let instance = __DependencyProviderRegistry()

    /// Register the given factory closure with given key.
    ///
    /// - note: This method is thread-safe.
    /// - parameter componentPath: The dependency graph path of the component
    /// the provider is for.
    /// - parameter dependencyProviderFactory: The closure that takes in a
    /// component to be injected and returns a provider instance that conforms
    /// to the component's dependency protocol.
    public func registerDependencyProviderFactory(`for` componentPath: String, _ dependencyProviderFactory: @escaping (ComponentType) -> AnyObject) {
        providerFactoryLock.lock()
        defer {
            providerFactoryLock.unlock()
        }

        providerFactories[componentPath.hashValue] = dependencyProviderFactory
    }

    /// Retrieve the dependency provider for the given component and its parent.
    ///
    /// - parameter component: The component that uses the returned dependency provider.
    /// - returns: The dependency provider for the given component.
    func dependencyProvider(`for` component: ComponentType) -> AnyObject {
        providerFactoryLock.lock()
        defer {
            providerFactoryLock.unlock()
        }

        let pathString = component.path.joined(separator: "->")
        if let factory = providerFactories[pathString.hashValue] {
            return factory(component)
        } else {
            // This case should never occur with properly generated Needle code.
            // This is useful for Needle generator development only.
            fatalError("Missing dependency provider factory for \(component.path)")
        }
    }

    private let providerFactoryLock = NSRecursiveLock()
    private var providerFactories = [Int: (ComponentType) -> AnyObject]()

    private init() {}
}
