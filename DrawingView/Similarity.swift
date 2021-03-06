//
//  Similarity.swift
//  DrawingView
//
//  Created by debugholic on 2022/03/15.
//

import UIKit

struct Similarity {
    static var cutOffScore: CGFloat = 0.7
    
    static var w1: CGFloat = 0.4
    static var w2: CGFloat = 0.2
    static var w3: CGFloat = 0.4

    static func compute(p1: [CGPoint], p2: [CGPoint], frameSize: CGSize) -> CGFloat {
        let k = sqrt(pow(frameSize.width, 2) + pow(frameSize.height, 2)) / 2

        var sim1: CGFloat = 0 // 거리
        var sim2: CGFloat = 0 // 크기
        var sim3: CGFloat = 0 // 방향
        
        for i in 0..<p1.count {
            sim1 += (1 - p1[i].distance(to: p2[i])/k)
            
            if i > 0 {
                let s1 = p1[i-1].distance(to: p1[i])
                let s2 = p2[i-1].distance(to: p2[i])
                sim2 += min(s1, s2)/max(s1, s2)
                
                let v1 = CGVector(dx: p1[i].x - p1[i-1].x, dy: p1[i].y - p1[i-1].y)
                let v2 = CGVector(dx: p2[i].x - p2[i-1].x, dy: p2[i].y - p2[i-1].y)
                sim3 += ((((v1.dx * v2.dx) + (v1.dy * v2.dy)) / (sqrt(pow(v1.dx, 2) + pow(v1.dy, 2)) * sqrt(pow(v2.dx, 2) + pow(v2.dy, 2)) + 1e-8)) + 1) / 2
            }
        }
        sim1 /= CGFloat(p1.count)
        sim2 /= CGFloat(p1.count)
        sim3 /= CGFloat(p1.count)

        sim1 *= w1
        sim2 *= w2
        sim3 *= w3
        
        return sim1 + sim2 + sim3
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2))
    }
}
