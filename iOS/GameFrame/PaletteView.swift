//
//  PaletteView.swift
//  GameFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class PaletteView: UIView {
    @IBOutlet weak var paletteName : UILabel!
    
    let verticalStackView = UIStackView()
    let colorStackView1 = UIStackView()
    let colorStackView2 = UIStackView()

    var colourButtons = [UIButton]()
    var selectedButton : UIButton?

    var colorChanged : ((UIColor)->())?
    var changePalettePressed : (()->())?

    let buttonWidth : CGFloat = 35
    let buttonHeight : CGFloat = 35

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        buildStackViews()
        buildPaletteButtons()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(PaletteView.longPress(_:)))
        self.addGestureRecognizer(lpgr)
    }
    
    @objc func longPress( _ gr : UILongPressGestureRecognizer ) {
        if gr.state == .began {
            changePalettePressed?()
        }
    }

    func buildStackViews() {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.distribution = .fillEqually
        verticalStackView.spacing = 20
        
        self.addSubview(verticalStackView)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[sv]|", options: [], metrics: [:], views: ["sv":verticalStackView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sv(90)]", options: [], metrics: [:], views: ["sv":verticalStackView]))
        
        
        
        colorStackView1.translatesAutoresizingMaskIntoConstraints = false
        colorStackView2.translatesAutoresizingMaskIntoConstraints = false
        
        colorStackView1.axis = .horizontal
        colorStackView1.alignment = .fill
        colorStackView1.distribution = .equalSpacing
        colorStackView2.axis = .horizontal
        colorStackView2.alignment = .fill
        colorStackView2.distribution = .equalSpacing
        
        colorStackView1.addConstraint(NSLayoutConstraint(item: colorStackView1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonHeight))
        colorStackView2.addConstraint(NSLayoutConstraint(item: colorStackView2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonHeight))
        
        verticalStackView.addArrangedSubview(colorStackView1)
        verticalStackView.addArrangedSubview(colorStackView2)
    }
    
    func buildPaletteButtons() {
        let stackViews = [colorStackView1,colorStackView2]
        
        for sv in stackViews {
            sv.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            sv.isLayoutMarginsRelativeArrangement = true
            
            for _ in 0 ..< 8 {
                let b = UIButton(type: .custom)
                b.addConstraint(NSLayoutConstraint(item: b, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonWidth))
                b.addConstraint(NSLayoutConstraint(item: b, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonHeight))
                
                b.layer.cornerRadius = 0.5 * buttonWidth;
                b.layer.borderWidth = 1
                b.layer.borderColor = UIColor.black.cgColor
                b.backgroundColor = UIColor.red
                
                b.layer.shadowColor = UIColor.white.cgColor
                b.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
                b.layer.masksToBounds = false
                b.layer.shadowRadius = 5.0
                b.layer.shadowOpacity = 1
                
                b.addTarget(self, action: #selector(PaletteView.selectColor(_:)), for: .touchUpInside)
                
                sv.addArrangedSubview(b)
                colourButtons.append(b)
            }
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
    
    func setPalette( name: String ) {
        self.paletteName.text = name
        guard let palette = PaletteManager.instance.getPalette(name) else { return }
        
        for i in 0 ..< palette.colors.count {
            colourButtons[i].backgroundColor = palette.colors[i]
        }
        
        if let b = selectedButton {
            colorChanged?( b.backgroundColor! )
        } else {
            selectColor( colourButtons[0])
        }
    }


}
