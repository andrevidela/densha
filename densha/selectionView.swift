//
//  selectionView.swift
//  densha
//
//  Created by avidela on 17/07/2023.
//

import Foundation
import SwiftUI

struct SelectionView : View {
    var name: String = ""
    var body : some View {
        VStack {
            Text(name)
        }
        .padding()
        .background(Color.gray)
    }
}
