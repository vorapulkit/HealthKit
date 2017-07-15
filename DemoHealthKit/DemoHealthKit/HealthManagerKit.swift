//
//  HealthManager.swift
//  DemoHealthKit
//
//  Created by Pulkit on 6/30/17.
//  Copyright © 2017 Pulkeet. All rights reserved.
//

import Foundation
import HealthKit


class HealthManagerKit {
    
    
    
    class var Shared: HealthManagerKit {
        struct Static {
            static var onceToken: Int = 0
            static var instance = HealthManagerKit()
        }
        return Static.instance
    }
    
    let healthKitStore:HKHealthStore = HKHealthStore()

    
    //MARK:
    //MARK: Auth
    func authorizeHealthKit(completion:@escaping(_ success:Bool, _ error:NSError?) -> Void)
    {
        // 1. Set the types you want to read from HK Store
        let healthKitTypesToRead : Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,


            HKObjectType.workoutType()
            ]
        
        // 2. Set the types you want to write to HK Store
        let healthKitTypesToWrite : Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKQuantityType.workoutType()
            ]
        
        // 3. If the store is not available (for instance, iPad) return an error and don't go on.
        if !HKHealthStore.isHealthDataAvailable()
        {
            let error = NSError(domain: "com.iMobDev.iutilities", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            completion(false,error as NSError)

            return;
        }
        
        // 4.  Request HealthKit authorization
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite as? Set<HKSampleType>, read: healthKitTypesToRead) { (success, error) -> Void in
            if error != nil {
                completion(success,error! as NSError)
            }else{
                completion(success,nil)

            }
            

        }
    }

    //MARK:
    //MARK: Read User Profile
    //Above will provide data only if user has added it in Health App

    func readProfile() -> ( age:Int?,  biologicalsex:HKBiologicalSexObject?, bloodtype:HKBloodTypeObject?)
    {
        var age:Int?
        
        do {
            if #available(iOS 10.0, *) {
                let birthDay = try healthKitStore.dateOfBirthComponents()
                let today = Date()
                age = yearsBetween(birthDay.date!, maxDate: today)
            } else {
                // Fallback on earlier versions
            }
   

        } catch let error as NSError {
            print("Couldn't read Birthday From Health Kit Error:\(error.description)")
            return (nil,nil,nil)
            }
            // 2. Read biological sex

        var biologicalSex:HKBiologicalSexObject?
        do{
            biologicalSex = try healthKitStore.biologicalSex()
        } catch let error1 as NSError {
            print("Couldn't get biologicalSex From Health Kit Error:\(error1.description)")
            return (nil,nil,nil)
        }

        // 3. Read blood type
        var bloodType:HKBloodTypeObject?
  
        do {
            bloodType = try healthKitStore.bloodType()
        }catch let error2 as NSError {
            print("Couldn't get bloodtype From Health Kit Error:\(error2.description)")
            return (nil,nil,nil)
        }
        
        // 4. Return the information read in a tuple
        return (age, biologicalSex, bloodType)
    }
   private func yearsBetween(_ minDate : Date, maxDate :Date)->Int
    {
        let calendar: Calendar = Calendar.current
        let date1 = calendar.startOfDay(for: minDate)
        let date2 = calendar.startOfDay(for: maxDate)
        let components = (calendar as NSCalendar).components(.year, from: date1, to: date2, options: [])
        return components.year!
        
    }
    
    //MARK:
    //MARK: Steps Count
    func retrieveStepCount(completion: @escaping (_ stepRetrieved: Double) -> Void) {
        
        //   Define the Step Quantity Type
        let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        //   Get the start of the day
        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1
        
        //  Perform the Query
        let query = HKStatisticsCollectionQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: newDate as Date, intervalComponents:interval)
        
        query.initialResultsHandler = { query, results, error in
            
            if error != nil {
                
                //  Something went Wrong
                return
            }
            
            if let myResults = results{
                let calendar = Calendar.current
                let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date())
                
                myResults.enumerateStatistics(from: oneDayAgo!, to: Date()) {
                    statistics, stop in
                    
                    if let quantity = statistics.sumQuantity() {
                        
                        let steps = quantity.doubleValue(for: HKUnit.count())
                        
                        print("Steps = \(steps)")
                        completion(steps)
                        
                    }
                }
            }
            
            
        }
        
        healthKitStore.execute(query)
    }
    //MARK:
    //MARK: Recent Sample
    func readMostRecentSample(sampleType:HKSampleType , completion: @escaping(HKSample?, NSError?) -> Void)
    {
        
        // 1. Build the Predicate
        let past = NSDate.distantPast as NSDate
        let now   = NSDate()
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past as Date, end:now as Date, options: .strictEndDate)
        
        // 2. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
        let limit = 1
        
        // 4. Build samples query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            if error != nil {
                completion(nil,error as NSError?)
                return;
            }
            
            // Get the first sample
            let mostRecentSample = results?.first as? HKQuantitySample
            
            // Execute the completion closure
            completion(mostRecentSample,nil)

        }
        // 5. Execute the Query
        self.healthKitStore.execute(sampleQuery)
    }
}
