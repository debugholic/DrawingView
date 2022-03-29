//
//  DrawingView.swift
//  DrawingView
//
//  Created by debugholic on 2022/03/15.
//

import UIKit
import PocketSVG

protocol DrawingViewDelegate {
    func drawingViewDidEndDrawing(_ drawingView: DrawingView, at index: Int)
}

class DrawingPath {
    let svgPath: SVGBezierPath
    var similarity: CGFloat = 0
    var isDrawn: Bool {
        similarity > Similarity.cutOffScore
    }

    init(svgPath: SVGBezierPath) {
        self.svgPath = svgPath
    }
}

public class DrawingView: UIView {    
    let canvas: Canvas
    private let imageView: UIImageView
    var delegate: DrawingViewDelegate?
    
    var answers: [SVGBezierPath]?
    var paths = [DrawingPath]()
    
    var strokeColor: UIColor = UIColor.blue.withAlphaComponent(1) {
        didSet {
            DispatchQueue.main.async { [self] in
                self.canvas.strokeColor = strokeColor
            }
        }
    }
    
    var lineWidth: CGFloat = 10 {
        didSet {
            DispatchQueue.main.async { [self] in
                self.canvas.lineWidth = lineWidth
            }
        }
    }

    private var isDrawInSequence: Bool = false
    private(set) var sequence: Int?
    
    public override init(frame: CGRect) {
        canvas = Canvas(frame: frame)
        imageView = UIImageView(frame: frame)
        super.init(frame: frame)
        addSubview(canvas)
        addSubview(imageView)
        bringSubviewToFront(canvas)
        canvas.delegate = self
    }
    
    required init?(coder: NSCoder) {
        canvas = Canvas(frame: .zero)
        imageView = UIImageView(frame: .zero)
        super.init(coder: coder)
        addSubview(canvas)
        addSubview(imageView)
        bringSubviewToFront(canvas)
        canvas.delegate = self
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        canvas.frame = bounds
        imageView.frame = bounds
    }

    public func drawPaths(url: URL, answers: URL? = nil, isDrawInSequence: Bool = false) {
        applyScale(paths: SVGBezierPath.pathsFromSVG(at: url)) { paths in
            self.paths = self.drawPaths(paths.map({ DrawingPath(svgPath: $0) }))
        }

        if let answers = answers {
            applyScale(paths: SVGBezierPath.pathsFromSVG(at: answers)) { paths in
                self.answers = paths
            }
        }
        self.isDrawInSequence = isDrawInSequence
        sequence = isDrawInSequence ? 0 : nil
    }
    
    public func drawPaths(string: String, answers: String? = nil, isDrawInSequence: Bool = false) {
        applyScale(paths: SVGBezierPath.paths(fromSVGString: string)) { paths in
            self.paths = self.drawPaths(paths.map({ DrawingPath(svgPath: $0) }))
        }

        if let answers = answers {
            applyScale(paths: SVGBezierPath.paths(fromSVGString: answers)) { paths in
                self.answers = paths
            }
        }
        self.isDrawInSequence = isDrawInSequence
        sequence = isDrawInSequence ? 0 : nil
    }
    
    public func drawPaths(svgPaths: [SVGBezierPath], answers: [SVGBezierPath]? = nil, isDrawInSequence: Bool = false) {
        if let answers = answers {
            applyScale(paths: answers) { paths in
                self.answers = paths
            }
        }
        applyScale(paths: svgPaths) { paths in
            self.paths = self.drawPaths(paths.map({ DrawingPath(svgPath: $0) }))
        }
        self.isDrawInSequence = isDrawInSequence
        sequence = isDrawInSequence ? 0 : nil
    }
    
    func applyScale(paths: [SVGBezierPath], completion: @escaping ([SVGBezierPath])->()) {
        DispatchQueue.main.async {
            self.imageView.layoutIfNeeded()
            for path in paths {
                if path.viewBox.width > 0 && path.viewBox.height > 0 {
                    let scaleX = self.imageView.bounds.width / path.viewBox.width
                    let scaleY = self.imageView.bounds.height / path.viewBox.height
                    path.apply(CGAffineTransform(scaleX: scaleX, y: scaleY))
                }
            }
            completion(paths)
        }
    }
    
    @discardableResult private func drawPaths(_ paths: [DrawingPath]) -> [DrawingPath] {
        UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
                
        for path in paths.sorted(by: { !$0.isDrawn && $1.isDrawn }) {
            context?.setFillColor(gray: path.isDrawn ? 0.0 : 0.8, alpha: 1.0)
            context?.setLineWidth(path.svgPath.lineWidth)
            context?.beginPath()
            context?.addPath(path.svgPath.cgPath)
            path.svgPath.fill()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        self.imageView.image = image
        
        UIGraphicsEndImageContext();
        return paths
    }
    
    public func clear() {
        canvas.reset()
        for path in paths {
            path.similarity = 0
        }
        sequence = isDrawInSequence ? 0 : nil
        canvas.isUserInteractionEnabled = true
        drawPaths(paths)
    }
}

extension DrawingView: CanvasDelegate {
    public func canvas(_ canvas: Canvas, didDrawWithPoints drawingPoints: [CGPoint], with frame: CGRect) {
        if let answers = answers {
            canvas.undo()
            var index: Int?
            var maxSim: CGFloat = 0
                     
            var points = [CGPoint]()
            points.append(drawingPoints[0])
            if drawingPoints.count > 1 {
                for i in 1..<drawingPoints.count {
                    if drawingPoints[i-1].distance(to: drawingPoints[i]) > 5{
                        points.append(drawingPoints[i])
                    }
                }
            }
            
            if let sequence = sequence, sequence < answers.count {
                let bezierPath = BezierPath(cgPath: answers[sequence].cgPath)
                bezierPath.generateLookupTable()
                let answerPoints = bezierPath.lookupTable
                maxSim = getSimilarity(points, with: answerPoints)
                index = sequence
                
            } else {
                for i in 0..<answers.count {
                    let bezierPath = BezierPath(cgPath: answers[i].cgPath)
                    bezierPath.generateLookupTable()
                    let answerPoints = bezierPath.lookupTable
                    
                    let sim = getSimilarity(points, with: answerPoints)
                    if sim > maxSim {
                        maxSim = sim
                        index = i
                    }
                }
            }
            
            if let index = index {
                paths[index].similarity = maxSim
                if paths[index].isDrawn, isDrawInSequence {
                    self.sequence = index + 1
                }
                delegate?.drawingViewDidEndDrawing(self, at: index)
            }
            
            drawPaths(paths)
            if paths.filter({ !$0.isDrawn }).isEmpty {
                canvas.isUserInteractionEnabled = false
            }
        }
    }
    
    func getSimilarity(_ pts1: [CGPoint], with pts2: [CGPoint]) -> CGFloat {
        var points = [CGPoint]()

        let larger: [CGPoint] = pts1.count > pts2.count ? pts1 : pts2
        let smaller: [CGPoint] = pts1.count > pts2.count ? pts2 : pts1

        for i in 0..<smaller.count {
            var position = Int(Float(i * larger.count) / (Float(smaller.count) - 1.0 + 1e-8))
            if position >= larger.count {
                position = larger.count - 1
            }
            points.append(larger[position])
        }
        return Similarity.compute(p1: smaller, p2:points, frameSize: frame.size)
    }
}
