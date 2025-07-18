//
//  Workout.swift
//  IntervalStopwatch
//
//  Created by Alun King on 24/02/2025.
//
import Foundation
import SwiftData
import SwiftUI
import WorkoutKit
import HealthKit

@Model
class Workout:Identifiable, ObservableObject{
    var id=UUID()
    var name:String
    var workoutDescription:String
    var type:String
    var duration:Int = 0
    var formattedDuration:String = "00:00"
    @Relationship(deleteRule: .cascade) var activitySets:[ActivitySet]{didSet{
        calculateWorkoutDuration()
    }}
    @Transient var sortedActivitySets: [ActivitySet] {
        activitySets.sorted(by: { $0.sortIndex < $1.sortIndex })
    }
    
    
    @Transient var plan:WorkoutPlan = WorkoutPlan(.custom(Workout.createSimpleWorkout()))
    
    init(
        name: String = "Workout",
        workoutDescription: String = "",
        type:String = WorkoutTypes.other.rawValue,
        activitySets: [ActivitySet] = []
    ) {
        self.name = name
        self.workoutDescription = workoutDescription
        self.type = type
        self.activitySets = activitySets
        self.calculateWorkoutDuration()
    }
    
    /*
     * Call this function when we load a workout for viewing,
     * so there is a callback if anything gets edited.
     */
    func bindChildren() {
        for activitySet in activitySets {
            activitySet.parentWorkout = self
            for activity in activitySet.activities {
                activity.parentActivitySet = activitySet
            }
        }
    }
    
    
    
    func save(editedWorkout:Workout){
        //copy over the edited information
        self.name = editedWorkout.name
        self.workoutDescription = editedWorkout.workoutDescription
        self.type = editedWorkout.type
        self.activitySets = editedWorkout.activitySets
        self.calculateWorkoutDuration()
    }
    
    @Transient func clone(of originalWorkout:Workout){
        self.name = originalWorkout.name
        self.workoutDescription = originalWorkout.workoutDescription
        self.type = originalWorkout.type
        //loop through and clone the activity sets which avoids SwiftData observing
        self.activitySets = []
        for originalActivitySet in originalWorkout.activitySets {
            let clonedActivitySet = ActivitySet.clone(of:originalActivitySet)
            self.activitySets.append(clonedActivitySet)
        }
        
        //self.activitySets = originalWorkout.activitySets
        self.calculateWorkoutDuration()
    }
    
    func calculateWorkoutDuration() {
        var totalDuration = 0
        for activitySet in activitySets {
            activitySet.calculateTotalDuration()
            totalDuration += activitySet.duration
        }
        self.duration = totalDuration
        //before we complete the total, save the pre-rep duration
        formattedDuration = Workout.formatDuration(for: totalDuration)
    }
    
    @Transient static func formatDuration(for duration:Int) -> String{
        var returnVal: String = ""
        
        if duration > 3600 {
            let hours = (Int(duration / 3600))
            returnVal += ("\(hours):")
        }
        var remainingDuration = duration % 3600
        if remainingDuration >= 60 {
            let minutes = (Int(remainingDuration / 60))
            returnVal += (String(format: "%02d:", minutes))
        } else {
            returnVal += "00:"
        }
        remainingDuration = remainingDuration % 60
        if remainingDuration > 0 {
            returnVal += String(String(format: "%02d", remainingDuration))
        } else {
            returnVal += "00"
        }
        
        return returnVal
    }
    
    @Transient func exportToWorkoutKit() -> CustomWorkout{
        let workoutType:HKWorkoutActivityType = .other
        let workoutLocation:HKWorkoutSessionLocationType = .unknown
        var intervalBlocks:[IntervalBlock] = []
        //we retrieve the sorted activity sets so that the order is based on sortIndex
        for activitySet in self.sortedActivitySets{
            intervalBlocks.append(activitySet.exportToWorkoutKit())
        }
        
        return CustomWorkout(activity: workoutType, location:workoutLocation, displayName:self.name, blocks:intervalBlocks)
    }
}
/* These workout types are taken from Apple HealthKit */
enum WorkoutTypes:String, CaseIterable, Identifiable{
    case preparationAndRecovery = "Recovery"
    case flexibility = "Flexibility"
    case cooldown = "Cooldown"
    case running = "Running"
    case wheelchairRunPace = "Wheelchair"
    case cycling = "Cycling"
    case handCycling = "Hand Cycling"
    case coreTraining = "Core Training"
    case elliptical = "Elliptical"
    case functionalStrengthTraining = "Functional Strength Training"
    case traditionalStrengthTraining = "Traditional Strength Training"
    case crossTraining = "Cross Training"
    case mixedCardio = "Mixed Cardio"
    case highIntensityIntervalTraining = "HIIT"
    case jumpRope = "Rope Jumping"
    case stairClimbing = "Stair Climbing"
    case stepTraining = "Step Training"
    case yoga = "Yoga"
    case mindAndBody = "Mind and Body"
    case pilates = "Pilates"
    case hiking = "Hiking"
    case crossCountrySkiing = "Cross Country Skiing"
    case skatingSports = "Skating"
    case paddleSports = "Paddle Sports"
    case rowing = "Rowing"
    case swimming = "Swimming"
    case other = "Other"
    var id:String {self.rawValue}
}
    

