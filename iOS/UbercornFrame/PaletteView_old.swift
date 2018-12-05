//
//  PaletteView.swift
//  UbercornFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class PaletteView_old: UIView {
    @IBOutlet weak var paletteName : UILabel!
    @IBOutlet weak var viewWidth : NSLayoutConstraint!
    
    var currentPalette : Palette!
    
    var colourButtons = [UIButton]()
    weak var selectedButton : UIButton?
    
    var colorChanged : ((UIColor)->())?
    var changePalette : (()->())?
    var showPage : ((Int)->())?
    var chooseColor : ((UIView)->())?
    var pickColor : (()->())?
    let buttonWidth : CGFloat = 35
    let buttonHeight : CGFloat = 35
    
    var normalViewWidth : CGFloat = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(PaletteView.longPress(_:)))
        self.addGestureRecognizer(lpgr)
        
        self.layoutIfNeeded()
    }
    
    @objc func longPress( _ gr : UILongPressGestureRecognizer ) {
        if gr.state == .began {
            let p = gr.location(in: self)
            
            if let v = hitTest(p, with: nil) as? UIButton {
                selectColor( v )
                
                chooseColor?(v)
            } else {
                changePalette?()
            }
        }
    }
    
    func createAddButton() {
        // create Add new color button
        
        var x :CGFloat = self.viewWidth.constant - 40
        let y :CGFloat = self.bounds.height/2 - buttonWidth/2
        
        let addColorButton = createButton(x:x, y:y, backgroundColor:.white)
        addColorButton.setImage(UIImage(named:"plus"), for: .normal)
        addColorButton.addTarget(self, action: #selector(PaletteView.createNewColorPressed(_:)), for: .touchUpInside)
        self.addSubview(addColorButton)
        
        // Create pick button
        x -= 45
        
        let pickColorButton = createButton(x:x, y:y, backgroundColor:.white)
        pickColorButton.setImage(UIImage(named:"dropper"), for: .normal)
        pickColorButton.addTarget(self, action: #selector(PaletteView.pickColorPressed(_:)), for: .touchUpInside)
        self.addSubview(pickColorButton)
    }
    
    func createButton(x: CGFloat, y: CGFloat, backgroundColor:UIColor ) -> UIButton {
        let b = UIButton(type: .custom)
        
        b.frame = CGRect(x: x, y: y, width: buttonWidth, height: buttonHeight)
        
        b.layer.cornerRadius = 0.5 * buttonWidth;
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.black.cgColor
        b.backgroundColor = backgroundColor
        
        b.layer.shadowColor = UIColor.white.cgColor
        b.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        b.layer.masksToBounds = false
        b.layer.shadowRadius = 5.0
        b.layer.shadowOpacity = 1
        
        return b
    }
    
    @objc func createNewColorPressed( _ sender : Any ) {
        addColor( .white )
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
            self.showPage?( self.colourButtons.count / 16 )
            
            var delay = 0.0
            if self.colourButtons.count % 16 == 1 {
                delay = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+delay, execute: {
                self.selectColor( self.colourButtons.last! )
                
                self.chooseColor?(self.selectedButton!)
            })
        })
    }
    
    @objc func pickColorPressed( _ sender : Any ) {
        print( "picking color" )
        pickColor?()
    }
    
    func addColor( _ color : UIColor ) {
        
        // Work out current x and y
        let buttonPage = colourButtons.count / 16
        let buttonIndex = (colourButtons.count - (16*buttonPage))
        let buttonX = buttonIndex % 8
        let buttonY = buttonIndex / 8
        
        let x :CGFloat = 5 + CGFloat(45 * buttonX) + CGFloat(buttonPage) * normalViewWidth
        let y :CGFloat = buttonY == 0 ? 5 : 80
        
        let b = createButton(x:x, y:y, backgroundColor:color)
        
        b.addTarget(self, action: #selector(PaletteView.selectColor(_:)), for: .touchUpInside)
        
        colourButtons.append(b)
        self.addSubview(b)
        
        // see if we need to create a new page
        if (buttonPage+1) * Int(normalViewWidth) > Int(self.viewWidth.constant) {
            self.viewWidth.constant = CGFloat(buttonPage+1) * normalViewWidth
            self.layoutIfNeeded()
            createAddButton()
        }
    }
    
    @objc func selectColor( _ button : UIButton ) {
        if let b = selectedButton {
            b.layer.shadowColor = UIColor.white.cgColor
        }
        
        let newColor = button.backgroundColor!
        button.layer.shadowColor = UIColor.black.cgColor
        selectedButton = button
        
        colorChanged?( newColor )
    }
    
    func setPalette( palette: Palette ) {
        if normalViewWidth == 0 {
            normalViewWidth = self.viewWidth.constant
        }
        
        self.viewWidth.constant = normalViewWidth
        self.colourButtons.removeAll()
        self.subviews.forEach { $0.removeFromSuperview() }
        
        createAddButton()
        for i in 0 ..< palette.colors.count {
            addColor(palette.colors[i])
        }
        
        selectColor(colourButtons[0])
    }
    
    
}


extension PaletteView_old : ColorPickerDelegate {
    func colorSelectionChanged(selectedColor color: UIColor) {
        selectedButton?.backgroundColor = color
        colorChanged?( color )
    }
}
