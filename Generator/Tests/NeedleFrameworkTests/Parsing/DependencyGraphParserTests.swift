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

import Concurrency
import XCTest
@testable import NeedleFramework

class DependencyGraphParserTests: AbstractParserTests {

    static var allTests = [
        ("test_parse_withTaskCompleteion_verifyTaskSequence", test_parse_withTaskCompleteion_verifyTaskSequence),
        ("test_parse_withTaskCompleteion_verifyResults", test_parse_withTaskCompleteion_verifyResults),
    ]

    func test_parse_withTaskCompleteion_verifyTaskSequence() {
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureUrl(for: "")
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]

        let executor = MockSequenceExecutor()
        var filterCount = 0
        var producerCount = 0
        var parserCount = 0
        executor.executionHandler = { (task: Task, result: Any) in
            if task is FileFilterTask {
                filterCount += 1
            } else if task is ASTProducerTask {
                producerCount += 1
            } else if task is ASTParserTask {
                parserCount += 1
            } else {
                XCTFail()
            }
        }

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            _ = try parser.parse(from: fixturesURL, excludingFilesWith: ["ha", "yay", "blah"], using: executor)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
        XCTAssertEqual(filterCount, files.count)
        XCTAssertEqual(producerCount, 6)
        XCTAssertEqual(parserCount, 6)
        XCTAssertEqual(producerCount, parserCount)
    }

    func test_parse_withTaskCompleteion_verifyResults() {
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureUrl(for: "")
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]
        let executor = MockSequenceExecutor()

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            let (components, imports) = try parser.parse(from: fixturesURL, excludingFilesWith: ["ha", "yay", "blah"], using: executor)
            let childComponent = components.filter { $0.name == "MyChildComponent" }.first!
            let parentComponent = components.filter { $0.name == "MyComponent" }.first!
            XCTAssertTrue(childComponent.parents.first! == parentComponent)
            XCTAssertEqual(components.count, 7)
            XCTAssertEqual(imports, ["import Foundation", "import RIBs", "import RxSwift", "import UIKit", "import Utility"])
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
    }
}

class MockSequenceExecutor: SequenceExecutor {

    var executeCallCount = 0
    var executionHandler: ((Task, Any) -> ())?

    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        executeCallCount += 1

        var result = initialTask.typeErasedExecute()
        var executionResult = execution(initialTask, result)
        executionHandler?(initialTask, result)
        while true {
            switch executionResult {
            case .continueSequence(let task):
                result = task.typeErasedExecute()
                executionResult = execution(task, result)
                executionHandler?(task, result)
            case .endOfSequence(let finalResult):
                return MockExecutionHandle(result: finalResult)
            }
        }
    }
}

class MockExecutionHandle<T>: SequenceExecutionHandle<T> {

    var awaitCallCount = 0
    var awaitHandler: ((TimeInterval?) -> ())?

    var cancelCallCount = 0
    var cancelHandler: (() -> ())?

    let result: T

    init(result: T) {
        self.result = result
    }

    override func await(withTimeout timeout: TimeInterval?) throws -> T {
        awaitCallCount += 1
        awaitHandler?(timeout)
        return result
    }

    override func cancel() {
        cancelCallCount += 1
        cancelHandler?()
    }
}
