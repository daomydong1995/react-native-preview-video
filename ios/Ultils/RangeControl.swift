//
//  RangeControlTrackLayer.swift
//  ImprovePerformance
//
//  Created by Beacon on 9/03/2023.
//

import UIKit
import QuartzCore

protocol RangeControlDelegate: AnyObject {
    func rangeControlValueChanged(_ low: Float, _ up: Float)
    func rangeControlDidEnd()
}

open class RangeControl: UIControl {
    static let height = CGFloat(50.0)
    let margin = CGFloat(1)
    private let trackLayer = RangeControlTrackLayer()
    let lowThumbLayer = RangeControlThumbLayer()
    let upThumbLayer = RangeControlThumbLayer()
    public let backgroundView = UIStackView()
    private let contentView = UIView()
    private  var previousLocation = CGPoint()

    open var minValue:Float = 0.0 { didSet { updateLayerFrames() } }
    open var maxValue:Float = 1.0 { didSet { updateLayerFrames() } }
    open var lowValue:Float = 0.0 { didSet { updateLayerFrames() } }
    open var upValue:Float = 1.0 { didSet {  updateLayerFrames() } }
//    open var onRangeValueChanged: OnRangeValueChanged?
    
    var minDistanceValue: Float = 3.0
    
    weak var delegate: RangeControlDelegate?
    
    open var trackColor: UIColor = UIColor.lightGray.withAlphaComponent(0.45) {
        didSet { trackLayer.setNeedsDisplay() }
    }
    
    open var thumbColor: UIColor =  UIColor.lightGray.withAlphaComponent(0.95) {
        didSet {
            lowThumbLayer.setNeedsDisplay()
            upThumbLayer.setNeedsDisplay()
        }
    }
    
    open var arrowColor: UIColor =  UIColor.white {
        didSet {
            lowThumbLayer.setNeedsDisplay()
            upThumbLayer.setNeedsDisplay()
        }
    }
    
    var gapBetweenThumbs: Float {
        return 0.6 * Float(thumbWidth) * (maxValue - minValue) / Float(bounds.width)
    }
    
    open var thumbWidth:CGFloat{
        return CGFloat(24.0)
    }
    
    open var thumbHeight:CGFloat{
        return CGFloat(bounds.height)
    }
    
    var isBeginTouchEvent = true
    var lastLocation: CGPoint = CGPoint.zero
    
    override open var frame: CGRect { didSet { updateLayerFrames() } }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
//        updateLayerFrames()
    }
    
    private func setup()  {
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundView)
        backgroundView.isUserInteractionEnabled = false
        backgroundView.topAnchor.constraint(equalTo: self.topAnchor, constant: margin).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: thumbWidth).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        setNeedsLayout()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = bounds
        contentView.isUserInteractionEnabled = false
        contentView.backgroundColor = UIColor.clear
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        trackLayer.isOpaque = false
        lowThumbLayer.isOpaque = false
        upThumbLayer.isOpaque = false
        lowThumbLayer.isLeft = true
        contentView.layer.addSublayer(trackLayer)
        contentView.layer.addSublayer(lowThumbLayer)
        contentView.layer.addSublayer(upThumbLayer)

        updateLayerFrames()
        lowThumbLayer.rangeControl = self
        upThumbLayer.rangeControl = self
        trackLayer.rangeControl = self
        
        trackLayer.contentsScale = UIScreen.main.scale
        lowThumbLayer.contentsScale = UIScreen.main.scale
        upThumbLayer.contentsScale = UIScreen.main.scale
        setNeedsDisplay()
    }
    
    func setupVideoTimeLayer() {
        
    }
    
    open func updateLayerFrames() {
        if(minValue == Float.nan || lowValue == Float.nan || upValue == Float.nan || maxValue == Float.nan){
            return
        }
        
        trackLayer.frame = bounds
        
        let lowThumbCenter = CGFloat(positionForValue(lowValue))
        let upThumbCenter = CGFloat(positionForValue(upValue))
        
        lowThumbLayer.frame = CGRect(x: lowThumbCenter - thumbWidth*1.5, y: 0.0, width: thumbWidth, height: thumbHeight)
        upThumbLayer.frame = CGRect(x: upThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbHeight)
        
        trackLayer.setNeedsDisplay()
        lowThumbLayer.setNeedsDisplay()
        upThumbLayer.setNeedsDisplay()
        
        self.delegate?.rangeControlValueChanged(lowValue, upValue)
    }
    
    func positionForValue(_ value: Float) -> Float {
        return Float(bounds.width - thumbWidth*2) * (value - minValue) /
            (maxValue - minValue) + Float(thumbWidth*1.5)
    }
    
    private func boundValue(_ value: Float, toLowerValue lowerValue: Float, upperValue: Float) -> Float {
        return Float.minimum(Float.maximum(value, lowerValue), upperValue)
    }
    
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        
        if lowThumbLayer.frame.contains(previousLocation) {
            lowThumbLayer.highlighted = true
        } else if upThumbLayer.frame.contains(previousLocation) {
            upThumbLayer.highlighted = true
        } else if (lowThumbLayer.frame.union(upThumbLayer.frame).contains(previousLocation)) { //between handles
//            lowThumbLayer.highlighted = true
//            upThumbLayer.highlighted = true
        }
        
        return lowThumbLayer.highlighted || upThumbLayer.highlighted
    }
    
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if self.isBeginTouchEvent == false {
            self.isBeginTouchEvent = true
            self.lastLocation = location
        }
        if self.lastLocation == location {
            return true
        }
        
        self.lastLocation = location
        
        // 1. Determine by how much the user has dragged
        let deltaLocation = Float(location.x - previousLocation.x)
        let deltaValue = (maxValue - minValue) * deltaLocation / Float(bounds.width - thumbWidth*2)
        
        previousLocation = location
        
        // 2. Update the values
        if lowThumbLayer.highlighted {
            var newLowValue = lowValue + deltaValue
            let lowValueTmp = boundValue(newLowValue, toLowerValue: minValue, upperValue: upValue)
            newLowValue = Float.maximum(lowValueTmp, self.minValue)
            if upValue - newLowValue >= 1 {
                lowValue = newLowValue
            }
        }
        if upThumbLayer.highlighted {
            var newUpValue = upValue + deltaValue
            let upValueTmp = boundValue(newUpValue, toLowerValue: lowValue, upperValue: maxValue)
            newUpValue = Float.minimum(upValueTmp, self.maxValue)
            if newUpValue - lowValue >= 1 {
                upValue = newUpValue
            }
        }
        
        // 3. Update the UI
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        self.updateLayerFrames()
        CATransaction.commit()
        return super.continueTracking(touch, with: event)
    }
    
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowThumbLayer.highlighted = false
        upThumbLayer.highlighted = false
        self.isBeginTouchEvent = false
        self.delegate?.rangeControlDidEnd()
    }
    
    func setBackground(_ view: UIView) {
//        view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - margin*2)
        self.backgroundView.addArrangedSubview(view)
    }
}
