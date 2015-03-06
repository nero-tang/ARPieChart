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
public protocol ARPieChartDataSource {
    
    func numberOfSlicesInPieChart(pieChart: ARPieChart) -> Int
    
    func pieChart(pieChart: ARPieChart, valueForSliceAtIndex index: Int) -> CGFloat
    
    func pieChart(pieChart: ARPieChart, colorForSliceAtIndex index: Int) -> UIColor
    
    func pieChart(pieChart: ARPieChart, descriptionForSliceAtIndex index: Int) -> String
}

/**
*  MARK: ARPieChart delegate
*/
public protocol ARPieChartDelegate {
    
    func pieChart(pieChart: ARPieChart, itemSelectedAtIndex index: Int)
    
    func pieChart(pieChart: ARPieChart, itemDeselectedAtIndex index: Int)
}

/**
*  MARK: ARPieChart
*/
public class ARPieChart: UIView {
    
    /// Delegate
    public var delegate: ARPieChartDelegate?
    
    /// DataSource
    public var dataSource: ARPieChartDataSource?
    
    /// Pie chart start angle, should be in [-PI, PI)
    public var startAngle: CGFloat = CGFloat(-M_PI_2) {
        didSet {
            while startAngle >= CGFloat(M_PI) {
                startAngle -= CGFloat(M_PI * 2)
            }
            while startAngle < CGFloat(-M_PI) {
                startAngle += CGFloat(M_PI * 2)
            }
        }
    }
    
    /// Outer radius
    public var outerRadius: CGFloat = 0.0
    
    /// Inner radius
    public var innerRadius: CGFloat = 0.0
    
    /// Offset of selected pie layer
    public var selectedPieOffset: CGFloat = 0.0
    
    /// Font of layer's description text
    public var labelFont: UIFont = UIFont.systemFontOfSize(10)
    
    public var showDescriptionText: Bool = false
    
    public var animationDuration: Double = 1.0
    
    var contentView: UIView!
    
    var pieCenter: CGPoint {
        return CGPointMake(CGRectGetMidX(contentView.bounds), CGRectGetMidY(contentView.bounds))
    }
    
    var endAngle: CGFloat {
        return CGFloat(M_PI * 2) + startAngle
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
    
    /**
        Stroke chart / update current chart
    */
    public func reloadData() {
        
        let parentLayer: CALayer = contentView.layer
        
        /// Mutable copy of current pie layers on display
        var currentLayers: NSMutableArray!
        if parentLayer.sublayers == nil {
            currentLayers = NSMutableArray()
        } else {
            currentLayers = NSMutableArray(array: parentLayer.sublayers)
        }
        
        var itemCount: Int = dataSource?.numberOfSlicesInPieChart(self) ?? 0
        
        total = 0
        for var index = 0; index < itemCount; index++ {
            let value = dataSource?.pieChart(self, valueForSliceAtIndex: index) ?? 0
            total += value
        }
        
        var diff = itemCount - currentLayers.count
        
        var layersToRemove: NSMutableArray = NSMutableArray()
        
        /**
        *  Begin CATransaction, disable user interaction
        */
        contentView.userInteractionEnabled = false
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock { () -> Void in
            /**
            *  Remove unnecessary layers
            */
            for obj in layersToRemove {
                let layerToRemove: CAShapeLayer = obj as CAShapeLayer
                layerToRemove.removeFromSuperlayer()
            }
            layersToRemove.removeAllObjects()
            
            /**
            *  Re-enable user interaction
            */
            self.contentView.userInteractionEnabled = true
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
                parentLayer.insertSublayer(newLayer, atIndex: 0)
                currentLayers.insertObject(newLayer, atIndex: 0)
                diff--
            }
        } else if diff < 0 {
            while diff != 0 {
                let layerToRemove = currentLayers.lastObject as CAShapeLayer
                currentLayers.removeLastObject()
                layersToRemove.addObject(layerToRemove)
                updateLayer(layerToRemove, atIndex: -1, strokeStart: 1, strokeEnd: 1)
                diff++
            }
        }
        
        var toStrokeStart: CGFloat = 0.0
        var toStrokeEnd: CGFloat = 0.0
        var currentTotal: CGFloat = 0.0
        
        /// Update current layers with corresponding item
        for var index: Int = 0; index < itemCount; index++ {
            
            let currentValue: CGFloat = dataSource?.pieChart(self, valueForSliceAtIndex: index) ?? 0
            
            var layer = currentLayers[index] as CAShapeLayer
            
            toStrokeStart = currentTotal / total
            toStrokeEnd = (currentTotal + abs(currentValue)) / total
            
            updateLayer(layer, atIndex: index, strokeStart: toStrokeStart, strokeEnd: toStrokeEnd)
            
            currentTotal += currentValue
        }
        CATransaction.commit()
    }
    
    func createPieLayer() -> CAShapeLayer {
        let pieLayer = CAShapeLayer()
        
        pieLayer.fillColor = UIColor.clearColor().CGColor
        pieLayer.borderColor = UIColor.clearColor().CGColor
        pieLayer.strokeStart = 0
        pieLayer.strokeEnd = 0

        return pieLayer
    }
    
    func createArcAnimationForLayer(layer: CAShapeLayer, key: String, toValue: AnyObject!) {
        
        let arcAnimation: CABasicAnimation = CABasicAnimation(keyPath: key);
        
        var fromValue: AnyObject!
        if key == "strokeStart" || key == "strokeEnd" {
            fromValue = 0
        }
        
        if layer.presentationLayer() != nil {
            fromValue = layer.presentationLayer().valueForKey(key)
        }
        
        arcAnimation.fromValue = fromValue
        arcAnimation.toValue = toValue
        arcAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        layer.addAnimation(arcAnimation, forKey: key)
        layer.setValue(toValue, forKey: key)
    }
    
    func updateLayer(layer: CAShapeLayer, atIndex index: Int, strokeStart: CGFloat, strokeEnd: CGFloat) {
        
        /// Add animation to stroke path (in case radius changes)
        let path = UIBezierPath(arcCenter: pieCenter, radius: strokeRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        createArcAnimationForLayer(layer, key: "path", toValue: path.CGPath)
        
        layer.lineWidth = strokeWidth
        
        /**
        *  Assign stroke color by data source
        */
        if index >= 0 {
            layer.strokeColor = dataSource?.pieChart(self, colorForSliceAtIndex: index).CGColor
        }
        
        createArcAnimationForLayer(layer, key: "strokeStart", toValue: strokeStart)
        createArcAnimationForLayer(layer, key: "strokeEnd", toValue: strokeEnd)
        
        /// Custom text layer for description
        var textLayer: CATextLayer!
        
        if layer.sublayers != nil {
            textLayer = layer.sublayers.first as CATextLayer
        } else {
            textLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.mainScreen().scale
            textLayer.wrapped = true
            textLayer.alignmentMode = kCAAlignmentCenter
            layer.addSublayer(textLayer)
        }
        
        textLayer.font = CGFontCreateWithFontName(labelFont.fontName)
        textLayer.fontSize = labelFont.pointSize
        textLayer.string = ""
        
        if showDescriptionText && index >= 0 {
            textLayer.string = dataSource?.pieChart(self, descriptionForSliceAtIndex: index)
        }
        
        let size: CGSize = textLayer.string.sizeWithAttributes([NSFontAttributeName: labelFont])
        textLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        if (strokeEnd - strokeStart) * CGFloat(M_PI) * 2 * strokeRadius < max(size.width, size.height) {
            textLayer.string = ""
        }
        
        let midAngle: CGFloat = (strokeStart + strokeEnd) * CGFloat(M_PI) + startAngle
        
        textLayer.position = CGPointMake(pieCenter.x + strokeRadius * cos(midAngle), pieCenter.y + strokeRadius * sin(midAngle))
    }
    
    public func selectLayerAtIndex(index: Int) {
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil && index < currentPieLayers.count {
            let layerToSelect = currentPieLayers[index] as CAShapeLayer
            let currentPosition = layerToSelect.position
            let midAngle = (layerToSelect.strokeEnd + layerToSelect.strokeStart) * CGFloat(M_PI) + startAngle
            let newPosition = CGPointMake(currentPosition.x + selectedPieOffset * cos(midAngle), currentPosition.y + selectedPieOffset * sin(midAngle))
            layerToSelect.position = newPosition
            selectedLayerIndex = index
        }
    }
    
    public func deselectLayerAtIndex(index: Int) {
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil && index < currentPieLayers.count {
            let layerToSelect = currentPieLayers[index] as CAShapeLayer
            layerToSelect.position = CGPointMake(0, 0)
            layerToSelect.zPosition = 0
            selectedLayerIndex = -1
        }
    }
    
    func getSelectedLayerIndexOnTouch(touch: UITouch) -> Int {
        
        var selectedIndex = -1
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil {
            
            let point = touch.locationInView(contentView)
            
            for var i = 0; i < currentPieLayers.count; i++ {
                
                let pieLayer = currentPieLayers[i] as CAShapeLayer
                
                let pieStartAngle = pieLayer.strokeStart * CGFloat(M_PI * 2)
                let pieEndAngle = pieLayer.strokeEnd * CGFloat(M_PI * 2)
                
                var angle = atan2(point.y - pieCenter.y, point.x - pieCenter.x) - startAngle
                if angle < 0 {
                    angle += CGFloat(M_PI * 2)
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
    
    func handleLayerSelection(#fromIndex: Int, toIndex: Int) {
        if fromIndex == -1 && toIndex != -1 {
            selectLayerAtIndex(toIndex)
            delegate?.pieChart(self, itemSelectedAtIndex: toIndex)
        } else if fromIndex != -1 {
            deselectLayerAtIndex(fromIndex)
            delegate?.pieChart(self, itemDeselectedAtIndex: fromIndex)
        }
    }
    
    public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if let anyTouch: UITouch = touches.anyObject() as? UITouch {
            let selectedIndex = getSelectedLayerIndexOnTouch(anyTouch)
            handleLayerSelection(fromIndex: self.selectedLayerIndex, toIndex: selectedIndex)
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
        super.init(coder: aDecoder)
        setDefaultValues()
    }
    
    

}
