//
//  Palette.swift
//  GameFrame
//
//  Created by Andy Qua on 20/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

struct Palette {
    var paletteName : String
    var colors = [UIColor]()
    

    static func loadPalettes() -> [String:Palette]{
        
        var palettes = [String:Palette]()
        if let url = Bundle.main.url(forResource: "palettes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)

                let jsonDict = try JSONDecoder().decode([String:[String]].self, from: data)
                
                for (key, value) in jsonDict {
                    let palette = Palette( name: key, colors: value )
                    palettes[key] = palette
                }
                
            } catch {
                print( "Unable to decode palettes.json file!")
            }
        }
        
        return palettes
    }
    
    init( name: String, colors: [String] ) {
        self.paletteName = name
        
        for val in colors {
            let c = UIColor.init(hexString: val)
            self.colors.append( c )
        }
    }
}
