//
//  UITableView+FDIndexPathHeightCache.swift
//  TableViewDynamicHeight
//
//  Created by 伯驹 黄 on 2017/2/21.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

extension UITableView {

    // MARK: - FDKeyedHeightCache and FDIndexPathHeightCache

    private struct Keys {
        static var keyedHeightCache = "keyedHeightCache"
        static var indexPathHeightCache = "indexPathHeightCache"
    }

    var fd_indexPathHeightCache: FDIndexPathHeightCache {
        var cache = objc_getAssociatedObject(self, &Keys.indexPathHeightCache) as? FDIndexPathHeightCache
        if cache == nil {
            cache = FDIndexPathHeightCache()
            objc_setAssociatedObject(self, &Keys.indexPathHeightCache, cache, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return cache!
    }

    var fd_keyedHeightCache: FDKeyedHeightCache {
        var cache = objc_getAssociatedObject(self, &Keys.keyedHeightCache) as? FDKeyedHeightCache
        if cache == nil {
            cache = FDKeyedHeightCache()
            objc_setAssociatedObject(self, &Keys.keyedHeightCache, cache, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return cache!
    }

    // MARK: - FDIndexPathHeightCacheInvalidation

    func fd_reloadDataWithoutInvalidateIndexPathHeightCache() {
        fd_reloadData()
    }

    static let _onceToken = UUID().uuidString

    func fd_reloadData() {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                heightsBySection.removeAll()
            })
        }
        fd_reloadData()
        //    FDPrimaryCall([self fd_reloadData];)
    }

    func fd_insertSections(_ sections: IndexSet, with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            for section in sections {
                fd_indexPathHeightCache.buildSectionsIfNeeded(section)
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection.insert([], at: section)
                })
            }
        }
        fd_insertSections(sections, with: rowAnimation)
    }

    func fd_deleteSections(_ sections: IndexSet, with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            for section in sections {
                fd_indexPathHeightCache.buildSectionsIfNeeded(section)
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection.remove(at: section)
                })
            }
            fd_deleteSections(sections, with: rowAnimation)
        }
    }

    func fd_reloadSections(_ sections: IndexSet, with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            for section in sections {
                fd_indexPathHeightCache.buildSectionsIfNeeded(section)
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection[section].removeAll()
                })
            }
        }
        fd_reloadSections(sections, with: rowAnimation)
    }

    func fd_moveSection(_ section: Int, toSection newSection: Int) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.buildSectionsIfNeeded(section)
            fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                heightsBySection.swapAt(section, newSection)
            })
        }
        fd_moveSection(section, toSection: newSection)
    }

    func fd_insertRows(at indexPaths: [IndexPath], with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.buildCachesAtIndexPathsIfNeeded(indexPaths)
            for indexPath in indexPaths {
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection[indexPath.section].insert(-1, at: indexPath.row)
                })
            }
        }
        fd_insertRows(at: indexPaths, with: rowAnimation)
    }

    func fd_deleteRows(at indexPaths: [IndexPath], with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.buildCachesAtIndexPathsIfNeeded(indexPaths)

            var mutableIndexSetsToRemove: [Int: IndexSet] = [:]

            for indexPath in indexPaths {
                var mutableIndexSet = mutableIndexSetsToRemove[indexPath.section]
                if mutableIndexSet == nil {
                    mutableIndexSet = IndexSet()
                    mutableIndexSetsToRemove[indexPath.section] = mutableIndexSet
                }
                mutableIndexSet?.insert(indexPath.row)
            }

            for (key, indexSet) in mutableIndexSetsToRemove {
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection[key].remove(at: indexSet)
                })
            }

            fd_deleteRows(at: indexPaths, with: rowAnimation)
            //    FDPrimaryCall([self fd_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];);
        }
    }

    func fd_reloadRows(at indexPaths: [IndexPath], with rowAnimation: UITableViewRowAnimation) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.buildCachesAtIndexPathsIfNeeded(indexPaths)
            for indexPath in indexPaths {
                fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                    heightsBySection[indexPath.section][indexPath.row] = -1
                })
            }
        }
        fd_reloadRows(at: indexPaths, with: rowAnimation)
    }

    func fd_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        if fd_indexPathHeightCache.automaticallyInvalidateEnabled {
            fd_indexPathHeightCache.buildCachesAtIndexPathsIfNeeded([indexPath, newIndexPath])
            fd_indexPathHeightCache.enumerateAllOrientations(using: { heightsBySection in
                var sourceRows = heightsBySection[indexPath.section]
                var destinationRows = heightsBySection[newIndexPath.section]
                let sourceValue = sourceRows[indexPath.row]
                let destinationValue = destinationRows[newIndexPath.row]
                sourceRows[indexPath.row] = destinationValue
                destinationRows[newIndexPath.row] = sourceValue
            })
        }
        fd_moveRow(at: indexPath, to: newIndexPath)
    }
}

extension Array {
    // Code taken from http://stackoverflow.com/a/26174259/1975001
    // Further adapted to work with Swift 3
    /// Removes objects at indexes that are in the specified `NSIndexSet`.
    /// - parameter indexes: the index set containing the indexes of objects that will be removed
    public mutating func remove(at indexes: IndexSet) {
        for i in indexes.reversed() {
            remove(at: i)
        }
    }

    subscript(safe index: Int) -> Element {
        get {
            return self[index]
        }
        set {
            insert(newValue, at: index)
        }
    }
}

extension DispatchQueue {

    private static var _onceTracker = [String]()

    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
