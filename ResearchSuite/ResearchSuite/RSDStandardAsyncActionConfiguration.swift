//
//  RSDStandardAsyncActionConfiguration.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/// `RSDStandardAsyncActionConfiguration` is a concrete implementation of `RSDRecorderConfiguration` that can be used to
/// decode an async configuration for a recorder.
///
/// - note: There is no implementations of the recorders included in this framework. That is to allow this framework to
///         stand alone without requiring any embedded frameworks that may be unused by a given application. For example,
///         there are numerous different uses for the `CoreMotion` framework. One task module will use this framework
///         to gather background information about tremor, while another will use it to measure response time. Since
///         the use-case will differ with the task and when it is most appropriate to request permissions will differ
///         with the task, it is unnecessarily restrictive to enforce constraits generally. (syoung 11/20/2017)
public struct RSDStandardAsyncActionConfiguration : RSDRecorderConfiguration, Codable {

    /// A short string that uniquely identifies the asynchronous action within the task. If started asynchronously,
    /// then the identifier maps to a result stored in `RSDTaskResult.asyncResults`.
    public let identifier: String
    
    /// The standard permission type associated with this configuration.
    public let type: RSDStandardPermissionType
    
    /// An identifier marking the step to start the action. If `nil`, then the action will be started when
    /// the task is started.
    public let startStepIdentifier: String?
    
    /// An identifier marking the step at which to stop the action. If `nil`, then the action will be
    /// stopped when the task is stopped.
    public var stopStepIdentifier: String?
    
    private enum CodingKeys: String, CodingKey {
        case identifier, type, startStepIdentifier, stopStepIdentifier
    }
    
    /// List of the permissions required for this action.
    public var permissions: [RSDPermissionType] {
        return [type]
    }
    
    /// Whether or not the recorder requires background audio.
    public var requiresBackgroundAudio: Bool {
        return type == .motion || type == .location
    }
    
    /// Default initializer.
    ///
    /// - parameters:
    ///     - identifier: The identifier for this recorder.
    ///     - type: The permission type associated with this recorder.
    ///     - startStepIdentifier: The start step identifier (if any).
    ///     - stopStepIdentifier: The stop step identifier (if any).
    public init(identifier: String, type: RSDStandardPermissionType, startStepIdentifier: String?, stopStepIdentifier: String?) {
        self.identifier = identifier
        self.type = type
        self.startStepIdentifier = startStepIdentifier
        self.stopStepIdentifier = stopStepIdentifier
    }
    
    /// Validate the async action to check for any configuration that should throw an error. This method does nothing
    /// but is required by the `RSDAsyncActionConfiguration` protocol.
    public func validate() throws {
        // Do nothing
    }
}

extension RSDStandardAsyncActionConfiguration : RSDDocumentableCodableObject {
    
    static func codingKeys() -> [CodingKey] {
        return allCodingKeys()
    }
    
    private static func allCodingKeys() -> [CodingKeys] {
        let codingKeys: [CodingKeys] = [.identifier, .type, .startStepIdentifier, .stopStepIdentifier]
        return codingKeys
    }
    
    static func validateAllKeysIncluded() -> Bool {
        let keys: [CodingKeys] = allCodingKeys()
        for (idx, key) in keys.enumerated() {
            switch key {
            case .identifier:
                if idx != 0 { return false }
            case .type:
                if idx != 1 { return false }
            case .startStepIdentifier:
                if idx != 2 { return false }
            case .stopStepIdentifier:
                if idx != 3 { return false }
            }
        }
        return keys.count == 4
    }
    
    static func examples() -> [Encodable] {
        let types = RSDStandardPermissionType.allStandardTypes()
        return types.map { RSDStandardAsyncActionConfiguration(identifier: $0.rawValue, type: $0, startStepIdentifier: "\($0.rawValue)StartStep", stopStepIdentifier: "\($0.rawValue)StopStep") }
    }
}
