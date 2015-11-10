//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import ReactiveFoundation
import ReactiveKit
import UIKit

extension UITableView {
  private struct AssociatedKeys {
    static var DataSourceKey = "r_DataSourceKey"
  }
}

extension ObservableCollectionType where Collection == Array<Generator.Element> {
  public func bindTo(tableView: UITableView, proxyDataSource: RKTableViewProxyDataSource? = nil, createCell: (NSIndexPath, ObservableCollection<Collection>, UITableView) -> UITableViewCell) -> DisposableType {
    let array = self as! ObservableCollection<Collection>
    
    let dataSource = RKTableViewDataSource(array: array, tableView: tableView, proxyDataSource: proxyDataSource, createCell: createCell)
    objc_setAssociatedObject(tableView, &UITableView.AssociatedKeys.DataSourceKey, dataSource, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    return BlockDisposable { [weak tableView] in
      if let tableView = tableView {
        objc_setAssociatedObject(tableView, &UITableView.AssociatedKeys.DataSourceKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}

@objc public protocol RKTableViewProxyDataSource {
  optional func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  optional func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
  optional func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
  optional func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
  optional func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]?
  optional func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
  optional func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
  optional func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
  
  /// Override to specify custom row animation when row is being inserted, deleted or updated
  optional func tableView(tableView: UITableView, animationForRowAtIndexPaths indexPaths: [NSIndexPath]) -> UITableViewRowAnimation
  
  /// Override to specify custom row animation when section is being inserted, deleted or updated
  optional func tableView(tableView: UITableView, animationForRowInSections sections: Set<Int>) -> UITableViewRowAnimation
}

public class RKTableViewDataSource<T>: NSObject, UITableViewDataSource {
  
  private let array: ObservableCollection<[T]>
  private weak var tableView: UITableView!
  private let createCell: (NSIndexPath, ObservableCollection<[T]>, UITableView) -> UITableViewCell
  private weak var proxyDataSource: RKTableViewProxyDataSource?
  
  public init(array: ObservableCollection<[T]>, tableView: UITableView, proxyDataSource: RKTableViewProxyDataSource?, createCell: (NSIndexPath, ObservableCollection<[T]>, UITableView) -> UITableViewCell) {
    self.tableView = tableView
    self.createCell = createCell
    self.proxyDataSource = proxyDataSource
    self.array = array
    super.init()
    
    tableView.dataSource = self
    tableView.reloadData()
    
    array.observe(on: ImmediateExecutionContext) { [weak tableView] event in
      if let tableView = tableView {
        RKTableViewDataSource.applyRowUnitChangeSet(event, tableView: tableView, sectionIndex: 0, dataSource: proxyDataSource)
      }
    }.disposeIn(rBag)
  }
  
  private class func applyRowUnitChangeSet(changeSet: ObservableCollectionEvent<[T]>, tableView: UITableView, sectionIndex: Int, dataSource: RKTableViewProxyDataSource?) {
    
    if changeSet.inserts.count > 0 {
      let indexPaths = changeSet.inserts.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: dataSource?.tableView?(tableView, animationForRowAtIndexPaths: indexPaths) ?? .Automatic)
    }
    
    if changeSet.updates.count > 0 {
      let indexPaths = changeSet.updates.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: dataSource?.tableView?(tableView, animationForRowAtIndexPaths: indexPaths) ?? .Automatic)
    }
    
    if changeSet.deletes.count > 0 {
      let indexPaths = changeSet.deletes.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: dataSource?.tableView?(tableView, animationForRowAtIndexPaths: indexPaths) ?? .Automatic)
    }
  }
  
  /// MARK - UITableViewDataSource
  
  @objc public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  @objc public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return array.count
  }
  
  @objc public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return createCell(indexPath, array, tableView)
  }
  
  @objc public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return proxyDataSource?.tableView?(tableView, titleForHeaderInSection: section)
  }
  
  @objc public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return proxyDataSource?.tableView?(tableView, titleForFooterInSection: section)
  }
  
  @objc public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return proxyDataSource?.tableView?(tableView, canEditRowAtIndexPath: indexPath) ?? false
  }
  
  @objc public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return proxyDataSource?.tableView?(tableView, canMoveRowAtIndexPath: indexPath) ?? false
  }
  
  @objc public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
    return proxyDataSource?.sectionIndexTitlesForTableView?(tableView)
  }
  
  @objc public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
    if let section = proxyDataSource?.tableView?(tableView, sectionForSectionIndexTitle: title, atIndex: index) {
      return section
    } else {
      fatalError("Dear Sir/Madam, your table view has asked for section for section index title \(title). Please provide a proxy data source object in bindTo() method that implements `tableView(tableView:sectionForSectionIndexTitle:atIndex:)` method!")
    }
  }
  
  @objc public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    proxyDataSource?.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
  }
  
  @objc public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    proxyDataSource?.tableView?(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
  }
}