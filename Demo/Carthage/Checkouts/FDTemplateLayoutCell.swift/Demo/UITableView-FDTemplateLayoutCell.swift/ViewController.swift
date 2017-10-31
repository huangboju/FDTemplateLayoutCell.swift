//
//  ViewController.swift
//  TableViewDynamicHeight
//
//  Created by 伯驹 黄 on 2017/2/21.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import SwiftyJSON
import FDTemplateLayoutCell

extension UISegmentedControl {
    var selectedTitle: String? {
        return titleForSegment(at: selectedSegmentIndex)
    }
}

class ViewController: UITableViewController {
    
    var feedEntitySections: [[FDFeedEntity]] = []
    
    var prototypeEntitiesFromJSON: [FDFeedEntity] = []
    
    private lazy var segmentConrol: UISegmentedControl = {
        let segmentConrol = UISegmentedControl(items: ["No cache", "IndexPath cache", "Key cache"])
        segmentConrol.selectedSegmentIndex = 1
        segmentConrol.addTarget(self, action: #selector(selectedChange), for: .valueChanged)
        return segmentConrol
    }()
    
    private lazy var actionControl: UISegmentedControl = {
        let actionControl = UISegmentedControl(items: ["insertRow", "insertSection", "deleteSection"])
        actionControl.addTarget(self, action: #selector(performAction), for: .valueChanged)
        actionControl.isMomentary = true
        actionControl.center.x = self.view.center.x
        actionControl.frame.origin.y = 8
        return actionControl
    }()
    
    private lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.tableView.frame.height - 44, width: self.tableView.frame.width, height: 44))
        return toolBar
    }()
    
    func selectedChange() {
        tableView.reloadData()
    }
    
    func performAction() {
        perform(Selector(actionControl.selectedTitle ?? ""), with: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red
        navigationItem.titleView = segmentConrol
        
        tableView.register(FDFeedCell.self, forCellReuseIdentifier: "cell")
        
        buildTestData {
            self.feedEntitySections.append(self.prototypeEntitiesFromJSON)
            self.tableView.reloadData()
        }
        
        UIApplication.shared.keyWindow?.addSubview(toolBar)
        toolBar.addSubview(actionControl)
        
        tableView.fd_debugLogEnabled = true
    }
    
    func buildTestData(then: @escaping() -> ()) {
        // Simulate an async request
        DispatchQueue.global().async {
            
            // Data from `data.json`
            
            guard let dataFilePath = Bundle.main.path(forResource: "data", ofType: "json") else { return }
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: dataFilePath))
                let rootDict = JSON(data).dictionaryValue
                
                guard let feedDicts = rootDict["feed"]?.arrayValue else { return }
                
                // Convert to `FDFeedEntity`
                self.prototypeEntitiesFromJSON = feedDicts.map { FDFeedEntity(dict: $0.dictionaryValue) }
            } catch let error {
                print(error)
            }
            
            DispatchQueue.main.async {
                then()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return feedEntitySections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedEntitySections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, at indexPath: IndexPath) {
        let cell = cell as? FDFeedCell
        cell?.fd_usingFrameLayout = true // Enable to use "-sizeThatFits:"
        if indexPath.row % 2 == 0 {
            cell?.accessoryType = .disclosureIndicator
        } else {
            cell?.accessoryType = .checkmark
        }
        cell?.entity = feedEntitySections[indexPath.section][indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch segmentConrol.selectedTitle ?? "" {
        case "No cache":
            return tableView.fd_heightForCell(with: "cell") { (cell) in
                self.configure(cell: cell, at: indexPath)
            }
        case "IndexPath cache":
            return tableView.fd_heightForCell(with: "cell", cacheBy: indexPath) { (cell) in
                self.configure(cell: cell, at: indexPath)
            }
        case "Key cache":
            let entity = feedEntitySections[indexPath.section][indexPath.row]
            return tableView.fd_heightForCell(with: "cell", cacheByKey: entity.identifier ?? "") { (cell) in
                self.configure(cell: cell, at: indexPath)
            }
        default:
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    var randomEntity: FDFeedEntity {
        let randomNumber = Int(arc4random_uniform(UInt32(prototypeEntitiesFromJSON.count)))
        let randomEntity = prototypeEntitiesFromJSON[randomNumber]
        return randomEntity
    }
    
    func insertRow() {
        if feedEntitySections.isEmpty {
            insertSection()
        } else {
            feedEntitySections[0].insert(randomEntity, at: 0)
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
    
    func insertSection() {
        feedEntitySections.insert([randomEntity], at: 0)
        tableView.insertSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func deleteSection() {
        if !feedEntitySections.isEmpty {
            feedEntitySections.remove(at: 0)
            tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
