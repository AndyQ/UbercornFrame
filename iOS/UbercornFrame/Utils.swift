//
//  Utils.swift
//  UbercornFrame
//
//  Created by Andy Qua on 25/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

func getDocsFolderURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let docsFolderURL = paths[0]
    return docsFolderURL
}
