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

import XCTest
@testable import NeedleFramework

class DependencyLinkerTests: AbstractParserTests {

    static var allTests = [
        ("test_process_withComponents_verifyLinkages", test_process_withComponents_verifyLinkages),
        ("test_process_withComponentsNoDependency_verifyError", test_process_withComponentsNoDependency_verifyError)
    ]

    func test_process_withComponents_verifyLinkages() {
        let component = ASTComponent(name: "SomeComp", dependencyProtocolName: "ItsDependency", properties: [], expressionCallTypeNames: [])
        let dependency = Dependency(name: "ItsDependency", properties: [])

        let linker = DependencyLinker(components: [component], dependencies: [dependency])

        try! linker.process()

        XCTAssertEqual(component.dependencyProtocol, dependency)
    }

    func test_process_withComponentsNoDependency_verifyError() {
        let component = ASTComponent(name: "SomeComp", dependencyProtocolName: "ItsDependency", properties: [], expressionCallTypeNames: [])
        let dependency = Dependency(name: "WrongDep", properties: [])

        let linker = DependencyLinker(components: [component], dependencies: [dependency])

        do {
            try linker.process()
            XCTFail()
        } catch ProcessingError.fail(_) {
        } catch {
            XCTFail()
        }
    }
}
