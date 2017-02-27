# It is translation of the [UITableView-FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell) by Swift

# Overview
It can be through the Auto layout and Frame layout way to obtain the height of the cell, and you can use the same key or indexpath way to cache the height of the cell

![](https://github.com/huangboju/FDTemplateLayoutCell.swift/blob/master/2017-02-24%2014_47_18.gif)

# Installation
* CocoaPods
```
pod 'FDTemplateLayoutCell'
```

* Carthage

```
github "huangboju/FDTemplateLayoutCell.swift"
```


# Usage
* No cache
```swift
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.fd_heightForCell(with: "cell") { (cell) in
        // Configure this cell with data, same as what you've done in "-tableView:cellForRowAtIndexPath:"
        // Like:
        //    cell.data = datas[indexPath.row]
        }
  }
```

* IndexPath cache
```swift
override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.fd_heightForCell(with: "cell", cacheBy: indexPath) { (cell) in
        // Configure this cell with data, same as what you've done in "-tableView:cellForRowAtIndexPath:"
        // Like:
        //    cell.data = datas[indexPath.row]
        }
  }
```

* Key cache
```swift
override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.fd_heightForCell(with: "cell", cacheByKey: entity.identifier ?? "") { (cell) in
        // Configure this cell with data, same as what you've done in "-tableView:cellForRowAtIndexPath:"
        // Like:
        //    cell.data = datas[indexPath.row]
        }
  }
```

# Frame layout mode

`FDTemplateLayoutCell.swift` offers 2 modes for asking cell's height.

* Auto layout mode using "-systemLayoutSizeFittingSize:"
* Frame layout mode using "-sizeThatFits:"

**You can use this API change mode for asking cell's height,default is true, because use "frame layout" rather than "auto layout".**
```swift
cell.fd_usingFrameLayout = false
```
**And if you're using frame layout mode, you must override func sizeThatFits(_ size: CGSize) -> CGSize in your customized cell and return content view's height (separator excluded)**
```swift
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: h1 + h2 + ... + hn)
    }
```

# Debug log
Debug log helps to debug or inspect what is this "FDTemplateLayoutCell.swift" extention doing, turning on to print logs when "calculating", "precaching" or "hitting cache".Default to "false", log by "print".

```swift
tableView.fd_debugLogEnabled = true
```
**It will print like this:**
```
** FDTemplateLayoutCell ** hit cache by index path[0, 17] - 123.5
** FDTemplateLayoutCell ** hit cache by index path[0, 18] - 237.5
** FDTemplateLayoutCell ** hit cache by index path[0, 18] - 237.5
** FDTemplateLayoutCell ** hit cache by index path[0, 19] - 159.5
** FDTemplateLayoutCell ** hit cache by index path[0, 19] - 159.5
** FDTemplateLayoutCell ** hit cache by index path[0, 20] - 262.0
** FDTemplateLayoutCell ** hit cache by index path[0, 20] - 262.0
** FDTemplateLayoutCell ** hit cache by index path[0, 21] - 288.0
** FDTemplateLayoutCell ** hit cache by index path[0, 21] - 288.0
** FDTemplateLayoutCell ** hit cache by index path[0, 22] - 299.0
** FDTemplateLayoutCell ** hit cache by index path[0, 22] - 299.0
** FDTemplateLayoutCell ** hit cache by index path[0, 23] - 176.5
```

## About self-satisfied cell

a fully **self-satisfied** cell is constrainted by auto layout and each edge("top", "left", "bottom", "right") has at least one layout constraint against it. It's the same concept introduced as "self-sizing cell" in iOS8 using auto layout.

A bad one :( - missing right and bottom
![non-self-satisfied](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell/blob/master/Sceenshots/screenshot0.png)   

A good one :)  
![self-satisfied](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell/blob/master/Sceenshots/screenshot1.png)   

## Notes

A template layout cell is created by `dequeueReusableCell(withIdentifier: <#T##String#>)` method, it means that you MUST have registered this cell reuse identifier by one of:  

- A prototype cell of UITableView in storyboard.
- Use `register(UINib, forCellReuseIdentifier: String)` 
- Use `register(AnyClass, forCellReuseIdentifier: String)`

# Contact
If you find an issue, just open a ticket. Pull requests are warmly welcome as well.

### License

FDTemplateLayoutCell.swift is released under the MIT license. See LICENSE for details.

