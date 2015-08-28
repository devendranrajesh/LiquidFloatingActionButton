//
//  LiquidFloatingActionButton.swift
//  Pods
//
//  Created by Takuma Yoshida on 2015/08/25.
//
//

import Foundation
import QuartzCore

public enum LiquidFloatingDirection {
    case Line
    case LiquidLine
    case Circle
    case LiquidCircle
}

private class LiquidFloatingButtonCell : UIButton {
    
    var onPressed: (() -> ())!

    init(frame: CGRect, onPressed: () -> ()) {
        self.onPressed = onPressed
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
    }
}

@IBDesignable
public class LiquidFloatingActionButton : UIView {

    let internalRadiusRatio: CGFloat = 20.0 / 56.0
    
    var isClosed: Bool {
        get {
            return plusRotation == 0
        }
    }
    @IBInspectable var color: UIColor = UIColor(red: 82 / 255.0, green: 112 / 255.0, blue: 235 / 255.0, alpha: 1.0)
    var buttonImages: [UIImage] = []
    let direction: LiquidFloatingDirection
    let plusLayer = CAShapeLayer()
    let circleLayer = CAShapeLayer()
    var touching = false
    var plusRotation: CGFloat = 0
    var baseView = CircleLiquidBaseView()
    let liquidView = UIView()
    var cells: [UIView] = []

    public init(frame: CGRect, direction: LiquidFloatingDirection = .Line) {
        self.direction = direction
        super.init(frame: frame)
        setup()
    }

    required public init(coder aDecoder: NSCoder) {
        self.direction = .Line
        super.init(coder: aDecoder)
        setup()
    }

    public func addCellImage(image: UIImage, onSelected: () -> ()) {
        let cell = LiquidFloatingCell(center: self.center.minus(self.frame.origin), radius: self.frame.width * 0.38, color: self.color, icon: image)
        cells.append(cell)
        insertSubview(cell, aboveSubview: baseView)
    }

    public func addCellView(view: UIView, onSelected: () -> ()) {
        
    }

    public func open() {
        // rotate plus icon
        self.plusLayer.addAnimation(plusKeyframe(isClosed), forKey: "plusRot")
        self.plusRotation = CGFloat(M_PI * 0.25)
        
        self.baseView.open(cells)
    }

    public func close() {
        // rotate plus icon
        self.plusLayer.addAnimation(plusKeyframe(isClosed), forKey: "plusRot")
        self.plusRotation = 0
    
        self.baseView.close(cells)
    }

    // MARK: draw icon
    public override func drawRect(rect: CGRect) {
        drawCircle()
        drawShadow()
        drawPlus(plusRotation)
    }
    
    private func drawCircle() {
        self.circleLayer.frame = CGRect(origin: CGPointZero, size: self.frame.size)
        self.circleLayer.cornerRadius = self.frame.width * 0.5
        self.circleLayer.masksToBounds = true
        if touching {
//            self.circleLayer.backgroundColor = self.color.white(0.5).CGColor
        } else {
            self.circleLayer.backgroundColor = self.color.CGColor
        }
    }
    
    private func drawPlus(rotation: CGFloat) {
        plusLayer.frame = CGRect(origin: CGPointZero, size: self.frame.size)
        plusLayer.lineCap = kCALineCapRound
        plusLayer.strokeColor = UIColor.whiteColor().CGColor // TODO: customizable
        plusLayer.lineWidth = 3.0

        plusLayer.path = pathPlus(rotation).CGPath
    }
    
    private func drawShadow() {
        appendShadow(self.circleLayer)
    }
    
    private func pathPlus(rotation: CGFloat) -> UIBezierPath {
        let radius = self.frame.width * internalRadiusRatio * 0.5
        let center = self.center.minus(self.frame.origin)
        let points = [
            CGMath.circlePoint(center, radius: radius, rad: rotation),
            CGMath.circlePoint(center, radius: radius, rad: CGFloat(M_PI_2) + rotation),
            CGMath.circlePoint(center, radius: radius, rad: CGFloat(M_PI_2) * 2 + rotation),
            CGMath.circlePoint(center, radius: radius, rad: CGFloat(M_PI_2) * 3 + rotation)
        ]
        let path = UIBezierPath()
        path.moveToPoint(points[0])
        path.addLineToPoint(points[2])
        path.moveToPoint(points[1])
        path.addLineToPoint(points[3])
        return path
    }
    
    private func plusKeyframe(closed: Bool) -> CAKeyframeAnimation {
        var paths = closed ? [
                pathPlus(CGFloat(M_PI * 0)),
                pathPlus(CGFloat(M_PI * 0.125)),
                pathPlus(CGFloat(M_PI * 0.25)),
        ] : [
                pathPlus(CGFloat(M_PI * 0.25)),
                pathPlus(CGFloat(M_PI * 0.375)),
                pathPlus(CGFloat(M_PI * 0.5)),
        ]
        let anim = CAKeyframeAnimation(keyPath: "path")
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        anim.values = paths.map { $0.CGPath }
        anim.duration = 0.5
        anim.removedOnCompletion = true
        anim.fillMode = kCAFillModeForwards
        anim.delegate = self
        return anim
    }

    // MARK: Events
    public override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.touching = true
        setNeedsDisplay()
    }
    
    public override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.touching = false
        setNeedsDisplay()
        didTapped()
    }
    
    public override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        self.touching = false
        setNeedsDisplay()
    }
    
    public override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        setNeedsDisplay()
    }

    // MARK: private methods
    private func setup() {
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = false

        baseView.setup(self)
        addSubview(baseView)
        
        liquidView.frame = baseView.frame
        addSubview(liquidView)
        
        liquidView.layer.addSublayer(circleLayer)
        circleLayer.addSublayer(plusLayer)
    }

    private func didTapped() {
        if isClosed {
            open()
        } else {
            close()
        }
    }

}

class ActionBarBaseView : UIView {
    var opening = false
    func setup(actionButton: LiquidFloatingActionButton) {
    }
    
    func translateY(layer: CALayer, duration: CFTimeInterval, f: (CABasicAnimation) -> ()) {
        let translate = CABasicAnimation(keyPath: "transform.translation.y")
        f(translate)
        translate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translate.removedOnCompletion = false
        translate.fillMode = kCAFillModeForwards
        translate.duration = duration
        layer.addAnimation(translate, forKey: "transYAnim")
    }
}

class CircleLiquidBaseView : ActionBarBaseView {
    
    let openDuration: CGFloat = 0.6
    let closeDuration: CGFloat = 0.2

    var baseLiquid: LiquittableCircle?
    var engine: SimpleCircleLiquidEngine?
    var bigEngine: SimpleCircleLiquidEngine?

    var openingCells: [UIView] = []
    var keyDuration: CGFloat = 0
    var displayLink: CADisplayLink?

    override func setup(actionButton: LiquidFloatingActionButton) {
        self.frame = actionButton.frame
        self.center = actionButton.center.minus(actionButton.frame.origin)
        let radius = min(self.frame.width, self.frame.height) * 0.5
        self.engine = SimpleCircleLiquidEngine(radiusThresh: radius * 0.73, angleThresh: 0.45)
        engine?.viscosity = 0.65
        self.bigEngine = SimpleCircleLiquidEngine(radiusThresh: radius, angleThresh: 0.55)
        bigEngine?.viscosity = 0.65
        self.engine?.color = actionButton.color
        self.bigEngine?.color = actionButton.color

        baseLiquid = LiquittableCircle(center: self.center.minus(self.frame.origin), radius: radius, color: actionButton.color)
        baseLiquid?.clipsToBounds = false
        baseLiquid?.layer.masksToBounds = false
        
        clipsToBounds = false
        layer.masksToBounds = false
        addSubview(baseLiquid!)
    }

    func open(cells: [UIView]) {
        stop()
        let distance: CGFloat = self.frame.height * 1.25
        displayLink = CADisplayLink(target: self, selector: Selector("didDisplayRefresh:"))
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        opening = true
        for cell in cells {
            cell.layer.removeAllAnimations()
//            appendShadow(cell.layer)
            eraseShadow(cell.layer)
            openingCells.append(cell)
            cell.userInteractionEnabled = true
        }
    }
    
    func close(cells: [UIView]) {
        stop()
        let distance: CGFloat = self.frame.height * 1.25
        opening = false
        displayLink = CADisplayLink(target: self, selector: Selector("didDisplayRefresh:"))
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        for cell in cells {
            cell.layer.removeAllAnimations()
            eraseShadow(cell.layer)
            openingCells.append(cell)
            cell.userInteractionEnabled = false
        }
    }

    func update(delay: CGFloat, duration: CGFloat, f: (UIView, Int, CGFloat) -> ()) {
        if openingCells.isEmpty {
            return
        }

        let maxDuration = duration + CGFloat(openingCells.count) * CGFloat(delay)
        let t = keyDuration
        let allRatio = easeInEaseOut(t / maxDuration)

        if allRatio >= 1.0 {
            stop()
            return
        }

        engine?.clear()
        bigEngine?.clear()
        for i in 0..<openingCells.count {
            if let liquidCell = openingCells[i] as? LiquidFloatingCell {
                let cellDelay = CGFloat(delay) * CGFloat(i)
                let ratio = easeInEaseOut((t - cellDelay) / duration)
                f(liquidCell, i, ratio)
                liquidCell.update(ratio)
            }
        }

        if let firstCell = openingCells[0] as? LiquittableCircle {
            bigEngine?.push(baseLiquid!, other: firstCell)
        }
        for i in 1..<openingCells.count {
            if let prev = openingCells[i - 1] as? LiquittableCircle, cell = openingCells[i] as? LiquittableCircle {
                engine?.push(prev, other: cell)
            }
        }
        engine?.draw(baseLiquid!)
        bigEngine?.draw(baseLiquid!)
    }
    
    func updateOpen() {
        update(0.1, duration: openDuration) { cell, i, ratio in
            let posRatio = ratio > CGFloat(i) / CGFloat(self.openingCells.count) ? ratio : 0
            let distance = (cell.frame.height * 0.5 + CGFloat(i + 1) * cell.frame.height * 1.5) * posRatio
            cell.center = self.center.minusY(distance)
        }
    }
    
    func updateClose() {
        update(0, duration: closeDuration) { cell, i, ratio in
            let distance = (cell.frame.height * 0.5 + CGFloat(i + 1) * cell.frame.height * 1.5) * (1 - ratio)
            cell.center = self.center.minusY(distance)
        }
    }
    
    func stop() {
        for cell in openingCells {
            appendShadow(cell.layer)
        }
        openingCells = []
        keyDuration = 0
        displayLink?.invalidate()
    }
    
    // t [0-1] b 0 c 1 d 1
    func easeInEaseOut(t: CGFloat) -> CGFloat {
        if t >= 1.0 {
            return 1.0
        }
        if t < 0 {
            return 0
        }
        var t2 = t * 2
        return -1 * t * (t - 2)
    }
    
    func didDisplayRefresh(displayLink: CADisplayLink) {
        if opening {
            keyDuration += CGFloat(displayLink.duration)
            updateOpen()
        } else {
            keyDuration += CGFloat(displayLink.duration)
            updateClose()
        }
    }

}

class LiquidFloatingCell : LiquittableCircle {

    init(center: CGPoint, radius: CGFloat, color: UIColor, icon: UIImage) {
        super.init(center: center, radius: radius, color: color)
        setup(icon)
    }
    

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(image: UIImage) {
        userInteractionEnabled = false
        let size = CGSize(width: frame.width * 0.5, height: frame.height * 0.5)
        let imageView = UIImageView(frame: CGRect(x: frame.width - frame.width * 0.75, y: frame.height - frame.height * 0.75, width: size.width, height: size.height))
        imageView.image = image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        imageView.tintColor = UIColor.whiteColor()
        addSubview(imageView)
    }

    func update(key: CGFloat) {
        for subview in self.subviews {
            if let view = subview as? UIView {
                view.alpha = 2 * (key - 0.5)
            }
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    }

}