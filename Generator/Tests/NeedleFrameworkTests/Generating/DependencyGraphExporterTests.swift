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
import Foundation
import XCTest
@testable import NeedleFramework

class DependencyGraphExporterTests: AbstractGeneratorTests {
    let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/")

    @available(OSX 10.12, *)
    static var allTests = [
        ("test_export_verifyContent", test_export_verifyContent),
    ]

    @available(OSX 10.12, *)
    func test_export_verifyContent() {
        let (components, imports) = sampleProjectParsed()
        let executor = MockSequenceExecutor()
        let exporter = DependencyGraphExporter()

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("generated.swift")
        let headerDocPath = fixturesURL.appendingPathComponent("HeaderDoc.txt").path
        try? exporter.export(components, with: imports, to: outputURL.path, using: executor, include: headerDocPath)
        let generated = try? String(contentsOf: outputURL)
        XCTAssertNotNil(generated, "Could not read the generated file")

        let url = fixturesURL.appendingPathComponent("generated.swift")
        let expected = try? String(contentsOf: url)
        XCTAssertNotNil(expected, "Could not read in fixture file")

        XCTAssertEqual(generated, expected)
    }
}
