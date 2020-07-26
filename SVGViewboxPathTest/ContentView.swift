//
//  ContentView.swift
//  SVGViewboxPathTest
//
//  Created by Noah Gilmore on 7/25/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ViewboxPathView(
            viewboxPath: ViewboxPath(
                viewbox: CGRect(x: 0, y: 0, width: 384, height: 512),
                pathString: ViewboxPathView.string
            ),
            height: 100
        )
        .frame(width: 512, height: 512)
        .padding()
        .background(Color.white)
    }
}
