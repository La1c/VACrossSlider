//
//  ViewController.swift
//  VACrossSliderDemo
//
//  Created by Vladimir on 15.08.17.
//  Copyright © 2017 Vladimir Ageev. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var crossSlider: VACrossSlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        crossSlider.addTarget(self, action: #selector(updateLabel), for: .valueChanged)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateLabel(){
        coordinateLabel.text = "X: \(NSString(format:"%.2f", crossSlider.value.x)) Y: \(NSString(format:"%.2f", crossSlider.value.y))"
    }


}

