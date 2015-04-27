# ARPieChart
A lightweight pie chart of pure Swift implementation, inspired by [XYPieChart](https://github.com/xyfeng/XYPieChart).

![Screenshot](https://github.com/nero-tang/ARPieChart/blob/master/screenshots/ARPieChartDemo.gif)
## Requirements

* iOS 8.0+
* Xcode 6.3

## Installation

Drag the source file `ARPieChartDemo/ARPieChart.swift` into your project.

## Feature

* Configurable & Animated inner/outer radius
* Pie selection with flexible offset
* Animated add/remove action
* Customizable text description for each slice

## Usage

Implement data source:

```swift
func numberOfSlicesInPieChart(pieChart: ARPieChart) -> Int
    
func pieChart(pieChart: ARPieChart, valueForSliceAtIndex index: Int) -> CGFloat
    
func pieChart(pieChart: ARPieChart, colorForSliceAtIndex index: Int) -> UIColor
    
func pieChart(pieChart: ARPieChart, descriptionForSliceAtIndex index: Int) -> String
```

Implement delegate:

```swift
func pieChart(pieChart: ARPieChart, itemSelectedAtIndex index: Int)
    
func pieChart(pieChart: ARPieChart, itemDeselectedAtIndex index: Int)
```

Set pie chart's properties:

```swift
public var outerRadius: CGFloat = 0.0

public var innerRadius: CGFloat = 0.0
    
public var selectedPieOffset: CGFloat = 0.0
    
public var labelFont: UIFont = UIFont.systemFontOfSize(10)
    
public var showDescriptionText: Bool = false
    
public var animationDuration: Double = 1.0
```

Explicitly reload data:

```swift
pieChart.reloadData()
```

## LICENSE

Copyright (c) 2015 Yufei Tang

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.