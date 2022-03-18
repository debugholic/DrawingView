//
//  ViewController.swift
//  DrawingViewSample
//
//  Created by debugholic on 2022/03/19.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var drawingView: DrawingView! {
        didSet {
            drawingView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var simLabel: UILabel!
    
    var answerName: String?
    var imageName: String?
    var isDrawInSequence: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let url = Bundle.main.url(forResource: imageName, withExtension: "svg") {
            let answer = Bundle.main.url(forResource: answerName, withExtension: "svg")
            drawingView.drawPaths(url: url, answers: answer, isDrawInSequence: isDrawInSequence)
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            self.drawingView.clear()
        }
    }
    
    @IBAction func undo() {
        drawingView.canvas.undo()
    }
    
    @IBAction func autoDraw() {
        
    }
    
    @IBAction func clear() {
        drawingView.clear()
    }
}

extension ViewController: DrawingViewDelegate {
    func drawingViewDidEndDrawing(_ drawingView: DrawingView, at index: Int) {
        simLabel.text = String(format: "%.1f", drawingView.paths[index].similarity)
    }
}


