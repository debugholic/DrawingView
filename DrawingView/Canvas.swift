//
//  Canvas.swift
//  DrawingView
//
//  Created by debugholic on 2022/03/15.
//

import UIKit

public protocol CanvasDelegate {
    func canvas(_ canvas: Canvas, didDrawWithPoints drawingPoints: [CGPoint], with frame: CGRect)
}

public class Canvas: UIView {
    private var paths = [[CGPoint]]()
    
    private lazy var context: CGContext? = {
        return createContext()
    }()
    
    var strokeColor: UIColor = UIColor.black.withAlphaComponent(1) {
        didSet {
            context?.setStrokeColor(strokeColor.cgColor)
        }
    }
    
    var lineWidth: CGFloat = 10 {
        didSet {
            context?.setLineWidth(lineWidth)
        }
    }
    
    private var last: CGPoint?
    
    public var delegate: CanvasDelegate?
        
    public func reset() {
        paths.removeAll()
        UIGraphicsEndImageContext();
        layer.contents = nil
        context = createContext()
    }
    
    public func undo() {
        UIGraphicsEndImageContext();
        layer.contents = nil
        context = createContext()
        if !paths.isEmpty {
            paths.removeLast()
            for path in paths {
                context?.beginPath()
                var last: CGPoint?
                for point in path {
                    context?.move(to: point)
                    if let last = last {
                        context?.addLine(to: last)
                        context?.strokePath()
                        context?.setLineCap(.round)
                    }
                    last = point
                }
                let image = UIGraphicsGetImageFromCurrentImageContext()
                layer.contents = image?.cgImage
            }
        }
    }
    
    func createContext() -> CGContext? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(strokeColor.cgColor)
        context?.setLineWidth(lineWidth)
        return context
    }
    
    deinit {
        UIGraphicsEndImageContext()
    }
        
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstPoint = touches.first!.location(in: self)
        context?.beginPath()
        paths.append([CGPoint]())
        paths[paths.count-1].append(firstPoint)
        context?.move(to: firstPoint)
        last = firstPoint
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let last = last, let point = touches.first?.location(in: self) {
            context?.move(to: last)
            paths[paths.count-1].append(point)
            context?.addLine(to: point)
            context?.strokePath()
            context?.setLineCap(.round)
            self.last = point
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        layer.contents = image?.cgImage
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        context?.addLines(between: paths[paths.count - 1])
        if let boundingBoxOfPath = context?.boundingBoxOfPath {
            delegate?.canvas(self, didDrawWithPoints: paths[paths.count-1], with: boundingBoxOfPath)
        }
    }
}

