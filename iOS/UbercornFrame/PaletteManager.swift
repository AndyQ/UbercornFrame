//
//  PaletteManager.swift
//  GameFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class PaletteManager {
    static let instance = PaletteManager()
    
    var palettes : [String:Palette]
    
    var initialPalette : String {
        let name = getAllPaletteNames()[0]
        return name
    }
    
    func getAllPaletteNames() -> [String] {
        return palettes.keys.sorted()
    }

    var nrPalettes : Int {
        return palettes.count
    }

    private init() {
        palettes = Palette.loadPalettes()
    }
    
    
    func getPalette(_ name: String ) -> Palette? {
        return palettes[name]
    }
}
