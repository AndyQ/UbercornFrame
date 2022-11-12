//
//  ArrayExt.swift
//  UbercornFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

extension Array where Element : Collection,
Element.Iterator.Element : Equatable, Element.Index == Int {
    
    func indices(of x: Element.Iterator.Element) -> (Int, Int)? {
        for (i, row) in self.enumerated() {
            if let j = row.firstIndex(of: x) {
                return (i, j)
            }
        }
        return nil
    }
}
