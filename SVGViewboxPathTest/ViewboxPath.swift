//
//  ViewboxPath.swift
//  ConfluenceEditor
//
//  Created by Noah Gilmore on 7/25/20.
//  Copyright © 2020 Noah Gilmore. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

/// Allows performing common `CGPoint` operations on both `CGPoint` and `PointWrapper`

public protocol CGPointProtocol {

    var x: CGFloat { get }

    var y: CGFloat { get }

}



extension CGPoint: CGPointProtocol {}



extension CGPointProtocol {



    /// Returns a new point by substracting `x` from the receiver.

    public func subtracting(x: CGFloat) -> CGPoint {

        return CGPoint(

            x: self.x - x,

            y: self.y

        )

    }



    /// Returns a new point by substracting `y` from the receiver.

    public func subtracting(y: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x,
            y: self.y - y
        )
    }

    public func subtracting(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x - x,
            y: self.y - y
        )
    }

    /// Returns a new point by adding the components of the given point.

    public func subtracting(point: CGPoint) -> CGPoint {
        return self.subtracting(x: point.x, y: point.y)
    }

    /// Returns a new point by adding `x` to the receiver.
    public func adding(x: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x + x,
            y: self.y
        )
    }

    /// Returns a new point by adding `y` to the receiver.
    public func adding(y: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x,
            y: self.y + y
        )
    }

    public func adding(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x + x,
            y: self.y + y
        )
    }

    /// Returns a new point by adding the components of the given point.
    public func adding(point: CGPoint) -> CGPoint {
        return self.adding(x: point.x, y: point.y)
    }

    public func multiplying(_ factor: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x * factor,
            y: self.y * factor
        )
    }
    /// Returns the distance between the receiver and `point`.

    public func distanceTo(_ point: CGPoint) -> CGFloat {

        let x = pow(self.x - point.x, 2)

        let y = pow(self.y - point.y, 2)

        return sqrt(x + y)

    }



    /// Returns the slope between the receiver and `point`.

    /// - Warning: If points are vertical (slope undefined) this will return `.nan`.

    public func slopeTo(_ point: CGPoint) -> CGFloat {

        let dy = point.y - self.y

        let dx = point.x - self.x

        if dx.isZero {

            return CGFloat.nan

        }

        return dy / dx

    }



    /// Returns the midpoint between the receiver and `point`.

    public func midPointTo(_ point: CGPoint) -> CGPoint {

        let x = (self.x + point.x) / 2.0

        let y = (self.y + point.y) / 2.0

        return CGPoint(x: x, y: y)

    }



    /// Returns uniformly spaced points along the line from the receiver to `endPoint`.

    ///

    /// - Parameters:

    ///   - endPoint: The end point of the line.

    ///   - spacing: The spacing between the points.

    /// - Returns: An array of uniformly spaced points along the line,

    ///            including the receiver but *not* `endPoint`.

    public func uniformPointsAlongLineTo(

        _ endPoint: CGPoint,

        withSpacing spacing: CGFloat

    ) -> [CGPoint] {

        let distance = self.distanceTo(endPoint)

        let numPoints = Int(distance / spacing)



        var pointsAlongLine = [CGPoint]()

        for i in 0...numPoints {

            let k = (CGFloat(i) * spacing) / distance

            let nextX = self.x + k * (endPoint.x - self.x)

            let nextY = self.y + k * (endPoint.y - self.y)

            let nextPoint = CGPoint(x: nextX, y: nextY)

            pointsAlongLine.append(nextPoint)

        }



        return pointsAlongLine

    }



    /// Returns `true` if the receiver is to the right of (greater than) `next`, `false` otherwise.

    public func isToTheRightOf(_ next: CGPoint) -> Bool {

        return self.x > next.x

    }



    /// Returns `true` if the receiver is to the left of (less than) `next`, `false` otherwise.

    public func isToTheLeftOf(_ next: CGPoint) -> Bool {

        return self.x < next.x

    }



    /// Returns `true` if the receiver is above (greater than) `next`, `false` otherwise.

    public func isAbove(_ next: CGPoint) -> Bool {

        return self.y > next.y

    }



    /// Returns `true` if the receiver is below (less than) `next`, `false` otherwise.

    public func isBelow(_ next: CGPoint) -> Bool {

        return self.y < next.y

    }

}

public struct GeometricEllipse: Codable, Equatable {
    /// Center of the ellipse
    public let center: CGPoint

    /// Distance between the ellipse's center and its edge at 0 radians. Analogous to the radius of
    /// a circle on the X axis.
    public let majorAxis: CGFloat

    /// Distance between the ellipse's center and its edge at pi/2 radians. Analogous to the radius
    /// of a circle on the Y axis.
    public let minorAxis: CGFloat

    /// Tilt of the ellipse in radians. E.g. 2 * pi tilt means the ellipse is upside down.
    public let tiltInRadians: CGFloat

    /// Returns the point on this ellipse at a given angle in radians from the positive major axis.
    /// For details on this magic formula, see http://www.spaceroots.org/documents/ellipse/elliptical-arc.pdf=
    /// section 2.1.1
    public func point(fromMajorAxisAtAngleInRadians angle: CGFloat) -> CGPoint {
        let a = self.majorAxis
        let b = self.minorAxis
        let theta = self.tiltInRadians
        let x = self.center.x + a * cos(theta) * cos(angle) - b * sin(theta) * sin(angle)
        let y = self.center.y + a * sin(theta) * cos(angle) + b * cos(theta) * sin(angle)
        return CGPoint(x: x, y: y)
    }

    // Returns the point on the derivative of this ellipse at a given angle in radians from the positive major axis.
    public func pointOnDerivativeCurve(fromMajorAxisAtAngleInRadians angle: CGFloat) -> CGPoint {
        let a = self.majorAxis
        let b = self.minorAxis
        let theta = self.tiltInRadians
        let x = -a * cos(theta) * sin(angle) - b * sin(theta) * cos(angle)
        let y = -a * sin(theta) * sin(angle) + b * cos(theta) * cos(angle)
        return CGPoint(x: x, y: y)
    }

    public init(center: CGPoint, majorAxis: CGFloat, minorAxis: CGFloat, tiltInRadians: CGFloat) {
        self.center = center
        self.majorAxis = majorAxis
        self.minorAxis = minorAxis
        self.tiltInRadians = tiltInRadians
    }
}

/// A curve that spans part of an ellipse. Drawing an elliptic curve is the same as drawing the outer
/// edge of a given sector of the ellipse. A start angle of 0 and an end angle of 2 * pi represents
/// drawing the full ellipse.
public struct EllipticCurve: Equatable {
    /// Ellipse this curve is a subset of
    public let ellipse: GeometricEllipse

    /// Start angle of the curve in radians, counterclockwise from the ellipse's major axis
    public let startInRadians: CGFloat

    /// End angle of the curve in radians, counterclockwise from the ellipse's major axis
    public let endInRadians: CGFloat

    public init(
        ellipse: GeometricEllipse,
        startInRadians: CGFloat,
        endInRadians: CGFloat
    ) {
        self.ellipse = ellipse
        self.startInRadians = startInRadians
        self.endInRadians = endInRadians
    }

    public var center: CGPoint { return self.ellipse.center }
    public var majorAxis: CGFloat { return self.ellipse.majorAxis }
    public var minorAxis: CGFloat { return self.ellipse.minorAxis }
}

public enum PathCommand: Equatable {
  case moveTo(CGPoint) // M
  case moveToRelative(dx: CGFloat, dy: CGFloat) // m
  case lineTo(CGPoint) // L
  case lineToRelative(dx: CGFloat, dy: CGFloat) // l
  case horizontalLine(x: CGFloat) // H
  case horizontalLineRelative(dx: CGFloat) // h
  case verticalLine(y: CGFloat) // V
  case verticalLineRelative(dy: CGFloat) // v
  case cubicBezierCurve(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, x: CGFloat, y: CGFloat) // C
  case cubicBezierCurveRelative(dx1: CGFloat, dy1: CGFloat, dx2: CGFloat, dy2: CGFloat, dx: CGFloat, dy: CGFloat) // c
  case smoothCubicBezierCurve(x2: CGFloat, y2: CGFloat, x: CGFloat, y: CGFloat) // S
  case smoothCubicBezierCurveRelative(dx2: CGFloat, dy2: CGFloat, dx: CGFloat, dy: CGFloat) // s
  case quadBezierCurve(x1: CGFloat, y1: CGFloat, x: CGFloat, y: CGFloat) // Q
  case quadBezierCurveRelative(dx1: CGFloat, dy1: CGFloat, dx: CGFloat, dy: CGFloat) // q
  case smoothQuadBezierCurve(x: CGFloat, y: CGFloat) // T
  case smoothQuadBezierCurveRelative(dx: CGFloat, dy: CGFloat) // t
  case elipticalArcCurve(rx: CGFloat, ry: CGFloat, angle: CGFloat, largeArcFlag: Bool, sweepFlag: Bool, x: CGFloat, y: CGFloat) // A
  case elipticalArcCurveRelative(rx: CGFloat, ry: CGFloat, angle: CGFloat, largeArcFlag: Bool, sweepFlag: Bool, dx: CGFloat, dy: CGFloat) // a
  case closePath // Zz

  private static let formatter = NumberFormatter()

  public static func commands(for string: String) -> [PathCommand] {
    guard string.count >= 1 else { return [] }

    var command = string.replacingOccurrences(of: ",", with: " ")
    let action = command.removeFirst()

    /*
     MoveTo: M, m
     LineTo: L, l, H, h, V, v
     Cubic Bézier Curve: C, c, S, s
     Quadratic Bézier Curve: Q, q, T, t
     Elliptical Arc Curve: A, a
     ClosePath: Z, z
     */

    let scanner = Scanner(string: command)
    var numbers: [CGFloat] = []

    while let number = scanner.scanDouble() {
      numbers.append(CGFloat(number))
    }

    // Remember, this is case sensitive
    switch action {
    case "M":
      var previousNumber: CGFloat = 0

      let pairs: [(CGFloat, CGFloat)] = numbers.enumerated().reduce(into: []) { result, enumeration in
        if enumeration.offset == 0 || enumeration.offset.remainderReportingOverflow(dividingBy: 2).overflow {
          previousNumber = enumeration.element
          return
        }

        result.append((previousNumber, enumeration.element))
      }

      return pairs.map { pair -> PathCommand in
        .moveTo(CGPoint(x: pair.0, y: pair.1))
      }
    case "m":
      var previousNumber: CGFloat = 0

      let pairs: [(CGFloat, CGFloat)] = numbers.enumerated().reduce(into: []) { result, enumeration in
        if enumeration.offset == 0 || enumeration.offset.remainderReportingOverflow(dividingBy: 2).overflow {
          previousNumber = enumeration.element
          return
        }

        result.append((previousNumber, enumeration.element))
      }

      return pairs.map { pair -> PathCommand in
        .moveToRelative(dx: pair.0, dy: pair.1)
      }
    case "L":
      var previousNumber: CGFloat = 0

      let pairs: [(CGFloat, CGFloat)] = numbers.enumerated().reduce(into: []) { result, enumeration in
        if enumeration.offset == 0 || enumeration.offset.remainderReportingOverflow(dividingBy: 2).overflow {
          previousNumber = enumeration.element
          return
        }

        result.append((previousNumber, enumeration.element))
      }

      return pairs.map { pair -> PathCommand in
        .lineTo(CGPoint(x: pair.0, y: pair.1))
      }
    case "l":
      var previousNumber: CGFloat = 0

      let pairs: [(CGFloat, CGFloat)] = numbers.enumerated().reduce(into: []) { result, enumeration in
        if enumeration.offset == 0 || enumeration.offset.remainderReportingOverflow(dividingBy: 2).overflow {
          previousNumber = enumeration.element
          return
        }

        result.append((previousNumber, enumeration.element))
      }

      return pairs.map { pair -> PathCommand in
        .lineToRelative(dx: pair.0, dy: pair.1)
      }
    case "H":
      return numbers.map { x in
        return .horizontalLine(x: x)
      }
    case "h":
      return numbers.map { dx in
        return .horizontalLineRelative(dx: dx)
      }
    case "V":
      return numbers.map { y in
        return .verticalLine(y: y)
      }
    case "v":
      return numbers.map { dy in
        return .verticalLineRelative(dy: dy)
      }
    case "C":
      guard numbers.count == 6 else { return [] }

      return [
        .cubicBezierCurve(
          x1: numbers[0],
          y1: numbers[1],
          x2: numbers[2],
          y2: numbers[3],
          x: numbers[4],
          y: numbers[5]
        )
      ]
    case "c":
        guard numbers.count % 6 == 0 else { return [] }

        return numbers.chunked(into: 6).map { numbers in
            return .cubicBezierCurveRelative(
                dx1: numbers[0],
                dy1: numbers[1],
                dx2: numbers[2],
                dy2: numbers[3],
                dx: numbers[4],
                dy: numbers[5]
            )
        }
    case "S":
      guard numbers.count == 4 else { return [] }

      return [.smoothCubicBezierCurve(x2: numbers[0], y2: numbers[1], x: numbers[2], y: numbers[3])]
    case "s":
      guard numbers.count == 4 else { return [] }

      return [
        .smoothCubicBezierCurveRelative(
          dx2: numbers[0],
          dy2: numbers[1],
          dx: numbers[2],
          dy: numbers[3]
        )
      ]
    case "Q":
      guard numbers.count == 4 else { return [] }

      return [
        .quadBezierCurve(x1: numbers[0], y1: numbers[1], x: numbers[2], y: numbers[3])
      ]
    case "q":
      guard numbers.count == 4 else { return [] }

      return [
        .quadBezierCurveRelative(dx1: numbers[0], dy1: numbers[1], dx: numbers[2], dy: numbers[3])
      ]
    case "T":
      guard numbers.count == 2 else { return [] }

      return [
        .smoothQuadBezierCurve(x: numbers[0], y: numbers[1])
      ]
    case "t":
      guard numbers.count == 2 else { return [] }

      return [
        .smoothQuadBezierCurveRelative(dx: numbers[0], dy: numbers[1])
      ]
    case "A":
      guard numbers.count == 7 else { return [] }

      let rx = numbers[0]
      let ry = numbers[1]
      let angle = numbers[2]
      let arcFlag = numbers[3] == 1
      let sweepFlag = numbers[4] == 1
      let pointX = numbers[5]
      let pointY = numbers[6]

      return [
        .elipticalArcCurve(
          rx: rx,
          ry: ry,
          angle: angle,
          largeArcFlag: arcFlag,
          sweepFlag: sweepFlag,
          x: pointX,
          y: pointY
        )
      ]
    case "a":
        guard numbers.count % 7 == 0 else { return [] }

        return numbers.chunked(into: 7).map { number in
            let rx = numbers[0]
            let ry = numbers[1]
            let angle = numbers[2]
            let arcFlag = numbers[3] == 1
            let sweepFlag = numbers[4] == 1
            let pointX = numbers[5]
            let pointY = numbers[6]
            return .elipticalArcCurveRelative(
                rx: rx,
                ry: ry,
                angle: angle,
                largeArcFlag: arcFlag,
                sweepFlag: sweepFlag,
                dx: pointX,
                dy: pointY
            )
        }
    case "Z", "z":
      return [.closePath]
    default:
      return []
    }
  }

    static func commands(fromNodeString string: String) -> [PathCommand] {
        let scanner = Scanner(string: string)
        var commands: [String] = []

        while var instruction = scanner.scanCharacters(from: .pathCommands) {
          if instruction.count == 2 {
            let first = instruction.removeFirst()
            commands.append("\(first)")
          }

          let command = scanner.scanUpToCharacters(from: .pathCommands) ?? ""
          commands.append("\(instruction)\(command)")
        }

        return commands.flatMap(PathCommand.commands(for:))
    }
}

extension CharacterSet {
  public static let pathCommands = CharacterSet(charactersIn: "MmLlHhVvCcSsQqTtAaZz")
}

extension CGPoint {
    func converting(from sourceRect: CGRect, to destRect: CGRect) -> CGPoint {
        let unitCoordinate = CGPoint(
            x: (self.x - sourceRect.minX) / sourceRect.size.width,
            y: (self.y - sourceRect.minY) / sourceRect.size.height
        )
        return CGPoint(
            x: unitCoordinate.x * destRect.size.width + destRect.minX,
            y: unitCoordinate.y * destRect.size.height + destRect.minY
        )
    }
}

struct ViewboxPath {
    let viewbox: CGRect
    let pathString: String
}
