//
//  ViewController.swift
//  DemoHealthKit
//
//  Created by Pulkit on 6/28/17.
//  Copyright © 2017 Pulkeet. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        HealthManagerKit.Shared.authorizeHealthKit { (authorized, error) -> Void in
            if authorized {
                print("HealthKit authorization received.")
                
               // self.fetchHealthData()
                self.fetchSample()
            }
            else
            {
                print("HealthKit authorization denied!")
                if error != nil {
                    print("\(error?.debugDescription ?? "")")
                }
            }
        }

        
    }

    //Above will provide data only if user has added it in Health App
    private func fetchHealthData(){
        
        var age : Int = 0;
        
        if (HealthManagerKit.Shared.readProfile().age != nil){
            age = HealthManagerKit.Shared.readProfile().age!;
        }
        
        var biologicalSex:HKBiologicalSexObject?
        if (HealthManagerKit.Shared.readProfile().biologicalsex != nil){
            biologicalSex = HealthManagerKit.Shared.readProfile().biologicalsex!;
        }
        
        var bloodType:HKBloodTypeObject?
        if (HealthManagerKit.Shared.readProfile().bloodtype != nil){
            bloodType = HealthManagerKit.Shared.readProfile().bloodtype!;
        }
        
        
        print("Age :",age)
        print("Sex :",biologicalSex?.biologicalSex.rawValue ?? "")
        print("Blood Type :",bloodType?.bloodType.rawValue ?? "")


    }
    
    private func fetchSteps(){
        
        HealthManagerKit.Shared.retrieveStepCount { (steps) in
            print("Steps : ",steps)
        }
    
    }
    
    private func fetchSample(){
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        HealthManagerKit.Shared.readMostRecentSample(sampleType: sampleType!) { (sample, error) in
            
            if (error == nil){
                print(sampleType?.aggregationStyle)
            }
            
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

