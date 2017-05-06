//
//  ARPieChart.swift
//  ARPieChartDemo
//
//  Created by Yufei Tang on 2015-02-04.
//  Copyright (c) 2015 Yufei Tang. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import QuartzCore

/**
*  MARK: ARPieChart datasource
*/
public protocol ARPieChartDataSource: class {
    
    func numberOfSlicesInPieChart(_ pieChart: ARPieChart) -> Int
    
    func pieChart(_ pieChart: ARPieChart, valueForSliceAtIndex index: Int) -> CGFloat
    
    func pieChart(_ pieChart: ARPieChart, colorForSliceAtIndex index: Int) -> UIColor
    
    func pieChart(_ pieChart: ARPieChart, descriptionForSliceAtIndex index: Int) -> String
}

/**
*  MARK: ARPieChart delegate
*/
public protocol ARPieChartDelegate: class {
    
    func pieChart(_ pieChart: ARPieChart, itemSelectedAtIndex index: Int)
    
    func pieChart(_ pieChart: ARPieChart, itemDeselectedAtIndex index: Int)
}

/**
*  MARK: ARPieChart
*/
open class ARPieChart: UIView {
    
    /// Delegate
    open weak var delegate: ARPieChartDelegate?
    
    /// DataSource
    open weak var dataSource: ARPieChartDataSource?
    
    /// Pie chart start angle, should be in [-PI, PI)
    open var startAngle: CGFloat = -(.pi / 2) {
        didSet {
            while startAngle >= CGFloat(Float.pi) {
                startAngle -= CGFloat(Float.pi * 2)
            }
            while startAngle < -CGFloat(Float.pi) {
                startAngle += CGFloat(Float.pi * 2)
            }
        }
    }
    
    /// Outer radius
    open var outerRadius: CGFloat = 0.0
    
    /// Inner radius
    open var innerRadius: CGFloat = 0.0
    
    /// Offset of selected pie layer
    open var selectedPieOffset: CGFloat = 0.0
    
    /// Font of layer's description text
    open var labelFont: UIFont = UIFont.systemFont(ofSize: 10)
    
    open var showDescriptionText: Bool = false
    
    open var animationDuration: Double = 1.0
    
    var contentView: UIView!
    
    var pieCenter: CGPoint {
        return CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
    }
    
    var endAngle: CGFloat {
        return CGFloat(Float.pi * 2) + startAngle
    }
    
    var strokeWidth: CGFloat {
        return outerRadius - innerRadius
    }
    
    var strokeRadius: CGFloat {
        return (outerRadius + innerRadius) / 2
    }
    
    var selectedLayerIndex: Int = -1
    
    var total: CGFloat = 0.0
    
    var refresh: Bool = true
    
    /**
        MARK: Functions
    */
    
    func setDefaultValues() {
        contentView = UIView(frame: self.bounds)
        addSubview(contentView)
        outerRadius = min(self.bounds.width, self.bounds.height) / 3.0
        innerRadius = outerRadius / 3.0
        selectedPieOffset = innerRadius / 2.0
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
    
    /**
        Stroke chart / update current chart
    */
    open func reloadData() {
        
        let parentLayer: CALayer = contentView.layer
        
        /// Mutable copy of current pie layers on display
        var currentLayers: NSMutableArray!
        if parentLayer.sublayers == nil {
            currentLayers = NSMutableArray()
        } else {
            currentLayers = NSMutableArray(array: parentLayer.sublayers!)
        }
        
        var itemCount: Int = dataSource?.numberOfSlicesInPieChart(self) ?? 0
        
        total = 0
        for index in 0 ..< itemCount {
            let value = dataSource?.pieChart(self, valueForSliceAtIndex: index) ?? 0
            total += value
        }
        
        var diff = itemCount - currentLayers.count
        
        let layersToRemove: NSMutableArray = NSMutableArray()
        
        /**
        *  Begin CATransaction, disable user interaction
        */
        contentView.isUserInteractionEnabled = false
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock { () -> Void in
            /**
            *  Remove unnecessary layers
            */
            for obj in layersToRemove {
                let layerToRemove: CAShapeLayer = obj as! CAShapeLayer
                layerToRemove.removeFromSuperlayer()
            }
            layersToRemove.removeAllObjects()
            
            /**
            *  Re-enable user interaction
            */
            self.contentView.isUserInteractionEnabled = true
        }
        
        /**
        *  Deselect layer
        */
        if selectedLayerIndex != -1 {
            deselectLayerAtIndex(selectedLayerIndex)
        }
        
        /**
        *  Check if datasource is valid, otherwise remove all layers from content view and show placeholder text, if any
        */
        if itemCount == 0 || total <= 0 {
            itemCount = 0
            diff = -currentLayers.count
        }
        
        /**
        *  If there are more new items, add new layers correpsondingly in the beginning, otherwise, remove extra layers from the end
        */
        if diff > 0 {
            while diff != 0 {
                let newLayer = createPieLayer()
                parentLayer.insertSublayer(newLayer, at: 0)
                currentLayers.insert(newLayer, at: 0)
                diff -= 1
            }
        } else if diff < 0 {
            while diff != 0 {
                let layerToRemove = currentLayers.lastObject as! CAShapeLayer
                currentLayers.removeLastObject()
                layersToRemove.add(layerToRemove)
                updateLayer(layerToRemove, atIndex: -1, strokeStart: 1, strokeEnd: 1)
                diff += 1
            }
        }
        
        var toStrokeStart: CGFloat = 0.0
        var toStrokeEnd: CGFloat = 0.0
        var currentTotal: CGFloat = 0.0
        
        /// Update current layers with corresponding item
        for index: Int in 0 ..< itemCount {
            
            let currentValue: CGFloat = dataSource?.pieChart(self, valueForSliceAtIndex: index) ?? 0
            
            let layer = currentLayers[index] as! CAShapeLayer
            
            toStrokeStart = currentTotal / total
            toStrokeEnd = (currentTotal + abs(currentValue)) / total
            
            updateLayer(layer, atIndex: index, strokeStart: toStrokeStart, strokeEnd: toStrokeEnd)
            
            currentTotal += currentValue
        }
        CATransaction.commit()
    }
    
    func createPieLayer() -> CAShapeLayer {
        let pieLayer = CAShapeLayer()
        
        pieLayer.fillColor = UIColor.clear.cgColor
        pieLayer.borderColor = UIColor.clear.cgColor
        pieLayer.strokeStart = 0
        pieLayer.strokeEnd = 0

        return pieLayer
    }
    
    func createArcAnimationForLayer(_ layer: CAShapeLayer, key: String, toValue: AnyObject!) {
        
        let arcAnimation: CABasicAnimation = CABasicAnimation(keyPath: key);
        
        var fromValue: AnyObject!
        if key == "strokeStart" || key == "strokeEnd" {
            fromValue = NSNumber(value: 0)
        }
        
        if layer.presentation() != nil {
            fromValue = layer.presentation()!.value(forKey: key) as AnyObject
        }
        
        arcAnimation.fromValue = fromValue
        arcAnimation.toValue = toValue
        arcAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        layer.add(arcAnimation, forKey: key)
        layer.setValue(toValue, forKey: key)
    }
    
    func updateLayer(_ layer: CAShapeLayer, atIndex index: Int, strokeStart: CGFloat, strokeEnd: CGFloat) {
        
        /// Add animation to stroke path (in case radius changes)
        let path = UIBezierPath(arcCenter: pieCenter, radius: strokeRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        createArcAnimationForLayer(layer, key: "path", toValue: path.cgPath)
        
        layer.lineWidth = strokeWidth
        
        /**
        *  Assign stroke color by data source
        */
        if index >= 0 {
            layer.strokeColor = dataSource?.pieChart(self, colorForSliceAtIndex: index).cgColor
        }
        
        createArcAnimationForLayer(layer, key: "strokeStart", toValue: strokeStart as AnyObject!)
        createArcAnimationForLayer(layer, key: "strokeEnd", toValue: strokeEnd as AnyObject!)
        
        /// Custom text layer for description
        var textLayer: CATextLayer!
        
        if layer.sublayers != nil {
            textLayer = layer.sublayers!.first as! CATextLayer
        } else {
            textLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.isWrapped = true
            textLayer.alignmentMode = kCAAlignmentCenter
            layer.addSublayer(textLayer)
        }
        
        textLayer.font = CGFont(labelFont.fontName as NSString)
        textLayer.fontSize = labelFont.pointSize
        textLayer.string = ""
        
        if showDescriptionText && index >= 0 {
            textLayer.string = dataSource?.pieChart(self, descriptionForSliceAtIndex: index)
        }
        
        let size: CGSize = (textLayer.string! as AnyObject).size(attributes: [NSFontAttributeName: labelFont])
        textLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        if (strokeEnd - strokeStart) * CGFloat(Float.pi) * 2 * strokeRadius < max(size.width, size.height) {
            textLayer.string = ""
        }
        
        let midAngle: CGFloat = (strokeStart + strokeEnd) * CGFloat(Float.pi) + startAngle
        
        textLayer.position = CGPoint(x: pieCenter.x + strokeRadius * cos(midAngle), y: pieCenter.y + strokeRadius * sin(midAngle))
    }
    
    open func selectLayerAtIndex(_ index: Int) {
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil && index < currentPieLayers!.count {
            let layerToSelect = currentPieLayers![index] as! CAShapeLayer
            let currentPosition = layerToSelect.position
            let midAngle = (layerToSelect.strokeEnd + layerToSelect.strokeStart) * CGFloat(Float.pi) + startAngle
            let newPosition = CGPoint(x: currentPosition.x + selectedPieOffset * cos(midAngle), y: currentPosition.y + selectedPieOffset * sin(midAngle))
            layerToSelect.position = newPosition
            selectedLayerIndex = index
        }
    }
    
    open func deselectLayerAtIndex(_ index: Int) {
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil && index < currentPieLayers!.count {
            let layerToSelect = currentPieLayers![index] as! CAShapeLayer
            layerToSelect.position = CGPoint(x: 0, y: 0)
            layerToSelect.zPosition = 0
            selectedLayerIndex = -1
        }
    }
    
    func getSelectedLayerIndexOnTouch(_ touch: UITouch) -> Int {
        
        var selectedIndex = -1
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil {
            
            let point = touch.location(in: contentView)
            
            for i in 0 ..< currentPieLayers!.count {
                
                let pieLayer = currentPieLayers![i] as! CAShapeLayer
                
                let pieStartAngle = pieLayer.strokeStart * CGFloat(Float.pi * 2)
                let pieEndAngle = pieLayer.strokeEnd * CGFloat(Float.pi * 2)
                
                var angle = atan2(point.y - pieCenter.y, point.x - pieCenter.x) - startAngle
                if angle < 0 {
                    angle += CGFloat(Float.pi * 2)
                }
                
                let distance = sqrt(pow(point.x - pieCenter.x, 2) + pow(point.y - pieCenter.y, 2))
                
                if angle > pieStartAngle && angle < pieEndAngle && distance < outerRadius && distance > innerRadius
                {
                    selectedIndex = i
                }
            }
        }
        
        return selectedIndex
    }
    
    func handleLayerSelection(_ fromIndex: Int, toIndex: Int) {
        if fromIndex == -1 && toIndex != -1 {
            selectLayerAtIndex(toIndex)
            delegate?.pieChart(self, itemSelectedAtIndex: toIndex)
        } else if fromIndex != -1 {
            deselectLayerAtIndex(fromIndex)
            delegate?.pieChart(self, itemDeselectedAtIndex: fromIndex)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let anyTouch: UITouch = touches.first {
            let selectedIndex = getSelectedLayerIndexOnTouch(anyTouch)
            handleLayerSelection(self.selectedLayerIndex, toIndex: selectedIndex)
        }
    }
    
    /**
        Initializers
    */
    override public init(frame: CGRect) {
        super.init(frame:frame)
        setDefaultValues()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setDefaultValues()
    }
    
    

}
