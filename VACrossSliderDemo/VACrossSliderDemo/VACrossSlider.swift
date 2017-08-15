//
//  customSlider.swift
//  customControlDemo
//
//  Created by Vladimir on 13.08.17.
//  Copyright © 2017 Vladimir Ageev. All rights reserved.
//

import UIKit
import QuartzCore

/// Slider track layer. Responsible for drawing the track
public class CrossSliderTrackLayer: CALayer {
    
    /// owner slider
    weak var slider: VACrossSlider?
    
    /// draw the track
    ///
    /// - Parameter ctx: current graphics context
    override open func draw(in ctx: CGContext) {
        guard let slider = slider else {
            return
        }
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds,
                                 cornerRadius: cornerRadius)
        path.lineWidth = slider.thumbWidth
        ctx.addPath(path.cgPath)
        
        
        // Fill the track
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }
}

/// the thumb for upper , lower bounds
public class CrossSliderThumbLayer: CALayer {
    
    /// owner slider
    weak var slider: VACrossSlider?
    
    /// whether this thumb is currently highlighted i.e. touched by user
    public var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// stroke color
    public var strokeColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// line width
    public var lineWidth: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    /// draw the thumb
    ///
    /// - Parameter ctx: current graphics context
    override open func draw(in ctx: CGContext) {
        guard let slider = slider else {
            return
        }
        
        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
        
        // Fill
        ctx.setFillColor(slider.thumbTintColor.cgColor)
        ctx.addPath(thumbPath.cgPath)
        ctx.fillPath()
        
        // Outline
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(thumbPath.cgPath)
        ctx.strokePath()
        
        if highlighted {
            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
        }
    }
}



@IBDesignable
open class VACrossSlider: UIControl {
    
    //MARK: properties
    
    
    ///minimum values
    @IBInspectable open var minimumValueX: CGFloat = -1.0 {
        willSet(newValue) {
            assert(newValue <= maximumValueX, "VACrossSlider: minimumValueX should be lower than maximumValueX")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable open var minimumValueY: CGFloat = -1.0 {
        willSet(newValue) {
            assert(newValue <= maximumValueY, "VACrossSlider: minimumValueY should be lower than maximumValueY")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    ///maximum values
    @IBInspectable open var maximumValueX: CGFloat = 1.0 {
        willSet(newValue) {
            assert(newValue >= minimumValueX, "VACrossSlider: minimumValueX should be lower than maximumValueX")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable open var maximumValueY: CGFloat = 1.0 {
        willSet(newValue) {
            assert(newValue >= minimumValueY, "VACrossSlider: minimumValueY should be lower than maximumValueY")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    
    @IBInspectable open var value: CGPoint = CGPoint(x: 0.0, y: 0.0){
        didSet {
            if value.x > maximumValueX {
                value.x = maximumValueX
            } else if value.x < minimumValueX{
                value.x = minimumValueX
            }
            
            if value.y > maximumValueY {
                value.y = maximumValueY
            } else if value.y < minimumValueY{
                value.y = minimumValueY
            }
            
            updateLayerFrames()
        }
    }
    
    /// set 0.0 for square thumbs to 1.0 for circle thumbs
    @IBInspectable open var curvaceousness: CGFloat = 1.0 {
        didSet {
            if curvaceousness < 0.0 {
                curvaceousness = 0.0
            }
            
            if curvaceousness > 1.0 {
                curvaceousness = 1.0
            }
            
            trackLayerX.setNeedsDisplay()
            trackLayerY.setNeedsDisplay()
            thumbLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable open var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayerX.setNeedsDisplay()
            trackLayerY.setNeedsDisplay()
        }
    }
    
    /// thumb tint color
    @IBInspectable open var thumbTintColor: UIColor = UIColor.white {
        didSet {
            thumbLayer.setNeedsDisplay()
        }
    }
    
    /// stepValue. If set, will snap to discrete step points along the slider . Default to nil
    @IBInspectable open var stepValue: Double? = nil {
        willSet(newValue) {
            if newValue != nil {
                assert(newValue! > 0, "VACrossSlider: stepValue must be positive")
            }
        }
        didSet {
            if let val = stepValue {
                if val <= 0 {
                    stepValue = nil
                }
            }
            
            updateLayerFrames()
        }
    }
    
    
    /// previous touch location
    fileprivate var previouslocation = CGPoint()
    
    /// track layer
    fileprivate let trackLayerX = CrossSliderTrackLayer()
    fileprivate let trackLayerY = CrossSliderTrackLayer()
    
    /// thumb width
    fileprivate var thumbWidth: CGFloat {
        return CGFloat(32)
    }
    
    /// thumb layer
    public let thumbLayer = CrossSliderThumbLayer()
  
    
    //MARK: init methods
    
    /**
     Initialize new slider view using the given frame.
     - parameter frame: the location and size of the slider
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    /**
     Initialize new slider view from a file.
     - parameter coder: the source of the slider configuration information
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    
    //MARK: layers
    
    /// layout sub layers
    ///
    /// - Parameter of: layer
    override open func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of:layer)
        updateLayerFrames()
    }
    
    
    /// init layers
    fileprivate func initialize() {
        layer.backgroundColor = UIColor.clear.cgColor
        
        trackLayerX.slider = self
        trackLayerY.slider = self
        trackLayerX.contentsScale = UIScreen.main.scale
        trackLayerY.contentsScale = UIScreen.main.scale

        layer.addSublayer(trackLayerX)
        layer.addSublayer(trackLayerY)
        
        thumbLayer.slider = self
        thumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(thumbLayer)
    }
    
    /// update layer frames
    open func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayerY.frame = CGRect(x: bounds.midX - thumbWidth / 32, y: thumbWidth / 16, width: thumbWidth / 16, height: bounds.height - thumbWidth / 8)
        trackLayerY.setNeedsDisplay()
        
        let thumbCenter = positionForValue(value)
        thumbLayer.frame = CGRect(x: thumbCenter.x, y: thumbCenter.y, width: thumbWidth, height: thumbWidth)
        thumbLayer.setNeedsDisplay()
        
        trackLayerX.frame = CGRect(x: thumbWidth / 16, y: thumbLayer.frame.midY - thumbWidth / 32, width: bounds.width - thumbWidth / 8, height: thumbWidth / 16)
        trackLayerX.setNeedsDisplay()
        
        
        CATransaction.commit()
    }
    
    /// thumb (x, y) position for new value
    open func positionForValue(_ value: CGPoint) -> CGPoint {
        if (maximumValueX == minimumValueX && maximumValueY == minimumValueY) {
            return CGPoint.zero
        }
        
        let pos = CGPoint(x: (bounds.width - thumbWidth) * (value.x - minimumValueX) / (maximumValueX - minimumValueX) ,
                          y: (bounds.height - thumbWidth) * (value.y - minimumValueY) / (maximumValueY - minimumValueY))
        
        return pos
    }
    
    
    // MARK: - Touches
    
    /// begin tracking
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previouslocation = touch.location(in: self)
        
        // set highlighted positions for lower and upper thumbs
        if thumbLayer.frame.contains(previouslocation) {
            thumbLayer.highlighted = true
        }
        
        
        return thumbLayer.highlighted
    }
    
    /// update positions for lower and upper thumbs
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        // Determine by how much the user has dragged
        let deltaLocationX = location.x - previouslocation.x
        let deltaLocationY = location.y - previouslocation.y
        var deltaValueX : CGFloat = 0
        var deltaValueY : CGFloat = 0
        
        
        deltaValueX = (maximumValueX - minimumValueX) * deltaLocationX / bounds.width
        deltaValueY = (maximumValueY - minimumValueY) * deltaLocationY / bounds.height
            
        
        
        
        previouslocation = location
        
        if (value.x + deltaValueX <= maximumValueX && value.x + deltaValueX >= minimumValueX){
           value.x = value.x + deltaValueX
        }
        
        if (value.y + deltaValueY <= maximumValueY && value.y + deltaValueY >= minimumValueY){
            value.y = value.y + deltaValueY
        }
        
        
        // only send changed value if stepValue is not set. We will trigger this later in endTracking
        if stepValue == nil {
            sendActions(for: .valueChanged)
        }
        
        return true
    }
    
    /// end touch tracking. Unhighlight the two thumbs
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        thumbLayer.highlighted = false
        
        
        // let slider snap after user stop dragging
        if let stepValue = stepValue {
            value.x = round(value.x / CGFloat(stepValue)) * CGFloat(stepValue)
            value.y = round(value.y / CGFloat(stepValue)) * CGFloat(stepValue)
            sendActions(for: .valueChanged)
        }
    }
    
}
