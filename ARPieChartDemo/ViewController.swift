//
//  ViewController.swift
//  ARPieChartDemo
//
//  Created by Yufei Tang on 2015-02-04.
//  Copyright (c) 2015 Yufei Tang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ARPieChartDelegate, ARPieChartDataSource {
    
    
    @IBOutlet weak var pieChart: ARPieChart!
    @IBOutlet weak var selectionLabel: UILabel!
    @IBOutlet weak var selectionOffsetSlider: UISlider!
    @IBOutlet weak var outerRadiusSlider: UISlider!
    @IBOutlet weak var innerRadiusSlider: UISlider!
    
    var dataItems: NSMutableArray = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        pieChart.delegate = self
        pieChart.dataSource = self
        pieChart.showDescriptionText = true
        
        // Random Default Value
        let defaultItemCount = randomInteger(1, upper: 10)
        for _ in 1...defaultItemCount {
            dataItems.add(randomItem())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let maxRadius = min(pieChart.frame.width, pieChart.frame.height) / 2
        
        innerRadiusSlider.minimumValue = 0
        outerRadiusSlider.minimumValue = 0
        selectionOffsetSlider.minimumValue = 0
        innerRadiusSlider.maximumValue = Float(maxRadius)
        outerRadiusSlider.maximumValue = Float(maxRadius * 0.8)
        selectionOffsetSlider.maximumValue = Float(maxRadius / 2)
        innerRadiusSlider.value = Float(pieChart.innerRadius)
        outerRadiusSlider.value = Float(pieChart.outerRadius)
        selectionOffsetSlider.value = Float(pieChart.selectedPieOffset)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pieChart.reloadData()
    }

    
    @IBAction func sliderChangedValue(_ sender: AnyObject) {
        updatePieChart()
    }
    
    
    @IBAction func deleteItem(_ sender: AnyObject) {
        
        let indexToRemove: Int = randomInteger(0, upper: dataItems.count - 1)
        
        print("Item removed at index \(indexToRemove)")
        
        dataItems.removeObject(at: indexToRemove)
        pieChart.reloadData()
    }
    @IBAction func addItem(_ sender: AnyObject) {
        
        let indexToAdd: Int = randomInteger(0, upper: dataItems.count - 1)
        
        print("Item added at index \(indexToAdd)")
        
        dataItems.insert(randomItem(), at: indexToAdd)
        pieChart.reloadData()
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        updatePieChart()
    }
    
    fileprivate func updatePieChart() {
        pieChart.innerRadius = CGFloat(innerRadiusSlider.value)
        pieChart.outerRadius = CGFloat(outerRadiusSlider.value)
        pieChart.selectedPieOffset = CGFloat(selectionOffsetSlider.value)
        pieChart.reloadData()
    }
    
    func randomColor() -> UIColor {
        let randomR: CGFloat = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let randomG: CGFloat = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let randomB: CGFloat = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        return UIColor(red: randomR, green: randomG, blue: randomB, alpha: 1)
    }
    
    func randomInteger(_ lower: Int, upper: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upper - lower + 1))) + lower
    }
    
    func randomItem() -> PieChartItem {
        let value = CGFloat(randomInteger(1, upper: 10))
        let color = randomColor()
        let description = "\(value)"
        return PieChartItem(value: value, color: color, description: description)
    }
    
    /**
    *  MARK: ARPieChartDelegate
    */
    func pieChart(_ pieChart: ARPieChart, itemSelectedAtIndex index: Int) {
        let itemSelected: PieChartItem = dataItems[index] as! PieChartItem
        selectionLabel.text = "Value: \(itemSelected.value)"
        selectionLabel.textColor = itemSelected.color
    }
    
    func pieChart(_ pieChart: ARPieChart, itemDeselectedAtIndex index: Int) {
        selectionLabel.text = "No Selection"
        selectionLabel.textColor = UIColor.black
    }
    
    
    /**
    *   MARK: ARPieChartDataSource
    */
    func numberOfSlicesInPieChart(_ pieChart: ARPieChart) -> Int {
        return dataItems.count
    }
    
    func pieChart(_ pieChart: ARPieChart, valueForSliceAtIndex index: Int) -> CGFloat {
        let item: PieChartItem = dataItems[index] as! PieChartItem
        return item.value
    }
    
    func pieChart(_ pieChart: ARPieChart, colorForSliceAtIndex index: Int) -> UIColor {
        let item: PieChartItem = dataItems[index] as! PieChartItem
        return item.color
    }
    
    func pieChart(_ pieChart: ARPieChart, descriptionForSliceAtIndex index: Int) -> String {
        let item: PieChartItem = dataItems[index] as! PieChartItem
        return item.description ?? ""
    }
}

/**
*  MARK: Pie chart data item
*/
open class PieChartItem {
    
    /// Data value
    open var value: CGFloat = 0.0
    
    /// Color displayed on chart
    open var color: UIColor = UIColor.black
    
    /// Description text
    open var description: String?
    
    public init(value: CGFloat, color: UIColor, description: String?) {
        self.value = value
        self.color = color
        self.description = description
    }
}

