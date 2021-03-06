//
//  RSDFormStepDataSource.swift
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

/// Delegate for the data source.
public protocol RSDFormStepDataSourceDelegate: class, NSObjectProtocol {
    
    /// Called when the answers tracked by the data source change.
    /// - parameter section: The section that changed.
    func answersDidChange(in section: Int)
}

/// `RSDFormStepDataSource`: the internal model for a table view controller. It provides the UITableViewDataSource,
/// manages and stores answers provided thru user input, and provides an RSDResult with those answers upon request.
///
/// It also provides several convenience methods for saving or selecting answers, checking if all answers are valid,
/// and retrieving specific model objects that may be needed by the ViewController.
///
/// The tableView data source is comprised of 3 objects:
///
/// 1. `RSDTableSection`: An object representing a section in the tableView. It has one or more RSDTableItemGroup objects.
///
/// 2. `RSDTableItemGroup`: An object representing a specific question supplied by `RSDStep` as an input field.
///     Upon init(), the ItemGroup will create one or more `RSDTableItem` objects representing the answer options
///     for the `RSDInputField`. The ItemGroup is responsible for storing/computing the answers for its `RSDInputField`.
///
/// 3. `RSDTableItem`: An object representing a specific answer option from the ItemGroup (RSDInputField), such as a
///     Yes or No choice in a boolean question or a string or number that's entered thru a text field. There will be one
///     TableItem for each indexPath in the tableView.
///
public protocol RSDFormStepDataSource : class {
    
    /// The delegate associated with this data source.
    weak var delegate: RSDFormStepDataSourceDelegate? { get set }
    
    /// The step associated with this data source.
    var step: RSDStep { get }
    
    /// The UI hints supported by this data source.
    var supportedHints: Set<RSDFormUIHint> { get }
    
    /// The current task path.
    var taskPath: RSDTaskPath { get }
    
    /// The table sections for this data source.
    var sections: [RSDTableSection] { get }
    
    /// The initial result when the data source was first displayed.
    var initialResults: [String : RSDResult] { get }
    
    /// This method is used to create an appropriate answer result for a given item group.
    /// - parameter itemGroup: The item group.
    /// - returns: The instantiated answer result (if applicable)
    func instantiateAnswerResult(for itemGroup: RSDInputFieldTableItemGroup) -> RSDAnswerResult?
    
    /// This method is used to vend the appropriate step answer result collection.
    /// - returns: The associated collection result.
    func collectionResult() -> RSDCollectionResult
}

extension RSDFormStepDataSource {
    
    /// Retrieve the `RSDTableItemGroup` with a specific `RSDInputField` identifier.
    /// - parameter identifier: The identifier of the `RSDInputField` assigned to the item group.
    /// - returns: The requested `RSDTableItemGroup`, or nil if it cannot be found.
    public func itemGroup(with identifier: String) -> RSDTableItemGroup? {
        for section in sections {
            for itemGroup in section.itemGroups {
                if (itemGroup as? RSDInputFieldTableItemGroup)?.inputField.identifier == identifier {
                    return itemGroup
                }
            }
        }
        return nil
    }
    
    /// Retrieve the 'RSDTableItemGroup' for a specific IndexPath.
    /// - parameter indexPath: The index path that represents the item group in the table view.
    /// - returns: The requested `RSDTableItemGroup`, or nil if it cannot be found.
    public func itemGroup(at indexPath: IndexPath) -> RSDTableItemGroup? {
        let section = sections[indexPath.section]
        for itemGroup in section.itemGroups {
            if itemGroup.beginningRowIndex ... itemGroup.beginningRowIndex + (itemGroup.items.count - 1) ~= indexPath.row {
                return itemGroup
            }
        }
        return nil
    }
    
    /// Retrieve the next item group after the current one at the given index path.
    /// - parameter indexPath: The index path that represents the item group in the table view.
    /// - returns: The next `RSDTableItemGroup` or `nil` if this was the last item.
    public func nextItem(after indexPath: IndexPath) -> RSDTableItemGroup? {
        let section = sections[indexPath.section]
        guard let itemGroup = itemGroup(at: indexPath),
            let idx = section.itemGroups.index(where: { $0.uuid == itemGroup.uuid })
            else {
                return nil
        }
        let nextIdx = idx.advanced(by: 1)
        if nextIdx < section.itemGroups.count {
            return section.itemGroups[nextIdx]
        } else if indexPath.section + 1 < sections.count {
            return sections[indexPath.section + 1].itemGroups.first
        } else {
            return nil
        }
    }
    
    /// Retrieve the index path that points at the given item group.
    /// - parameter itemGroup: The item group.
    /// - returns: The index path for the given item group or `nil` if not found.
    public func indexPath(for itemGroup: RSDTableItemGroup) -> IndexPath? {
        for (sectionIdx, section) in sections.enumerated() {
            var row: Int = 0
            for item in section.itemGroups {
                if itemGroup.uuid == item.uuid {
                    return IndexPath(row: row, section: sectionIdx)
                }
                row += item.items.count
            }
        }
        return nil
    }
    
    /// Save an answer for a specific IndexPath.
    /// - parameters:
    ///     - answer:      The object to be save as the answer.
    ///     - indexPath:   The `IndexPath` that represents the `RSDTableItem` in the table view.
    /// - throws: `RSDInputFieldError` if the answer is invalid.
    public func saveAnswer(_ answer: Any, at indexPath: IndexPath) throws {
        guard let itemGroup = self.itemGroup(at: indexPath) as? RSDInputFieldTableItemGroup else {
            return
        }
        
        try itemGroup.setAnswer(answer)
        _answerDidChange(for: itemGroup, at: indexPath)
    }
    
    /// Select or deselect the answer option for a specific IndexPath.
    /// - parameter indexPath: The `IndexPath` that represents the `RSDTableItem` in the  table view.
    /// - throws: `RSDInputFieldError` if the selection is invalid.
    public func selectAnswer(item: RSDChoiceTableItem, at indexPath: IndexPath) throws {
        guard let itemGroup = self.itemGroup(at: indexPath) as? RSDChoicePickerTableItemGroup else {
            return
        }
        
        try itemGroup.select(item, indexPath: indexPath)
        _answerDidChange(for: itemGroup, at: indexPath)
    }
    
    private func _answerDidChange(for itemGroup: RSDInputFieldTableItemGroup, at indexPath: IndexPath) {
        
        // Update the answers
        var stepResult = self.collectionResult()
        if let result = self.instantiateAnswerResult(for: itemGroup) {
            stepResult.appendInputResults(with: result)
        } else {
            stepResult.removeInputResult(with: itemGroup.identifier)
        }
        self.taskPath.appendStepHistory(with: stepResult)
        
        // inform delegate that answers have changed
        if let delegate = delegate {
            delegate.answersDidChange(in: indexPath.section)
        }
    }
    
    /// Determine if all answers are valid. Also checks the case where answers are required but one has not been provided.
    /// - returns: A `Bool` indicating if all answers are valid.
    public func allAnswersValid() -> Bool {
        for section in sections {
            for itemGroup in section.itemGroups {
                if !itemGroup.isAnswerValid {
                    return false
                }
            }
        }
        return true
    }
    
    /// Retrieve the `RSDTableItem` for a specific `IndexPath`.
    /// - parameter indexPath: The `IndexPath` that represents the table item in the table view.
    /// - returns: The requested `RSDTableItem`, or nil if it cannot be found.
    public func tableItem(at indexPath: IndexPath) -> RSDTableItem? {
        if let itemGroup = itemGroup(at: indexPath) {
            let index = indexPath.row - itemGroup.beginningRowIndex
            return itemGroup.items[index]
        }
        return nil
    }
}
