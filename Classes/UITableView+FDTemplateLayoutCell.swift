//
//  UITableView+FDTemplateLayoutCell.swift
//  TableViewDynamicHeight
//
//  Created by 伯驹 黄 on 2017/2/22.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

extension UITableView {

    private struct Keys {
        static var fd_systemFittingHeightForConfiguratedCell = "fd_systemFittingHeightForConfiguratedCell"
        static var fd_templateCell = "fd_templateCell"
        static var fd_heightForHeaderFooterView = "fd_heightForHeaderFooterView"
    }

    private var systemAccessoryWidths: [UITableViewCellAccessoryType: CGFloat] {
        return [
            .none: 0,
            .disclosureIndicator: 34,
            .detailDisclosureButton: 68,
            .checkmark: 40,
            .detailButton: 48,
        ]
    }

    // [bug fix] after iOS 10.3, Auto Layout engine will add an additional 0 width constraint onto cell's content view, to avoid that, we add constraints to content view's left, right, top and bottom.
    private var isSystemVersionEqualOrGreaterThen10_2: Bool {
        return UIDevice.current.systemVersion.compare("10.2", options: .numeric) == .orderedDescending
    }

    func fd_systemFittingHeightForConfiguratedCell(_ cell: UITableViewCell) -> CGFloat {
        var contentViewWidth = frame.width

        var cellBounds = cell.bounds
        cellBounds.size.width = contentViewWidth
        cell.bounds = cellBounds
        
        var accessroyWidth: CGFloat = 0

        // If a cell has accessory view or system accessory type, its content view's width is smaller
        // than cell's by some fixed values.
        if let accessoryView = cell.accessoryView {
            // 16为系统cell左边的空隙
            accessroyWidth = 16 + accessoryView.frame.width
        } else {
            accessroyWidth = systemAccessoryWidths[cell.accessoryType] ?? 0
        }
        contentViewWidth -= accessroyWidth

        // If not using auto layout, you have to override "-sizeThatFits:" to provide a fitting size by yourself.
        // This is the same height calculation passes used in iOS8 self-sizing cell's implementation.
        //
        // 1. Try "- systemLayoutSizeFittingSize:" first. (skip this step if 'fd_enforceFrameLayout' set to YES.)
        // 2. Warning once if step 1 still returns 0 when using AutoLayout
        // 3. Try "- sizeThatFits:" if step 1 returns 0
        // 4. Use a valid height or default row height (44) if not exist one

        var fittingHeight: CGFloat = 0
        if !cell.fd_usingFrameLayout && contentViewWidth > 0 {
            // Add a hard width constraint to make dynamic content views (like labels) expand vertically instead
            // of growing horizontally, in a flow-layout manner.
            let widthFenceConstraint = NSLayoutConstraint(item: cell.contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: contentViewWidth)
            cell.contentView.addConstraint(widthFenceConstraint)

            
            var edgeConstraints: [NSLayoutConstraint] = []
            if isSystemVersionEqualOrGreaterThen10_2 {
                // To avoid confilicts, make width constraint softer than required (1000)
                widthFenceConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)

                // Build edge constraints
                let leftConstraint = NSLayoutConstraint(item: cell.contentView, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 0)
                let rightConstraint = NSLayoutConstraint(item: cell.contentView, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: accessroyWidth)
                let topConstraint = NSLayoutConstraint(item: cell.contentView, attribute: .top, relatedBy: .equal, toItem: cell, attribute: .top, multiplier: 1, constant: 0)
                let bottomConstraint = NSLayoutConstraint(item: cell.contentView, attribute: .bottom, relatedBy: .equal, toItem: cell, attribute: .bottom, multiplier: 1, constant: 0)

                edgeConstraints = [leftConstraint, rightConstraint, topConstraint, bottomConstraint]
                cell.addConstraints(edgeConstraints)
            }

            cell.contentView.addConstraint(widthFenceConstraint)

            // Auto layout engine does its math
            fittingHeight = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height

            // Clean-ups
            cell.contentView.removeConstraint(widthFenceConstraint)
            if isSystemVersionEqualOrGreaterThen10_2 {
                cell.removeConstraints(edgeConstraints)
            }
            fd_debugLog("calculate using system fitting size (AutoLayout) -\(fittingHeight)")
        }

        if fittingHeight == 0 {
            #if DEBUG
                // Warn if using AutoLayout but get zero height.
                if cell.contentView.constraints.count > 0 {
                    if objc_getAssociatedObject(self, &Keys.fd_systemFittingHeightForConfiguratedCell) == nil && !cell.fd_usingFrameLayout {
                        print("[FDTemplateLayoutCell] Warning once only: Cannot get a proper cell height (now 0) from '- systemFittingSize:'(AutoLayout). You should check how constraints are built in cell, making it into 'self-sizing' cell.")
                        objc_setAssociatedObject(self, &Keys.fd_systemFittingHeightForConfiguratedCell, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    }
                }
            #endif

            // Try '- sizeThatFits:' for frame layout.
            // Note: fitting height should not include separator view.

            fittingHeight = cell.sizeThatFits(CGSize(width: contentViewWidth, height: 0)).height

            fd_debugLog("calculate using sizeThatFits - \(fittingHeight)")
        }

        // Still zero height after all above.
        if fittingHeight == 0 {
            // Use default row height.
            fittingHeight = 44
        }

        // Add 1px extra space for separator line if needed, simulating default UITableViewCell.
        if separatorStyle != .none {
            fittingHeight += 1.0 / UIScreen.main.scale
        }

        return fittingHeight
    }

    // MARK: - FDTemplateLayoutCell

    /// Access to internal template layout cell for given reuse identifier.
    /// Generally, you don't need to know these template layout cells.
    ///
    /// @param identifier Reuse identifier for cell which must be registered.
    ///
    func fd_templateCell(for reuseIdentifier: String) -> UITableViewCell {
        assert(!reuseIdentifier.isEmpty, "Expect a valid identifier - \(reuseIdentifier)")
        var templateCellsByIdentifiers: [String: UITableViewCell]? = objc_getAssociatedObject(self, &Keys.fd_templateCell) as? [String: UITableViewCell]
        if templateCellsByIdentifiers == nil {
            templateCellsByIdentifiers = [String: UITableViewCell]()
            objc_setAssociatedObject(self, &Keys.fd_templateCell, templateCellsByIdentifiers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        var templateCell = templateCellsByIdentifiers![reuseIdentifier]
        if templateCell == nil {
            templateCell = dequeueReusableCell(withIdentifier: reuseIdentifier)
            assert(templateCell != nil, "Cell must be registered to table view for identifier - \(reuseIdentifier)")
            templateCell?.fd_isTemplateLayoutCell = true
            templateCell?.contentView.translatesAutoresizingMaskIntoConstraints = false
            templateCellsByIdentifiers?[reuseIdentifier] = templateCell
            fd_debugLog("layout cell created - \(reuseIdentifier)")
        }

        return templateCell!
    }

    /// Returns height of cell of type specifed by a reuse identifier and configured
    /// by the configuration block.
    ///
    /// The cell would be layed out on a fixed-width, vertically expanding basis with
    /// respect to its dynamic content, using auto layout. Thus, it is imperative that
    /// the cell was set up to be self-satisfied, i.e. its content always determines
    /// its height given the width is equal to the tableview's.
    ///
    /// @param identifier A string identifier for retrieving and maintaining template
    ///        cells with system's "-dequeueReusableCellWithIdentifier:" call.
    /// @param configuration An optional block for configuring and providing content
    ///        to the template cell. The configuration should be minimal for scrolling
    ///        performance yet sufficient for calculating cell's height.
    ///
    public func fd_heightForCell(with identifier: String, configuration: ((UITableViewCell) -> Void)?) -> CGFloat {
        let templateLayoutCell = fd_templateCell(for: identifier)

        // Manually calls to ensure consistent behavior with actual cells. (that are displayed on screen)
        templateLayoutCell.prepareForReuse()

        if let configuration = configuration {
            configuration(templateLayoutCell)
        }

        return fd_systemFittingHeightForConfiguratedCell(templateLayoutCell)
    }

    /// This method does what "-fd_heightForCellWithIdentifier:configuration" does, and
    /// calculated height will be cached by its index path, returns a cached height
    /// when needed. Therefore lots of extra height calculations could be saved.
    ///
    /// No need to worry about invalidating cached heights when data source changes, it
    /// will be done automatically when you call "-reloadData" or any method that triggers
    /// UITableView's reloading.
    ///
    /// @param indexPath where this cell's height cache belongs.
    ///
    public func fd_heightForCell(with identifier: String, cacheBy indexPath: IndexPath, configuration: ((UITableViewCell) -> Void)?) -> CGFloat {
        // Hit cache
        if fd_indexPathHeightCache.existsHeight(at: indexPath) {
            let cachedHeight = fd_indexPathHeightCache.height(for: indexPath)
            fd_debugLog("hit cache by index path\(indexPath) - \(cachedHeight)")
            return cachedHeight
        }

        let height = fd_heightForCell(with: identifier, configuration: configuration)
        fd_indexPathHeightCache.cache(height: height, by: indexPath)
        fd_debugLog("cached by index path\(indexPath) - \(height)")

        return height
    }

    /// This method caches height by your model entity's identifier.
    /// If your model's changed, call "-invalidateHeightForKey:(id <NSCopying>)key" to
    /// invalidate cache and re-calculate, it's much cheaper and effective than "cacheByIndexPath".
    ///
    /// @param key model entity's identifier whose data configures a cell.
    ///
    public func fd_heightForCell(with identifier: String, cacheByKey key: String, configuration: ((UITableViewCell) -> Void)?) -> CGFloat {
        // Hit cache
        if fd_keyedHeightCache.existsHeight(for: key) {
            let cachedHeight = fd_keyedHeightCache.height(for: key)
            fd_debugLog("hit cache by key[\(key)] -\(cachedHeight)")
            return cachedHeight
        }

        let height = fd_heightForCell(with: identifier, configuration: configuration)
        fd_keyedHeightCache.cache(height, by: key)
        fd_debugLog("cached by key[\(key)] - \(height)")
        return height
    }

    // MARK: - FDTemplateLayoutHeaderFooterView

    public func fd_templateHeaderFooterView(for reuseIdentifier: String) -> UITableViewHeaderFooterView {
        assert(!reuseIdentifier.isEmpty, "Expect a valid identifier - \(reuseIdentifier)")

        var templateHeaderFooterViews: [String: UITableViewHeaderFooterView]? = objc_getAssociatedObject(self, &Keys.fd_heightForHeaderFooterView) as? [String: UITableViewHeaderFooterView]
        if templateHeaderFooterViews == nil {
            templateHeaderFooterViews = [:]
            objc_setAssociatedObject(self, &Keys.fd_heightForHeaderFooterView, templateHeaderFooterViews, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        var templateHeaderFooterView = templateHeaderFooterViews![reuseIdentifier]

        if templateHeaderFooterView == nil {
            templateHeaderFooterView = dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier)
            assert(templateHeaderFooterView != nil, "HeaderFooterView must be registered to table view for identifier - \(reuseIdentifier)")

            templateHeaderFooterView?.contentView.translatesAutoresizingMaskIntoConstraints = false
            templateHeaderFooterViews?[reuseIdentifier] = templateHeaderFooterView
            fd_debugLog("layout header footer view created - \(reuseIdentifier)")
        }

        return templateHeaderFooterView!
    }

    /// Returns header or footer view's height that registered in table view with reuse identifier.
    ///
    /// Use it after calling "-[UITableView registerNib/Class:forHeaderFooterViewReuseIdentifier]",
    /// same with "-fd_heightForCellWithIdentifier:configuration:", it will call "-sizeThatFits:" for
    /// subclass of UITableViewHeaderFooterView which is not using Auto Layout.
    ///
    public func fd_heightForHeaderFooterView(with identifier: String, configuration _: ((UIView) -> Void)?) -> CGFloat {
        let templateHeaderFooterView = fd_templateHeaderFooterView(for: identifier)

        let widthFenceConstraint = NSLayoutConstraint(item: templateHeaderFooterView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: frame.width)
        templateHeaderFooterView.addConstraint(widthFenceConstraint)
        var fittingHeight = templateHeaderFooterView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        templateHeaderFooterView.removeConstraint(widthFenceConstraint)
        if fittingHeight == 0 {
            fittingHeight = templateHeaderFooterView.sizeThatFits(CGSize(width: frame.width, height: 0)).height
        }

        return fittingHeight
    }
}

extension UITableViewCell {

    private struct Keys {
        static var isTemplateLayoutCell = "isTemplateLayoutCell"
        static var enforceFrameLayout = "enforceFrameLayout"
    }

    // MARK: - FDTemplateLayoutCell

    /// Indicate this is a template layout cell for calculation only.
    /// You may need this when there are non-UI side effects when configure a cell.
    /// Like:
    ///   - (void)configureCell:(FooCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ///       cell.entity = [self entityAtIndexPath:indexPath];
    ///       if (!cell.fd_isTemplateLayoutCell) {
    ///           [self notifySomething]; // non-UI side effects
    ///       }
    ///   }
    ///

    public var fd_isTemplateLayoutCell: Bool {
        set {
            objc_setAssociatedObject(self, &Keys.isTemplateLayoutCell, newValue, .OBJC_ASSOCIATION_RETAIN)
        }

        get {
            return objc_getAssociatedObject(self, &Keys.isTemplateLayoutCell) as? Bool ?? false
        }
    }

    /// Enable to enforce this template layout cell to use "frame layout" rather than "auto layout",
    /// and will ask cell's height by calling "-sizeThatFits:", so you must override this method.
    /// Use this property only when you want to manually control this template layout cell's height
    /// calculation mode, default to NO.
    ///
    public var fd_usingFrameLayout: Bool {
        set {
            objc_setAssociatedObject(self, &Keys.enforceFrameLayout, newValue, .OBJC_ASSOCIATION_RETAIN)
        }

        get {
            return objc_getAssociatedObject(self, &Keys.enforceFrameLayout) as? Bool ?? true
        }
    }
}
