//
//  PaletteView.swift
//  UbercornFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class PaletteView: UIView {
    @IBOutlet weak var paletteName : UILabel!
    @IBOutlet weak var viewWidth : NSLayoutConstraint!

    var currentPalette : Palette!
    
    var selectedIndex = 0

    var colorChanged : ((UIColor)->())?
    var changePalette : (()->())?
    var showPage : ((Int)->())?
    var chooseColor : ((UIView, CGRect)->())?
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
            
            if checkColorTouched( p ) {
                chooseColor?(self, self.bounds)
            } else {
                changePalette?()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        _ = checkColorTouched(p)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        _ = checkColorTouched(p)
    }
    
    func checkColorTouched( _ p : CGPoint ) -> Bool {
        let x = Int(p.x) / 40
        let y = Int(p.y) / 40
        
        guard x < 8 && y < 3 else { return false}
        let index = x + (y*8)
        
        if index != selectedIndex && currentPalette.colors.count > index {
            selectedIndex = index
            colorChanged?( currentPalette.colors[index] )

            self.setNeedsDisplay()
        }
        
        return true
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        guard let currentPalette = currentPalette else { return }

        for (index, element) in currentPalette.colors.enumerated() {
            let buttonPage = index / 24
            let buttonIndex = (index - (24*buttonPage))
            let buttonX = buttonIndex % 8
            let buttonY = buttonIndex / 8
            
            var x :CGFloat = 5 + CGFloat(40 * buttonX) + CGFloat(buttonPage) * normalViewWidth
            var y :CGFloat = [5,45,85][buttonY]//buttonY == 0 ? 5 : 80
            var w = buttonWidth
            var h = buttonHeight
            
            if index == selectedIndex {
                x -= 3
                y -= 3
                w += 6
                h += 6
            }

            ctx.setFillColor(element.cgColor)
            ctx.addRect(CGRect(x:x, y:y, width:w, height:h))
            ctx.drawPath(using: .fillStroke)

        }
        
    }

    func createAddButton() {
        // create Add new color button
        
        let x :CGFloat = self.viewWidth.constant - 40
        var y :CGFloat = 5//self.bounds.height/2 - buttonWidth/2
        
        let addColorButton = createButton(x:x, y:y, backgroundColor:.white)
        addColorButton.setImage(UIImage(named:"plus"), for: .normal)
        addColorButton.addTarget(self, action: #selector(PaletteView.createNewColorPressed(_:)), for: .touchUpInside)
        self.addSubview(addColorButton)
        
        // Create pick button
        y += 40

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
        self.setNeedsDisplay()
        selectedIndex = currentPalette.colors.count-1
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
            self.showPage?( self.currentPalette.colors.count / 24 )
            
            var delay = 0.0
            if self.currentPalette.colors.count % 24 == 1 {
                delay = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+delay, execute: {
                self.chooseColor?(self, self.bounds)
            })
        })
    }

    @objc func pickColorPressed( _ sender : Any ) {
        pickColor?()
    }

    func addColor( _ color : UIColor ) {
        currentPalette.colors.append(color)
        let shouldStartNewPage = currentPalette.colors.count > 1 && currentPalette.colors.count % 24 == 1

        // see if we need to create a new page
        if shouldStartNewPage {
            self.viewWidth.constant += normalViewWidth
            self.layoutIfNeeded()
            createAddButton()
        }

        return
    }

    
    func setPalette( palette: Palette ) {
        self.currentPalette = palette

        if normalViewWidth == 0 {
            normalViewWidth = self.viewWidth.constant
        }

        self.viewWidth.constant = normalViewWidth
        self.subviews.forEach { $0.removeFromSuperview() }
        
        createAddButton()
        
        selectedIndex = 0
        colorChanged?( currentPalette.colors[0] )

        self.setNeedsDisplay()
    }
    
    func colorSelectionChanged(selectedColor color: UIColor) {
        currentPalette.colors[selectedIndex] = color
        colorChanged?( color )
        
        self.setNeedsDisplay()
    }

}
