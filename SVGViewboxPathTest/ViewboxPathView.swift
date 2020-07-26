//
//  ViewboxPathView.swift
//  ConfluenceEditor
//
//  Created by Noah Gilmore on 7/25/20.
//  Copyright © 2020 Noah Gilmore. All rights reserved.
//

import Foundation
import SwiftUI

extension CGFloat {
    func squared() -> CGFloat {
        return self * self
    }
}

typealias Radians = CGFloat

enum Sign {
    case negative
    case positive

    var factor: CGFloat {
        switch self {
        case .negative: return -1
        case .positive: return 1
        }
    }

    init(of: CGFloat) {
        if of < 0 {
            self = .negative
        } else {
            self = .positive
        }
    }

    init(positiveIfValue value1: Bool, isNotEqualToValue value2: Bool) {
        if value1 != value2 {
            self = .positive
        } else {
            self = .negative
        }
    }
}

struct Matrix1x2 {
    let a: CGFloat
    let b: CGFloat

    func multiplied(_ factor: CGFloat) -> Matrix1x2 {
        return Matrix1x2(
            a: self.a * factor,
            b: self.b * factor
        )
    }

    func plus(_ other: Matrix1x2) -> Matrix1x2 {
        return Matrix1x2(
            a: self.a + other.a,
            b: self.b + other.b
        )
    }

    func dot(_ other: Matrix1x2) -> CGFloat {
        return self.a * other.a + self.b * other.b
    }

    var cgPoint: CGPoint {
        return CGPoint(x: self.a, y: self.b)
    }

    func magnitude() -> CGFloat {
        return sqrt(self.a.squared() + self.b.squared())
    }
}

typealias Vector2 = Matrix1x2

extension Radians {
    init(between u: Vector2, and v: Vector2) {
        let sign = Sign(of: u.a * v.b - u.b * v.a)
        self = sign.factor * acos(u.dot(v) / (u.magnitude() * v.magnitude()))
    }
}

struct Matrix2x2 {
    let a: CGFloat
    let b: CGFloat
    let c: CGFloat
    let d: CGFloat

    func dot(_ other: Matrix1x2) -> Matrix1x2 {
        return Matrix1x2(
            a: self.a * other.a + self.b * other.b,
            b: self.c * other.a + self.d * other.b
        )
    }
}

// https://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
struct EndpointEllipticCurveParameterization {
    let point1: CGPoint
    let point2: CGPoint
    let largeArcFlag: Bool
    let sweepFlag: Bool
    let rPoint: CGPoint
    let tilt: Radians

    func toCenterParamterization() -> CenterEllipticCurveParamterization {
        // Step 1: Compute (x1′, y1′)
        let product = Matrix1x2(
            a: (point1.x - point2.x) / 2,
            b: (point1.y - point2.y) / 2
        )
        let pointPrime = Matrix2x2(a: cos(tilt), b: sin(tilt), c: -sin(tilt), d: cos(tilt))
            .dot(product).cgPoint

        // Step 2: Compute (cx′, cy′)
        let sign: Sign = Sign(positiveIfValue: largeArcFlag, isNotEqualToValue: sweepFlag)

        let numerator1: CGFloat = rPoint.x.squared() * rPoint.y.squared()
        let numerator2: CGFloat = rPoint.x.squared() * pointPrime.y.squared()
        let numerator3: CGFloat = rPoint.y.squared() * pointPrime.x.squared()
        let numerator: CGFloat = numerator1 - numerator2 - numerator3
        let denominator1: CGFloat = rPoint.x.squared() * pointPrime.y.squared()
        let denominator2: CGFloat = rPoint.y.squared() * pointPrime.x.squared()
        let denominator: CGFloat = denominator1 + denominator2
        let sqrtFactor = sqrt(numerator / denominator)

        let matrix = Matrix1x2(a: rPoint.x * pointPrime.y / rPoint.y, b: -rPoint.y * pointPrime.x / rPoint.x)

        let centerPrime = matrix.multiplied(sign.factor * sqrtFactor)

        // Step 3: Compute (cx, cy) from (cx′, cy′)
        let addend = Matrix1x2(a: (point1.x + point2.x) / 2, b: (point1.y + point2.y) / 2)
        let center = Matrix2x2(a: cos(tilt), b: -sin(tilt), c: sin(tilt), d: cos(tilt))
            .dot(centerPrime)
            .plus(addend)

        // Step 4: Compute θ1 and Δθ
        let theta1VectorFactor = Vector2(
            a: (pointPrime.x - centerPrime.a) / rPoint.x,
            b: (pointPrime.y - centerPrime.b) / rPoint.y
        )
        let theta1 = Radians(between: Vector2(a: 1, b: 0), and: theta1VectorFactor)

        let deltaThetaFactor2 = Vector2(
            a: (-pointPrime.x - centerPrime.a) / rPoint.x,
            b: (-pointPrime.y - centerPrime.b) / rPoint.y
        )
        let deltaThetaBeforeAdjustment = Radians(between: theta1VectorFactor, and: deltaThetaFactor2)

        // In other words, if fS = 0 and the right side of (F.6.5.6) is greater than 0, then subtract 360°, whereas if fS = 1 and the right side of (F.6.5.6) is less than 0, then add 360°. In all other cases leave it as is.
        let finalDeltaTheta: CGFloat
        if sweepFlag == false && deltaThetaBeforeAdjustment > 0 {
            finalDeltaTheta = deltaThetaBeforeAdjustment - CGFloat.pi * 2
        } else if sweepFlag == true && deltaThetaBeforeAdjustment < 0 {
            finalDeltaTheta = deltaThetaBeforeAdjustment + CGFloat.pi * 2
        } else {
            finalDeltaTheta = deltaThetaBeforeAdjustment
        }
        return CenterEllipticCurveParamterization(center: center.cgPoint, startAngle: theta1, sweepDelta: finalDeltaTheta)
    }
}

struct CenterEllipticCurveParamterization {
    let center: CGPoint
    let startAngle: Radians
    let sweepDelta: Radians
}

extension Path {

    /// Adds a cubic bezier curve in this path which approximates stroking the given ellipse from
    /// one angle (relative to the ellipse's major axis) to the other. For details on this magic
    /// formula see http://www.spaceroots.org/documents/ellipse/elliptical-arc.pdf

    mutating func addCurveApproximating(ellipse: GeometricEllipse, startAngleInRadians: CGFloat, endAngleInRadians: CGFloat) {

        let p1 = ellipse.point(fromMajorAxisAtAngleInRadians: startAngleInRadians)

        let p2 = ellipse.point(fromMajorAxisAtAngleInRadians: endAngleInRadians)

        let difference = endAngleInRadians - startAngleInRadians

        let alpha = sin(difference) * (
            (sqrt(4 + 3 * pow(tan((difference) / 2), 2)) - 1) / 3
        )

        let q1 = p1.adding(point: ellipse.pointOnDerivativeCurve(fromMajorAxisAtAngleInRadians: startAngleInRadians).multiplying(alpha))

        let q2 = p2.subtracting(point: ellipse.pointOnDerivativeCurve(fromMajorAxisAtAngleInRadians: endAngleInRadians).multiplying(alpha))
        if self.currentPoint != p1 {
            self.move(to: p1)
        }
        self.addCurve(to: p2, control1: q1, control2: q2)
    }
}

struct SVGPathShape: Shape {
    let viewbox: CGRect
    let pathCommands: [PathCommand]

  func path(in rect: CGRect) -> Path {
    var path = Path()

    pathCommands.forEach { command in
      switch command {
      case let .moveTo(point):
        path.move(to: point)
      case let .moveToRelative(dx: dx, dy: dy):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
          x: currentPoint.x + dx,
          y: currentPoint.y + dy
        )
        path.move(to: newPoint)
      case let .lineTo(point):
        path.addLine(to: point)
      case let .lineToRelative(dx: dx, dy: dy):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
          x: currentPoint.x + dx,
          y: currentPoint.y + dy
        )
        path.addLine(to: newPoint)
      case let .horizontalLine(x: x):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
          x: x,
          y: currentPoint.y
        )
        path.addLine(to: newPoint)
      case let .horizontalLineRelative(dx: dx):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
            x: currentPoint.x + dx,
            y: currentPoint.y
        )
        path.addLine(to: newPoint)
      case let .verticalLine(y: y):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
          x: currentPoint.x,
          y: y
        )
        path.addLine(to: newPoint)
      case let .verticalLineRelative(dy: dy):
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
          x: currentPoint.x,
          y: currentPoint.y + dy
        )
        path.addLine(to: newPoint)
      case let .cubicBezierCurve(x1: x1, y1: y1, x2: x2, y2: y2, x: x, y: y):
        let endPoint = CGPoint(x: x, y: y)
        let control1 = CGPoint(x: x1, y: y1)
        let control2 = CGPoint(x: x2, y: y2)
        path.addCurve(to: endPoint, control1: control1, control2: control2)
      case let .cubicBezierCurveRelative(dx1: dx1, dy1: dy1, dx2: dx2, dy2: dy2, dx: dx, dy: dy):

        let currentPoint = path.currentPoint ?? .zero
        let endPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
        let control1 = CGPoint(x: currentPoint.x + dx1, y: currentPoint.y + dy1)
        let control2 = CGPoint(x: currentPoint.x + dx2, y: currentPoint.y + dy2)

        path.addCurve(to: endPoint, control1: control1, control2: control2)
      case let .smoothCubicBezierCurve(x2: x2, y2: y2, x: x, y: y):
        let endPoint = CGPoint(x: x, y: y)
        let control = CGPoint(x: x2, y: y2)
        path.addQuadCurve(to: endPoint, control: control)
      case let .smoothCubicBezierCurveRelative(dx2: dx2, dy2: dy2, dx: dx, dy: dy):

        let currentPoint = path.currentPoint ?? .zero
        let endPoint = CGPoint(
          x: currentPoint.x + dx,
          y: currentPoint.y + dy
        )
        let control = CGPoint(
          x: currentPoint.x + dx2,
          y: currentPoint.y + dy2
        )
        path.addQuadCurve(to: endPoint, control: control)
      case let .quadBezierCurve(x1: x1, y1: y1, x: x, y: y):
        let endPoint = CGPoint(x: x, y: y)
        let control = CGPoint(x: x1, y: y1)
        path.addQuadCurve(to: endPoint, control: control)
      case let .quadBezierCurveRelative(dx1: dx1, dy1: dy1, dx: dx, dy: dy):
        let currentPoint = path.currentPoint ?? .zero
        let endPoint = CGPoint(
          x: currentPoint.x + dx,
          y: currentPoint.y + dy
        )
        let control = CGPoint(
          x: currentPoint.x + dx1,
          y: currentPoint.y + dy1
        )
        path.addQuadCurve(to: endPoint, control: control)
      case let .smoothQuadBezierCurve(x: x, y: y):
        // TODO: Implement this
        print("WAH OH")
        break
      case let .smoothQuadBezierCurveRelative(dx: dx, dy: dy):
        // TODO: Implement this
        print("WAH OH")
        break
      case let .elipticalArcCurve(rx, ry, angle, largeArcFlag, sweepFlag, x, y):
        let pointRep = EndpointEllipticCurveParameterization(point1: path.currentPoint ?? .zero, point2: CGPoint(x: x, y: y), largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, rPoint: CGPoint(x: rx, y: ry), tilt: angle)
        let centerRep = pointRep.toCenterParamterization()
        path.addCurveApproximating(ellipse: GeometricEllipse(center: centerRep.center, majorAxis: rx, minorAxis: ry, tiltInRadians: angle), startAngleInRadians: centerRep.startAngle, endAngleInRadians: centerRep.startAngle + centerRep.sweepDelta)
        break
      case let .elipticalArcCurveRelative(rx, ry, angle, largeArcFlag, sweepFlag, dx, dy):
        print("Adding elliptical curve relative: rx=\(rx), ry=\(ry), angle=\(angle), arc=\(largeArcFlag), sweep=\(sweepFlag), dx=\(dx), dy=\(dy)")
        let currentPoint = path.currentPoint ?? .zero
        let newPoint = CGPoint(
            x: currentPoint.x + dx,
            y: currentPoint.y + dy
        )
        let pointRep = EndpointEllipticCurveParameterization(point1: currentPoint, point2: newPoint, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, rPoint: CGPoint(x: rx, y: ry), tilt: angle)
        let centerRep = pointRep.toCenterParamterization()
        path.addCurveApproximating(ellipse: GeometricEllipse(center: centerRep.center, majorAxis: rx, minorAxis: ry, tiltInRadians: angle), startAngleInRadians: centerRep.startAngle, endAngleInRadians: centerRep.startAngle + centerRep.sweepDelta)
        break
      case .closePath:
        path.closeSubpath()
      }
    }

    let transform = CGAffineTransform(translationX: viewbox.origin.x, y: viewbox.origin.y).concatenating(CGAffineTransform(scaleX: rect.width / viewbox.width, y: rect.height / viewbox.height))
//    return Path({ newPath in
//        path.addPath(path, transform: .identity)
//    })
    return path.applying(transform)
  }
}

struct ViewboxPathView: View {
    let viewboxPath: ViewboxPath
    let height: CGFloat

    var body: some View {
        let colors = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
        let conic = AngularGradient(gradient: colors, center: .center, startAngle: .zero, endAngle: .degrees(360))

        return SVGPathShape(viewbox: viewboxPath.viewbox, pathCommands: PathCommand.commands(fromNodeString: viewboxPath.pathString))
            .fill(conic)
            .frame(width: self.height * viewboxPath.viewbox.width / viewboxPath.viewbox.height, height: self.height)
//            .stroke(strokeColor, lineWidth: strokeWidth)
    }
}

extension ViewboxPathView {
    static let string = [
        "M333.49 238",
        "a122 122 0 0 0 27-65.21",
        "C367.87 96.49 308 32 233.42 32",
        "H34",
        "a16 16 0 0 0-16 16",
        "v48",
        "a16 16 0 0 0 16 16",
        "h31.87",
        "v288",
        "H34",
        "a16 16 0 0 0-16 16",
        "v48",
        "a16 16 0 0 0 16 16",
        "h209.32",
        "c70.8 0 134.14-51.75 141-122.4",
        "4.74-48.45-16.39-92.06-50.83-119.6",
        "z",
        "M145.66 112",
        "h87.76",
        "a48 48 0 0 1 0 96",
        "h-87.76",
        "z",
        "m87.76 288",
        "h-87.76",
        "V288",
        "h87.76",
        "a56 56 0 0 1 0 112",
        "z",
    ].joined(separator: " ")
}

struct ViewboxPathView_Previews: PreviewProvider {
//    static let string = "M50 50 l 200 200z"
//    static let string = "M333.49 238a122 122 0 0 0 27-65.21z"

    static var previews: some View {
        ViewboxPathView(
            viewboxPath: ViewboxPath(
                viewbox: CGRect(x: 0, y: 0, width: 384, height: 512),
                pathString: ViewboxPathView.string
            ),
            height: 50
        )
        .padding()
        .background(Color.white)
        .previewLayout(.sizeThatFits)
    }
}

