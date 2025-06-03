import Foundation
import SwiftUI


/*
 enum MuscleSplits: String, CaseIterable, Identifiable, Codable {
 case freshMuscles = "Fresh Muscles"
 case pushMuscles = "Push Muscles"
 case pullMuscles = "Pull Muscles"
 case upperBody = "Upper Body"
 case lowerBody = "Lower Body"
 case arms = "Arms"
 case fullBody = "Full Body"
 
 var id: String { self.rawValue }
 }
 
 enum TrainingStyle: String, CaseIterable, Identifiable, Codable {
 case strengthTraining = "Strength Training"
 case hypertrophy = "Hypertrophy"
 case circuitTraining = "Circuit Training"
 case generalFitness = "General Fitness"
 case powerlifting = "Powerlifting"
 case olympicLifting = "Olympic Lifting"
 
 var id: String { self.rawValue }
 }*/


enum CategorySelections: Hashable {
  case split(SplitCategory)
  case muscle(Muscle)
  case upperLower(UpperLower)
  case pushPull(PushPull)
  
  var title: String {
    switch self {
      case .split(let s):      return s.rawValue
      case .muscle(let m):     return m.rawValue
      case .upperLower(let u): return u.rawValue
      case .pushPull(let p):   return p.rawValue
    }
  }
}

enum UpperLower: String, Codable, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
}

enum PushPull: String, Codable, CaseIterable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
}

enum ExerciseSortOption: String, Codable, CaseIterable {
    case simple = "Simple"     // Sort by Simple: All, Back, Legs, Arms, Abs, Shoulders, Chest, Biceps, Triceps
    
    case moderate = "Moderate"     // Sort by Moderate: All, Back, Quads, Calves, Hamstrings, Glutes, Abs, Shoulders, Chest, Biceps, Triceps, Forearms
    
    case complex = "Complex"     // Sort by Complex: All, Abs, Chest, Shoulders, Biceps, Triceps, Trapezius, Latissimus Dorsi, Erector Spinae, Quadriceps, Gluteus, Hamstrings, Hip Flexors, Stabilizers, Calves, Forearms, Neck
    
    case upperLower = "Upper/Lower"     // Sort by Upper Lower: Upper Body, Lower Body
    
    case pushPull = "Push/Pull"     // Sort by Push Pull: Push, Pull, Legs
    
    // Sort by template categories ([SplitCategory])
    case templateCategories = "Template Categories" // removes exercises and categories that are not in the template categories
}

enum CompletedExerciseSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case mostSets = "Most Sets"
    case leastSets = "Least Sets"
    
    var id: String { self.rawValue }
}

enum CompletedWorkoutSortOption: String, CaseIterable, Identifiable {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
    case thisMonth = "This Month"
    case longestDuration = "Longest Duration"
    case shortestDuration = "Shortest Duration"
    
    var id: String { self.rawValue }
}

enum SplitType: String, CaseIterable, Identifiable, Codable {
    case fullBody = "Full-Body"
    case broSplit = "Bro Split"
    case upperLower = "Upper / Lower"
    case pushPullLegs = "Push / Pull / Legs"
    case upperLowerPPL = "Upper / Lower + PPL"
    case arnoldSplit = "Arnold Split"
    case antagonistSplit = "Antagonist Split"
    case torsoLimb = "Torso / Limb"
    
    var id: String { self.rawValue }
    
    var frequencyRange: ClosedRange<Int> {
        switch self {
        case .fullBody: return 2...4
        case .broSplit: return 5...6
        case .upperLower: return 3...5
        case .pushPullLegs: return 3...6
        case .upperLowerPPL: return 5...6
        case .arnoldSplit: return 6...6
        case .antagonistSplit: return 4...6
        case .torsoLimb: return 4...5
        }
    }

    var minimumDaysRequired: Int {
        frequencyRange.lowerBound
    }
    
    var description: String {
        switch self {
        case .fullBody:
            return "Trains the entire body each session. Great for beginners or maximizing efficiency with fewer training days."
        case .broSplit:
            return "Focuses on one major muscle group per day. Popular in bodybuilding circles for high volume per body part."
        case .upperLower:
            return "Alternates between upper and lower body workouts. Balanced and time-efficient for both strength and hypertrophy."
        case .pushPullLegs:
            return "Divides workouts by movement pattern: push (chest/shoulders/triceps), pull (back/biceps), and legs. Easy to scale and structure."
        case .upperLowerPPL:
            return "Combines upper/lower and push/pull/legs into a hybrid rotation. Designed for more advanced lifters needing higher volume and variety."
        case .arnoldSplit:
            return "Classic six-day routine used by Arnold Schwarzenegger, pairing chest/back, shoulders/arms, and legs. Built for high volume and symmetry."
        case .antagonistSplit:
            return "Pairs opposing muscle groups (e.g., chest/back or biceps/triceps) to improve balance, efficiency, and recovery within workouts."
        case .torsoLimb:
            return "Separates workouts into torso (chest, back, shoulders) and limbs (arms, legs). Offers functional variety and recovery balance."
        }
    }
}


enum ExerciseType: String, CaseIterable, Identifiable, Codable {
    case `default` = "Default"
    case bodyweightOnly = "Bodyweight Only"
    case excludeBodyweight = "Exclude Bodyweight"
    /*case freeWeightOnly = "Free Weight Only"
    case machineOnly = "Machine Only"*/
    
    var id: String { self.rawValue }
}

enum SplitCategory: String, CaseIterable, Identifiable, Codable {
    // MARK: - Muscle Group
    case all = "All"
    case back = "Back"
    case legs = "Legs"
    case arms = "Arms"
    
    case abs = "Abs"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    // MARK: - Accessory Groups
    case calves = "Calves"
    case forearms = "Forearms"
    
    var id: String { self.rawValue }
    
    static let upperBody: Set<SplitCategory> = [.back, .shoulders, .arms, .chest, .biceps, .triceps, .forearms]
    static let lowerBody: Set<SplitCategory> = [.legs, .quads, .hamstrings, .glutes, .calves]
    static let push: Set<SplitCategory> = [.chest, .shoulders, .triceps]
    static let pull: Set<SplitCategory> = [.back, .biceps]
    static let armsGroup: Set<SplitCategory> = [.arms, .biceps, .triceps]
   // static let legsGroup: Set<SplitCategory> = [.legs, .quads, .hamstrings, .glutes, .calves]
    
    static let muscles: [SplitCategory: [Muscle]] = [
        .all: [.all],
        .back: [.trapezius, .latissimusDorsi, .erectorSpinae], // add .scapularStabilizers
        .legs: [.quadriceps, .hamstrings, .gluteus, .calves, .hipFlexors],
        .arms: [.biceps, .triceps, .forearms],
        .abs: [.abdominals],
        .shoulders: [.deltoids],
        .chest: [.pectorals],
        .biceps: [.biceps],
        .triceps: [.triceps],
        .forearms: [.forearms],
        .quads: [.quadriceps],
        .hamstrings: [.hamstrings],
        .glutes: [.gluteus],
        .calves: [.calves]
    ]
    
    static let hasFrontImages: Set<SplitCategory> = [
        .all, .legs, .arms, .abs, .chest, .shoulders, .biceps, .triceps, .forearms, .quads, .calves
    ]
    
    static let hasRearImages: Set<SplitCategory> = [
        .all, .legs, .arms, .shoulders, .back, .triceps, .forearms, .hamstrings, .glutes, .calves
    ]
    
    static let hasBothImages: Set<SplitCategory> = hasFrontImages.intersection(hasRearImages)
    
    // Determines which image paths are available for the muscle
    var splitGroupImages: [String] {
       // let basePathFront = "(M)Front_Simple-"
       // let basePathRear = "(M)Rear_Simple-"
        let basePathFront = "Images/Male/Split_Images/Front/(M)Front_Simple-"
        let basePathRear  = "Images/Male/Split_Images/Rear/(M)Rear_Simple-"

        let imageName = self.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if Self.hasFrontImages.contains(self) {
            images.append(basePathFront + imageName)
        }
        
        if Self.hasRearImages.contains(self) {
            images.append(basePathRear + imageName)
        }
        
        return images
    }
    
    static func getLegDetails(categories: [SplitCategory]) -> [String]? {
        var legDetails: [String] = []
        if categories.contains(.quads) { legDetails.append("Quad") }
        if categories.contains(.glutes) { legDetails.append("Glute") }
        if categories.contains(.hamstrings) { legDetails.append("Hamstring") }
        if categories.contains(.calves) { legDetails.append("Calf") }
        if legDetails.isEmpty { return nil }
        return legDetails
    }
    
    static func concatenateCategories(for categories: [SplitCategory]) -> String {
        var categoryNames: String = ""
        
        if categories.contains(.all) {
            categoryNames = "Full Body"
        } else if let legDetails = getLegDetails(categories: categories) {
            if categories.contains(.legs) {
                categoryNames = "Legs: " + legDetails.joined(separator: ", ") + " focused"
            }
        } else {
            // If no leg specifics are included, join all category raw values
            categoryNames = categories.map { $0.rawValue }.joined(separator: ", ")
        }
        
        return categoryNames
    }
    
    static var columnGroups: [[SplitCategory]] {
        [
            [.all, .shoulders, .back, .abs, .chest],
            [.legs, .quads, .glutes, .hamstrings, .calves],
            [.arms, .biceps, .triceps, .forearms]
        ]
    }
}

// create separate split category enum
enum Muscle: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    // MARK: - Independent
    case abdominals = "Abdominals"
    case pectorals = "Pectorals"
    case deltoids = "Deltoids"
    // MARK: - Part of Muscle Group
    case biceps = "Biceps"
    case triceps = "Triceps"
    case trapezius = "Trapezius"
    case latissimusDorsi = "Latissimus Dorsi" // do not include in split picker
    case erectorSpinae = "Erector Spinae" // do not include in split picker
    case quadriceps = "Quadriceps" // legs - quad focused
    case gluteus = "Gluteus" // legs - glute focused
    case hamstrings = "Hamstrings" // legs - hamstring focused
    // MARK: - Accessory
    case hipFlexors = "Hip Flexors" // accessory
    case scapularStabilizers = "Scapular Stabilizers" // accessory
    case calves = "Calves" // accessory
    case forearms = "Forearms" // accessory
    case cervicalSpine = "Cervical Spine" // accessory - neck
    
    var id: String { self.rawValue }
    
    var shortName: String {
        switch self {
        case .abdominals: return "Abs"
        case .pectorals: return "Pecs"
        case .deltoids: return "Delts"
        case .trapezius: return "Traps"
        case .latissimusDorsi: return "Lats"
        case .erectorSpinae: return "Erectors"
        case .quadriceps: return "Quads"
        case .gluteus: return "Glutes"
            // case .hamstrings: return "Hams"
        case .hipFlexors: return "Hips"
        case .scapularStabilizers: return "Stabilizers"
        case .cervicalSpine: return "Cervical"
        default :
            return self.rawValue
        }
    }
    
    var simpleName: String {
        switch self {
        case .pectorals: return "Chest"
        case .deltoids: return "Shoulders"
        case .erectorSpinae: return "Lower Back"
        case .cervicalSpine: return "Neck"
        default :
            return self.shortName
        }
    }
    
    static func getButtonForCategory(_ category: Muscle) -> Image {
        let startPath = "UI/Male-UIButton/"
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-")
        let fullPath = startPath + imageName
        return Image(fullPath)
    }
    
    // Property to check if the muscle should be included
    var isSignificantMuscle: Bool {
        switch self {
        case .trapezius, .latissimusDorsi, .erectorSpinae, .hipFlexors, .scapularStabilizers, .cervicalSpine:
            return false
        default:
            return true
        }
    }
    
    static let Groups: [SplitCategory: [Muscle]] = [
        .arms: [.biceps, .triceps, .forearms],
        .legs: [.hipFlexors, .quadriceps, .hamstrings, .gluteus, .calves],
        .back: [.trapezius, .latissimusDorsi,  .erectorSpinae] // add .scapularStabilizers
    ]
    
    static let SubMuscles: [Muscle: [SubMuscles]] = [
        .abdominals: [.upperAbs, .lowerAbs, .obliques, .externalObliques],
        .pectorals: [.clavicularHead, .sternocostalHead, .costalHead],
        .deltoids: [.frontDelt, .sideDelt, .rearDelt],
        .biceps: [.bicepsLongHead, .bicepsShortHead, .bicepsBrachialis],
        .triceps: [.tricepsLongHead, .tricepsLateralHead, .tricepsMedialHead],
        .trapezius: [.upperTraps, .lowerTraps],
        .latissimusDorsi: [.upperLats, .lowerLats],
        .erectorSpinae: [.iliocostalis, .longissimus, .spinalis],
        .forearms: [.brachioradialis, .forearmFlexors, .forearmExtensors],
        .cervicalSpine: [.sternocleidomastoid, .scalenes, .longusColli, .longusCapitis],
        .hipFlexors: [.adductors, .abductors],
        .scapularStabilizers: [.teresMajor, .teresMinor, .infraspinatus, .rhomboids, .levatorScapulae],
        .quadriceps: [.rectusFemoris, .vastusLateralis, .vastusMedialis],
        .hamstrings: [.medialHamstring, .lateralHamstring],
        .gluteus: [.gluteusMaximus, .gluteusMedius, .gluteusMinimus],
        .calves: [.calvesGastrocnemius, .calvesSoleus]
    ]
    
    static func getSubMuscles(for category: Muscle) -> [SubMuscles] {
        return SubMuscles[category] ?? []
    }
    
    static func getTapForMuscle(_ muscle: Muscle, showFrontView: Bool) -> String? {
        let startPath = showFrontView ? "(M)Front_Tap-" : "(M)Rear_Tap-"
        let imageName = muscle.rawValue.replacingOccurrences(of: " ", with: "-")
        
        if (showFrontView && hasFrontImages.contains(muscle)) || (!showFrontView && hasRearImages.contains(muscle)) {
            return startPath + imageName
        }
        
        // Return nil if no valid image exists for the current view
        return nil
    }
    
    static let hasFrontImages: Set<Muscle> = [
        .all, .abdominals, .pectorals, .trapezius, .deltoids, .biceps, .triceps, .quadriceps, .calves, .forearms, .cervicalSpine, .hipFlexors
    ]
    
    static let hasRearImages: Set<Muscle> = [
        .all, .deltoids, .triceps, .trapezius, .latissimusDorsi, .erectorSpinae, .hamstrings, .gluteus, .calves, .forearms, .scapularStabilizers
    ]
    
    static let hasBothImages: Set<Muscle> = hasFrontImages.intersection(hasRearImages)
    
    // Determines which image paths are available for the muscle
    var muscleGroupImages: [String] {
        let basePathFront = "(M)Front-"
        let basePathRear = "(M)Rear-"
        let imageName = self.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if Self.hasFrontImages.contains(self) {
            images.append(basePathFront + imageName)
        }
        
        if Self.hasRearImages.contains(self) {
            images.append(basePathRear + imageName)
        }
        
        return images
    }
}


enum SubMuscles: String, CaseIterable, Identifiable, Codable {
    // MARK: - Chest
    case clavicularHead = "Clavicular Head" // upper chest
    case sternocostalHead = "Sternocostal Head" // middle chest
    case costalHead = "Costal Head" // lower chest
    
    // MARK: - Shoulders
    case frontDelt = "Front Delt"
    case sideDelt = "Side Delt"
    case rearDelt = "Rear Delt"
    
    // MARK: - Biceps
    case bicepsLongHead = "Biceps Long Head"
    case bicepsShortHead = "Biceps Short Head"
    case bicepsBrachialis = "Biceps Brachialis" // deep
    
    // MARK: - Triceps
    case tricepsLongHead = "Triceps Long Head"
    case tricepsLateralHead = "Triceps Lateral Head"
    case tricepsMedialHead = "Triceps Medial Head"
    
    // MARK: - Abs
    case externalObliques = "External Obliques"
    case upperAbs = "Upper Abs"
    case lowerAbs = "Lower Abs"
    case obliques = "Obliques"
    
    // MARK: - Traps
    case upperTraps = "Upper Traps"
    case lowerTraps = "Lower Traps"
    
    // MARK: - Lats
    case upperLats = "Upper Lats"
    case lowerLats = "Lower Lats"
    
    // MARK: - Erector Spinae
    case iliocostalis = "Iliocostalis"
    case longissimus = "Longissimus"
    case spinalis = "Spinalis"              //deep
    
    // MARK: - Scapular Stabilizers
    case teresMajor = "Teres Major"
    case teresMinor = "Teres Minor"
    case infraspinatus = "Infraspinatus"
    case rhomboids = "Rhomboids"
    case levatorScapulae = "Levator Scapulae"
    case serratusAnterior = "Serratus Anterior"
    
    
    // MARK: - Cervical Spine
    case sternocleidomastoid = "Sternocleidomastoid"
    case scalenes = "Scalenes"
    case longusColli = "Longus Colli"
    case longusCapitis = "Longus Capitis"
    
    // MARK: - Forearms
    case brachioradialis = "Brachioradialis"
    case forearmFlexors = "Forearm Flexors"
    case forearmExtensors = "Forearm Extensors"
    
    // MARK: - Quads
    case rectusFemoris = "Rectus Femoris"
    case vastusMedialis = "Vastus Medialis"
    case vastusLateralis = "Vastus Lateralis"
    
    // MARK: - Hip Flexors
    case adductors = "Adductors"
    case abductors = "Abductors"
    
    // MARK: - Hamstrings
    case medialHamstring = "Medial Hamstring"
    case lateralHamstring = "Lateral Hamstring"
    
    // MARK: - Calves
    case calvesGastrocnemius = "Calves Gastrocnemius"
    case calvesSoleus = "Calves Soleus"
    
    // MARK: - Glutes
    case gluteusMaximus = "Gluteus Maximus"
    case gluteusMedius = "Gluteus Medius"
    case gluteusMinimus = "Gluteus Minimus" // deep
    
    // Additional muscle groups as needed
    var id: String { self.rawValue }
    
    var simpleName: String {
        switch self {
        case .clavicularHead: return "Upper Chest"
        case .sternocostalHead: return "Middle Chest"
        case .costalHead: return "Lower Chest"
            
        case .tricepsLongHead, .bicepsLongHead: return "Long Head"
        case .tricepsLateralHead: return "Lateral Head"
        case .tricepsMedialHead: return "Medial Head"
            
        case .bicepsShortHead: return "Short Head"
        case .bicepsBrachialis: return "Brachialis"
            
        case .forearmFlexors: return "Flexors"
        case .forearmExtensors: return "Extensors"
            
        case .calvesGastrocnemius: return "Gastrocnemius"
        case .calvesSoleus: return "Soleus"
            
        default : return self.rawValue
        }
    }
    
    static let colorRed: Set<SubMuscles> = [
        .clavicularHead, .frontDelt, .bicepsLongHead, .tricepsLongHead, .externalObliques, .upperTraps, .upperLats, .iliocostalis, .teresMajor, .sternocleidomastoid, .brachioradialis, .rectusFemoris, .adductors, .medialHamstring, . calvesGastrocnemius, .gluteusMaximus
    ]
    
    static let colorGreen: Set<SubMuscles> = [
        .sternocostalHead, .sideDelt, .bicepsShortHead, .tricepsLateralHead, .upperAbs, .lowerTraps, .lowerLats, .longissimus, .teresMinor, .scalenes, .forearmFlexors, .vastusMedialis, .abductors, .lateralHamstring, .calvesSoleus, .gluteusMedius
    ]
    
    static let colorBlue: Set<SubMuscles> = [
        .costalHead, .rearDelt, .bicepsBrachialis, .tricepsMedialHead, .lowerAbs, .spinalis, .infraspinatus, .longusColli, .forearmExtensors, .vastusLateralis, .gluteusMinimus
    ]
    
    static let colorOrange: Set<SubMuscles> = [
        .obliques, .rhomboids, .longusCapitis
    ]
    
    static let hasFrontImages: Set<SubMuscles> = [
        .clavicularHead, .sternocostalHead, .costalHead, .upperTraps, .frontDelt, .sideDelt, .bicepsLongHead, .bicepsShortHead, .tricepsLateralHead, .upperAbs, .lowerAbs, .externalObliques, .obliques, .brachioradialis, .forearmFlexors, .forearmExtensors, .rectusFemoris, .vastusMedialis, .vastusLateralis, .adductors, .calvesSoleus, .calvesGastrocnemius, .sternocleidomastoid
    ]
    
    static let hasRearImages: Set<SubMuscles> = [
        .rearDelt, .tricepsLongHead, .tricepsMedialHead, .tricepsLateralHead, .upperTraps, .lowerTraps, .upperLats, .lowerLats, .teresMajor, .brachioradialis, .forearmExtensors, .iliocostalis, .longissimus, .medialHamstring, .lateralHamstring, .calvesSoleus, .calvesGastrocnemius, .abductors, .gluteusMaximus, .gluteusMedius
    ]
    
    static let hasBothImages: Set<SubMuscles> = hasFrontImages.intersection(hasRearImages)
    
    static let hasNoImages: Set<SubMuscles> = [
        .bicepsBrachialis, .spinalis, .gluteusMinimus,
        .teresMinor, .infraspinatus, .rhomboids, .levatorScapulae,
        .scalenes, .longusColli, .longusCapitis
    ]
    
    var detailedMuscleGroupImages: [String] {
        let basePathFront = "(M)Front_Detailed-"
        let basePathRear = "(M)Rear_Detailed-"
        let imageName = self.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
        var images: [String] = []
        
        if Self.hasFrontImages.contains(self) {
            images.append(basePathFront + imageName)
        }
        
        if Self.hasRearImages.contains(self) {
            images.append(basePathRear + imageName)
        }
        return images
    }
}

enum ExerciseName: String, Identifiable, Codable {
    // MARK: - Chest
    case benchPress = "Bench Press"
    case declineBenchPress = "Decline Bench Press"
    case dumbbellChestFly = "Dumbbell Chest Fly"
    case dumbbellBenchPress = "Dumbbell Bench Press"
    case dumbbellDeclineBenchPress = "Dumbbell Decline Bench Press"
    case dumbbellFloorPress = "Dumbbell Floor Press"
    case dumbbellPullover = "Dumbbell Pullover"
    case floorPress = "Floor Press"
    case inclineBenchPress = "Incline Bench Press"
    case inclineDumbbellBenchPress = "Incline Dumbbell Bench Press"
    case inclinePushUp = "Incline Push-Up"
    case machineChestFly = "Machine Chest Fly"
    case machineChestPress = "Machine Chest Press"
    case pushUp = "Push-Up"
    case smithMachineBenchPress = "Smith Machine Bench Press"
    case cableChestFly = "Cable Chest Fly"
    case pausedBenchPress = "Paused Bench Press"
    case reverseGripBenchPress = "Reverse Grip Bench Press"
    case benchPinPress = "Bench Pin Press"
    case declinePushUp = "Decline Push-Up"
    case diamondPushUp = "Diamond Push-Up"
    // MARK: - Shoulders
    case arnoldPress = "Arnold Press"
    case barbellFrontRaise = "Barbell Front Raise"
    case barbellUprightRow = "Barbell Upright Row"
    case dumbbellUprightRow = "Dumbbell Upright Row"
    case behindTheNeckPress = "Behind the Neck Press"
    case cableLateralRaise = "Cable Lateral Raise"
    case dumbbellFrontRaise = "Dumbbell Front Raise"
    case dumbbellLateralRaise = "Dumbbell Lateral Raise"
    case dumbbellShoulderPress = "Dumbbell Shoulder Press"
    case facePull = "Face Pull"
    case machineLateralRaise = "Machine Lateral Raise"
    case machineShoulderPress = "Machine Shoulder Press"
    case shoulderPress = "Shoulder Press"
    case pushPress = "Push Press"
    case cableReverseFly = "Cable Reverse Fly"
    case reverseDumbbellFly = "Reverse Dumbbell Fly"
    case machineReverseFly = "Machine Reverse Fly"
    case seatedDumbbellShoulderPress = "Seated Dumbbell Shoulder Press"
    case seatedShoulderPress = "Seated Shoulder Press"
    case landminePress = "Landmine Press"
    case oneArmLandminePress = "One Arm Landmine Press"
    case vikingPress = "Viking Press"
    case shoulderPinPress = "Shoulder Pin Press"
    case handstandPushUp = "Handstand Push-Up"
    // MARK: - Biceps
    case barbellCurl = "Barbell Curl"
    case preacherCurl = "Preacher Curl"
    case cableCurlWithBar = "Cable Curl With Bar"
    case dumbbellConcentrationCurl = "Dumbbell Concentration Curl"
    case dumbbellCurl = "Dumbbell Curl"
    case ezBarCurl = "EZ Bar Curl"
    case hammerCurl = "Hammer Curl"
    case inclineDumbbellCurl = "Incline Dumbbell Curl"
    case machineBicepCurl = "Machine Bicep Curl"
    case spiderCurl = "Spider Curl"
    case strictCurl = "Strict Curl"
    case oneArmCableBicepCurl = "One Arm Cable Bicep Curl"
    case oneArmDumbbellPreacherCurl = "One Arm Dumbbell Preacher Curl"
    case inclineHammerCurl = "Incline Hammer Curl"
    case zottmanCurl = "Zottman Curl"
    case seatedDumbbellCurl = "Seated Dumbbell Curl"
    case cheatCurl = "Cheat Curl"
    case cableHammerCurl = "Cable Hammer Curl"
    case overheadCableCurl = "Overhead Cable Curl"
    case inclineCableCurl = "Incline Cable Curl"
    case lyingCableCurl = "Lying Cable Curl"
    // MARK: - Triceps
    case closeGripBenchPress = "Close-Grip Bench Press"
    case dips = "Dips"
    case barbellLyingTricepsExtension = "Barbell Lying Triceps Extension"
    case benchDips = "Bench Dips"
    case closeGripPushUp = "Close-Grip Push-Up"
    case lyingDumbbellTricepsExtension = "Lying Dumbbell Triceps Extension"
    case standingDumbbellTricepsExtension = "Standing Dumbbell Triceps Extension"
    case cableOverheadTricepsExtension = "Cable Overhead Triceps Extension"
    case dumbbellTricepKickback = "Dumbbell Tricep Kickback"
    case standingBarbellTricepsExtension = "Standing Barbell Triceps Extension"
    case machineSeatedDip = "Machine Seated Dip"
    case machineTricepExtension = "Machine Tricep Extension"
    case seatedDumbbellTricepsExtension = "Seated Dumbbell Triceps Extension"
    case tricepPushdownWithBar = "Tricep Pushdown With Bar"
    case reverseGripTricepPushdown = "Reverse Grip Tricep Pushdown"
    case tricepRopePushdown = "Tricep Rope Pushdown"
    case jmPress = "JM Press"
    case tatePress = "Tate Press"
    // MARK: - Legs
    case bodyweightSquat = "Bodyweight Squat"
    case barbellHackSquat = "Barbell Hack Squat"
    case machineHackSquat = "Machine Hack Squat"
    case boxSquat = "Box Squat"
    case dumbbellSquat = "Dumbbell Squat"
    case legPress = "Leg Press"
    case pauseSquat = "Pause Squat"
    case smithMachineSquat = "Smith Machine Squat"
    case backSquat = "Back Squat"
    case zercherSquat = "Zercher Squat"
    case verticalLegPress = "Vertical Leg Press"
    case horizontalLegPress = "Horizontal Leg Press"
    case pistolSquat = "Pistol Squat"
    case reverseLunge = "Reverse Lunge"
    case sideLunge = "Side Lunge"
    case lunge = "Lunge"
    case barbellLunge = "Barbell Lunge"
    case barbellWalkingLunge = "Barbell Walking Lunge"
    case dumbbellLunge = "Dumbbell Lunge"
    // MARK: - Quads
    case beltSquat = "Belt Squat"
    case safetyBarSquat = "Safety Bar Squat"
    case frontSquat = "Front Squat"
    case gobletSquat = "Goblet Squat"
    case landmineSquat = "Landmine Squat"
    case barbellBulgarianSplitSquat = "Barbell Bulgarian Split Squat"
    case dumbbellBulgarianSplitSquat = "Dumbbell Bulgarian Split Squat"
    case legExtension = "Leg Extension"
    case cableLegExtension = "Cable Leg Extension"
    case machineHipAdduction = "Machine Hip Adduction"
    case trapBarDeadlift = "Trap Bar Deadlift"
    // MARK: - Hamstrings
    case standingLegCurl = "Standing Leg Curl"
    case seatedLegCurl = "Seated Leg Curl"
    case romanianDeadlift = "Romanian Deadlift"
    case lyingLegCurl = "Lying Leg Curl"
    case goodMorning = "Good Morning"
    case seatedCalfRaise = "Seated Calf Raise"
    case standingCalfRaise = "Standing Calf Raise"
    case barbellCalfRaise = "Barbell Calf Raise"
    case dumbbellCalfRaise = "Dumbbell Calf Raise"
    case bodyweightCalfRaise = "Bodyweight Calf Raise"
    case legPressCalfRaise = "Leg Press Calf Raise"
    case singleLegSeatedCalfRaise = "Single Leg Seated Calf Raise"
    case cablePullThrough = "Cable Pull Through"
    case dumbbellRomanianDeadlift = "Dumbbell Romanian Deadlift"
    case singleLegRomanianDeadlift = "Single Leg Romanian Deadlift"
    case gluteBridge = "Glute Bridge"
    case machineHipAbduction = "Machine Hip Abduction"
    case hipThrust = "Hip Thrust"
    case cableGluteKickbacks = "Cable Glute Kickbacks"
    // MARK: - Back
    case backExtension = "Back Extension"
    case machineBackExtension = "Machine Back Extension"
    case deadlift = "Deadlift"
    case deficitDeadlift = "Deficit Deadlift"
    case dumbbellDeadlift = "Dumbbell Deadlift"
    case pauseDeadlift = "Pause Deadlift"
    case rackPull = "Rack Pull"
    case stiffLeggedDeadlift = "Stiff-Legged Deadlift"
    case sumoDeadlift = "Sumo Deadlift"
    // MARK: - Lats
    case barbellRow = "Barbell Row"
    case chinUp = "Chin-Up"
    case pullUp = "Pull-Up"
    case neutralGripPullUp = "Neutral Grip Pull-Up"
    case muscleUp = "Muscle-Up"
    case seatedCableRow = "Seated Cable Row"
    case seatedMachineRow = "Seated Machine Row"
    case dumbbellRow = "Dumbbell Row"
    case invertedRow = "Inverted Row"
    case tBarRow = "T-Bar Row"
    case pendlayRow = "Pendlay Row"
    case latPulldown = "Lat Pulldown"
    case reverseGripLatPulldown = "Reverse Grip Lat Pulldown"
    case oneArmLatPulldown = "One-Arm Lat Pulldown"
    case straightArmLatPulldown = "Straight Arm Lat Pulldown"
    // MARK: - Traps
    case smithMachineShrug = "Smith Machine Shrug"
    case dumbbellShrug = "Dumbbell Shrug"
    case barbellShrug = "Barbell Shrug"
    // MARK: - Abs
    case abWheelRollOut = "Ab Wheel Roll-Out"
    case crunch = "Crunch"
    case hangingLegRaise = "Hanging Leg Raise"
    case hangingKneeRaise = "Hanging Knee Raise"
    case cableWoodChop = "Cable Wood Chop"
    case lyingLegRaise = "Lying Leg Raise"
    case machineSeatedCrunch = "Machine Seated Crunch"
    case mountainClimbers = "Mountain Climbers"
    case russianTwist = "Russian Twist"
    case scissorKicks = "Scissor Kicks"
    case sitUp = "Sit-Up"
    case standingCableCrunch = "Standing Cable Crunch"
    case highPulleyCrunch = "High Pulley Crunch"
    case declineCrunch = "Decline Crunch"
    case toesToBar = "Toes to Bar"
    case flutterKicks = "Flutter Kicks"
    case declineSitUp = "Decline Sit-Up"
    case cableCrunch = "Cable Crunch"
    case sideCrunch = "Side Crunch"
    // MARK: - Forearms
    case barbellWristCurl = "Barbell Wrist Curl"
    case dumbbellWristCurl = "Dumbbell Wrist Curl"
    case reverseWristCurl = "Reverse Wrist Curl"
    case barbellReverseCurl = "Barbell Reverse Curl"
    case dumbbellReverseCurl = "Dumbbell Reverse Curl"
    case dumbbellReverseWristCurl = "Dumbbell Reverse Wrist Curl"
    
    var id: String { self.rawValue }
}


enum EquipmentName: String, Identifiable, Codable {
    case dumbbells = "Dumbbells"
    case kettlebells = "Kettlebells"
    case medicineBall = "Medicine Ball"
    case barbell = "Barbell"
    case ezBar = "EZ Bar"
    case landmine = "Landmine"
    case farmersWalkHandles = "Farmer's Walk Handles"
    case trapBar = "Trap Bar"
    case pullUpBar = "Pull-Up Bar"
    case squatRack = "Squat Rack"
    case flatBench = "Flat Bench"
    case adjustableBench = "Adjustable Bench"
    case flatBenchRack = "Flat Bench Rack"
    case inclineBenchRack = "Incline Bench Rack"
    case declineBenchRack = "Decline Bench Rack"
    case verticalBench = "Vertical Bench"
    case reverseHyperextensionBench = "Reverse Hyperextension Bench"
    case preacherCurlBench = "Preacher Curl Bench"
    case backExtensionBench = "Back Extension Bench"
    case gluteHamRaiseBench = "Glute Ham Raise Bench"
    case dipBar = "Dip Bar"
    case cableCrossover = "Cable Crossover"
    case cableLatPulldown = "Cable Lat Pulldown"
    case hiLoPulleyCable = "Hi-Lo Pulley Cable"
    case cableRow = "Cable Row"
    case handleBands = "Handle Bands"
    case miniLoopBands = "Mini Loop Bands"
    case loopBands = "Loop Bands"
    case legPress = "Leg Press"
    case verticalLegPress = "Vertical Leg Press"
    case smithMachine = "Smith Machine"
    case tBarRow = "T-Bar Row"
    case hackSquat = "Hack Squat"
    case shoulderShrug = "Shoulder Shrug"
    case seatedCalfRaise = "Seated Calf Raise"
    case standingCalfRaise = "Standing Calf Raise"
    case horizontalLegPress = "Horizontal Leg Press"
    case shoulderPressMachine = "Shoulder Press Machine"
    case lyingLegCurlMachine = "Lying Leg Curl Machine"
    case standingCalfRaiseMachine = "Standing Calf Raise Machine"
    case seatedDipMachine = "Seated Dip Machine"
    case seatedLegCurlMachine = "Seated Leg Curl Machine"
    case standingLegCurlMachine = "Standing Leg Curl Machine"
    case seatedRowMachine = "Seated Row Machine"
    case backExtensionMachine = "Back Extension Machine"
    case abCrunchMachine = "Ab Crunch Machine"
    case preacherCurlMachine = "Preacher Curl Machine"
    case bicepCurlMachine = "Bicep Curl Machine"
    case chestPressMachine = "Chest Press Machine"
    case flyMachine = "Fly Machine"
    case hipAbductorMachine = "Hip Abductor Machine"
    case hipAdductorMachine = "Hip Adductor Machine"
    case legExtensionMachine = "Leg Extension Machine"
    case lateralRaiseMachine = "Lateral Raise Machine"
    case tricepDipMachine = "Tricep Dip Machine"
    case assistedWeightMachine = "Assisted Weight Machine"
    case squatMachine = "Squat Machine"
    case gluteKickbackMachine = "Glute Kickback Machine"
    case freemotionMachine = "Freemotion Machine"
    case vikingPress = "Viking Press"
    case tricepExtensionMachine = "Tricep Extension"
    case beltSquat = "Belt Squat"
    case safetySquatBar = "Safety Squat Bar"
    case abWheel = "Ab Wheel"
    case plyometricBox = "Plyometric Box"
    
    var id: String { self.rawValue }
}

enum Languages: String, Codable, CaseIterable  {
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
}

enum UnitOfMeasurement: String, Codable, CaseIterable {
    case imperial = "Imperial"
    case metric = "Metric"
    
    var desc: String {
        switch self {
        case .imperial:
            return "US Customary ( lb / in )"
        case .metric:
            return "SI System ( kg / cm )"
        }
    }
    
}

enum ProgressiveOverloadStyle: String, CaseIterable, Codable {
    case increaseWeight = "Increase Weight"
    case increaseReps = "Increase Reps"
    case decreaseReps = "Decrease Reps"
    case dynamic = "Dynamic"
    
    var desc: String {
        switch self {
        case .increaseWeight:
            return "Weight is slightly increased while reps remain the same."
        case .increaseReps:
            return "Reps are increased per week while weight remains the same. At the end of the period, reps will decrease to original values and weight will be increased."
        case .decreaseReps:
            return "Reps are decreased per week while weight is increased. At the end of the period, reps will increase to orgininal values and weight will be decreased to accomodate the increased reps."
        case .dynamic:
            return "Reps will be increased each week. Once halfway through period, reps will return to original value and weight will be increased slightly. For remainder of weeks, reps will remain the same while weight increases."
        }
    }
    
    static func applyProgressiveOverload(exercise: Exercise, period: Int, style: ProgressiveOverloadStyle, roundingPreference: [EquipmentCategory: Double], equipmentData: EquipmentData) -> [SetDetail] {
        let usesWeight = exercise.usesWeight
        let equipment = exercise.equipmentRequired
        let setDetails = exercise.setDetails
        let progress = exercise.overloadProgress
        var updatedSetDetails = setDetails
        
        for (index, setDetail) in setDetails.enumerated() {
            var updatedSetDetail = setDetail
            
            if !usesWeight {
                // increase reps
                updatedSetDetail.reps += progress // Increment reps based on progress
                
            } else {
                switch style {
                case .increaseWeight:
                    // Increase weight while keeping reps constant
                    updatedSetDetail.weight += Double(progress) * 2.5 // Add 2.5 units per week of progress
                    updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    
                case .increaseReps:
                    // Increase reps while keeping weight constant
                    updatedSetDetail.reps += progress // Increment reps based on progress
                    
                case .decreaseReps:
                    // Decrease reps and increase weight
                    updatedSetDetail.reps = max(1, updatedSetDetail.reps - progress) // Decrease reps (minimum of 1)
                    updatedSetDetail.weight += Double(progress) * 2.5 // Add 2.5 units per week of progress
                    updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    
                case .dynamic:
                    let halfwayPoint = period / 2
                    if progress <= halfwayPoint {
                        // First half: Increase reps
                        updatedSetDetail.reps += progress
                    } else {
                        // Second half: Reset reps, increase weight
                        let adjustedProgress = progress - halfwayPoint
                        updatedSetDetail.reps = setDetail.reps // Reset reps to original value
                        updatedSetDetail.weight += Double(adjustedProgress) * 2.5 // Increase weight
                        updatedSetDetail.weight = equipmentData.roundWeight(updatedSetDetail.weight, for: equipment, roundingPreference: roundingPreference) // Round weight
                    }
                }
            }
            updatedSetDetails[index] = updatedSetDetail
        }
        
        return updatedSetDetails
    }
}

enum Themes: String, CaseIterable, Codable {
    case lightMode = "Light Mode"
    case darkMode = "Dark Mode"
    case defaultMode = "Default Mode" // uses device settings
}

enum SetStructures: String, CaseIterable, Codable, Identifiable {
    case pyramid = "Pyramid" // default: start with lowest weight and increase per set
    case reversePyramid = "Reverse Pyramid" // start with highest weight and decrease per set
    case fixed = "Fixed" // same weight and reps across all sets
    
    var id: String { self.rawValue }
    
    var desc: String {
        switch self {
        case .pyramid:
            return "Start with lighter weight and higher reps, increasing weight while decreasing reps for each subsequent set."
        case .reversePyramid:
            return "Start with heavier weight and lower reps, decreasing weight while increasing reps for each subsequent set."
        case .fixed:
            return "Same weight and reps across all sets."
        }
    }
}

enum StrengthLevel: String, CaseIterable, Codable {
    case beginner = "Beg."
    case novice = "Nov."
    case intermediate = "Int."
    case advanced = "Adv."
    case elite = "Elite"
    
    var strengthValue: Int {
        switch self {
        case .beginner: return 0
        case .novice: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .elite: return 4
        }
    }
    var percentile: Double {
        switch self {
        case .beginner: return 0.2
        case .novice: return 0.5
        case .intermediate: return 0.8
        case .advanced: return 0.95
        case .elite: return 1.0
        }
    }
    static func getLevelForScore(level: Int) -> String {
        switch level {
        case 1: return beginner.rawValue
        case 2: return novice.rawValue
        case 3: return intermediate.rawValue
        case 4: return advanced.rawValue
        case 5: return elite.rawValue
        default:
            return "Unknown"
        }
        
    }
}

enum MeasurementType: String, Codable, CaseIterable, Identifiable, Hashable {
    case weight = "Weight"
    case bodyFatPercentage = "Body Fat Percentage"
    case caloricIntake = "Caloric Intake"
    case bmi = "BMI"
    case neck = "Neck"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case leftBicep = "Left Bicep"
    case rightBicep = "Right Bicep"
    case leftForearm = "Left Forearm"
    case rightForearm = "Right Forearm"
    case upperAbs = "Upper Abs"
    case waist = "Waist"
    case lowerAbs = "Lower Abs"
    case hips = "Hips"
    case leftThigh = "Left Thigh"
    case rightThigh = "Right Thigh"
    case leftCalf = "Left Calf"
    case rightCalf = "Right Calf"
    
    var id: String { rawValue }
    
    static let coreMeasurements: [MeasurementType] = [
        .weight, .bodyFatPercentage, .caloricIntake, .bmi
    ]
    
    static let bodyPartMeasurements: [MeasurementType] = [
        .neck, .shoulders, .chest, .leftBicep, .rightBicep,
        .leftForearm, .rightForearm, .upperAbs, .waist,
        .lowerAbs, .hips, .leftThigh, .rightThigh, .leftCalf,
        .rightCalf
    ]
    
    var unitLabel: String? {
        switch self {
        case .weight:
            return "lb"
        case .bodyFatPercentage:
            return "%"
        case .caloricIntake:
            return "kcal"
        case .bmi:
            return nil
        default:
            return "in"
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle = "Build Muscle"
    case getStronger = "Get Stronger"
    case buildMuscleGetStronger = "Build Muscle and Get Stronger"
    // case improveEndurance = "Improve Endurance"  // New goal
    
    var name: String {
        switch self {
        case .buildMuscle:
            return "Build Muscle"
        case .getStronger:
            return "Get Stronger"
        case .buildMuscleGetStronger:
            return "Build Muscle & Get Stronger"
            /* case .improveEndurance:
             return "Improve Endurance"*/
        }
    }
    
    static func determineRestPeriod(for goal: FitnessGoal) -> Int {
        switch goal {
        case .buildMuscle:
            return 60 // 60 for isolation, 90 for compound
        case .getStronger:
            return 120 // 180 for isolation, 240 for compound
        case .buildMuscleGetStronger:
            return 90 // 120 for isolation, 180 for compound
            /* case .improveEndurance:
             return 30*/
        }
    }
    
    static func getRepsAndSets(for goal: FitnessGoal, restPeriod: Int) -> RepsAndSets {
        switch goal {
        case .buildMuscle:
            // Hypertrophy: Higher volume, moderate rest, high intensity
            return RepsAndSets(repsRange: 8...12, sets: 5, restPeriod: restPeriod) // 4 sets for isolation, 5 for compound
        case .getStronger:
            // Strength: Lower reps, more sets, longer rest, very high intensity
            return RepsAndSets(repsRange: 3...6, sets: 3, restPeriod: restPeriod) // 3 sets for isolation, 4 for compound
        case .buildMuscleGetStronger:
            // Hybrid: Blend of hypertrophy and strength, moderate reps, variable sets, moderate rest
            return RepsAndSets(repsRange: 6...10, sets: 4, restPeriod: restPeriod) // 4 sets for all?
            /* case .improveEndurance:
             return RepsAndSets(repsRange: 12...20, sets: 3, restPeriod: restPeriod)*/
        }
    }
    
    var detailDescription: String {
        switch self {
        case .buildMuscle:
            return "Reps: 8-12, Sets: 3, Rest: 60s"
            //return "Reps: \(self.repsAndSets), Sets: 3, Rest: 60s"
        case .getStronger:
            return "Reps: 3-6, Sets: 5, Rest: 120s"
        case .buildMuscleGetStronger:
            return "Reps: 6-10, Sets: 4, Rest: 90s"
            /*case .improveEndurance:
             return "Reps: 12-20, Sets: 3, Rest: 30s"*/
        }
    }
    
    var shortDescription: String {
        switch self {
        case .buildMuscle:
            return "Hypertrophy focused"
        case .getStronger:
            return "Strength focused"
        case .buildMuscleGetStronger:
            return "Hybrid focus"
            /*   case .improveEndurance:
             return "Endurance focused"*/
        }
    }
}


enum Gender: Hashable, Codable {
    case male, female
}


enum OneRepMaxFormula {
    case epleys, landers
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case select = "Select"
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly active"
    case moderatelyActive = "Moderately active"
    case veryActive = "Very active"
    case superActive = "Super active"
    
    var id: String { self.rawValue }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .superActive: return 1.9
        case .select: return 1.0 // Default value for 'select', though it might not be used
        }
    }
    
    var estimatedSteps: Int {
        switch self {
        case .sedentary: return 3000
        case .lightlyActive: return 5000
        case .moderatelyActive: return 7500
        case .veryActive: return 10000
        case .superActive: return 12500
        case .select: return 0
        }
    }
    
    var description: String {
        switch self {
        case .sedentary:
            return "Spend most of the day sitting (i.e. desk job)"
        case .lightlyActive:
            return "Spend a good part of the day on my feet (e.g. teacher or cashier)"
        case .moderatelyActive:
            return "Spend a good part of the day doing moderate physical activity (e.g. server/food runner or parcel driver)"
        case .veryActive:
            return "Spend a good part of the day doing heavy physical activities (e.g. construction worker or mover)"
        case .superActive:
            return "Spend most of the day doing intense physical activity (e.g. professional athlete or training for a marathon)"
        case .select:
            return ""
        }
    }
}

enum EquipmentCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    case smallWeights = "Small Weights" // dumbbells
    case barsPlates = "Bars & Plates"
    case benchesRacks = "Benches & Racks"
    case cableMachines = "Cable Machines" //
    case resistanceBands = "Resistance Bands"
    case platedMachines = "Plated Machines" //
    case weightMachines = "Weight Machines" //
    case other = "Other"
    
    var id: String { self.rawValue }
    
    // Function to concatenate EquipmentCategory names
    static func concatenateEquipCategories(for categories: [EquipmentCategory]) -> String {
        return categories.map { $0.rawValue }.joined(separator: ", ")
    }
}

enum LimbMovementType: String, Codable {
    case unilateral = "Unilateral" // One limb working at a time (e.g., glute kickbacks)
    case bilateralIndependent = "Bilateral Independent" // Both limbs work separately but simultaneously (e.g., dumbbell shoulder press)
    case bilateralDependent = "Bilateral Dependent" // Both limbs work together (e.g., bench press, squat)
    
    var description: String {
        switch self {
        case .unilateral:
            return "One limb working at a time" // would say 'per arm' or 'per leg' in caption font around the reps text
        case .bilateralIndependent:
            return "Both limbs working independently but simultaneously" // would say 'per arm' or 'per leg' in caption font around the weight text
        case .bilateralDependent:
            return "Both limbs working together at the same time"
        }
    }
}


enum ExerciseDistinction: String, CaseIterable, Identifiable, Codable {
    case compound = "Compound"
    case isolation = "Isolation"
    case cardio = "Cardio"
    
    var id: String { self.rawValue }
}

enum ExerciseDifficulty: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case novice = "Novice"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
    
    var id: String { self.rawValue }
    
    static let difficultyValue: [ExerciseDifficulty: Int] = [
        .beginner: 0,
        .novice: 1,
        .intermediate: 2,
        .advanced: 3,
        .elite: 4
    ]
    
    static func getDifficultyValue(for category: ExerciseDifficulty) -> Int {
        return difficultyValue[category] ?? 0
    }
}

enum daysOfWeek: String, CaseIterable, Codable, Comparable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    // map these to the 1-based weekday that Calendar uses
    /*var calendarWeekday: Int {
        switch self {
        case .monday:    return 2
        case .tuesday:   return 3
        case .wednesday: return 4
        case .thursday:  return 5
        case .friday:    return 6
        case .saturday:  return 7
        case .sunday:    return 1
        }
    }*/
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    // Explicitly define the order of the week days
    static let orderedDays: [daysOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    // Implement custom comparison method for sorting
    static func < (lhs: daysOfWeek, rhs: daysOfWeek) -> Bool {
        return orderedDays.firstIndex(of: lhs)! < orderedDays.firstIndex(of: rhs)!
    }
    
    static func defaultDays(for workoutDaysPerWeek: Int) -> [daysOfWeek] {
        switch workoutDaysPerWeek {
        case 3:
            return [.monday, .wednesday, .friday]  // Typical three-day split
        case 4:
            return [.monday, .tuesday, .thursday, .friday]  // Typical four-day split
        case 5:
            return [.monday, .tuesday, .wednesday, .thursday, .friday]  // Typical five-day split
        case 6:
            return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]  // Typical six-day split
        default:
            // Default to the number of days evenly distributed
            return Array(orderedDays.prefix(workoutDaysPerWeek))
        }
    }
    static func getWorkoutDayIndexes(for frequency: Int) -> [Int] {
        // Default days calculation based on frequency
        switch frequency {
        case 3:
            return [0, 2, 4]  // Monday, Wednesday, Friday
        case 4:
            return [0, 1, 3, 4]  // Monday, Tuesday, Thursday, Friday
        case 5:
            return [0, 1, 2, 3, 4]  // Monday to Friday
        case 6:
            return [0, 1, 2, 3, 4, 5]  // Monday to Saturday
        default:
            return []
        }
    }
    
    static func calculateWorkoutDayIndexes(customWorkoutDays: [daysOfWeek]?, workoutDaysPerWeek: Int) -> [Int] {
        if let customDays = customWorkoutDays, !customDays.isEmpty {
            // Use custom workout days if they are set
            return customDays.compactMap { daysOfWeek.orderedDays.firstIndex(of: $0) }
        } else {
            // Fallback to default indexes if no custom days are set
            return getWorkoutDayIndexes(for: workoutDaysPerWeek)
        }
    }
    
    // When the user wants to start the week on a different day (e.g., Sunday)
    /*static func orderedDays(startingOn firstDay: daysOfWeek) -> [daysOfWeek] {
        let allDays = orderedDays  // the static default [mon, tue, wed...]
        guard let firstIndex = allDays.firstIndex(of: firstDay) else {
            return allDays
        }
        // Rotate the array so that `firstDay` is at index 0
        let head = allDays[firstIndex...]
        let tail = allDays[..<firstIndex]
        return Array(head + tail)
    }
    
    static func currentOrderedDays(for startDay: daysOfWeek) -> [daysOfWeek] {
        // rotate so that startDay is first
        let base = orderedDays
        guard let idx = base.firstIndex(of: startDay) else { return base }
        return Array(base[idx...] + base[..<idx])
    }
    
    static func defaultDays(for workoutDaysPerWeek: Int, startingOn firstDay: daysOfWeek) -> [daysOfWeek] {
        let reordered = orderedDays(startingOn: firstDay)  // e.g. Sunday->Saturday
        // Now pick the days
        switch workoutDaysPerWeek {
        case 3:
            // For a 3-day split, you want the 0th, 2nd, and 4th from the reordered array
            // if you want them spaced the same way as you originally did (Mon, Wed, Fri).
            return [reordered[0], reordered[2], reordered[4]]
        case 4:
            return [reordered[0], reordered[1], reordered[3], reordered[4]]
        case 5:
            return [reordered[0], reordered[1], reordered[2], reordered[3], reordered[4]]
        case 6:
            return [reordered[0], reordered[1], reordered[2], reordered[3], reordered[4], reordered[5]]
        default:
            return Array(reordered.prefix(workoutDaysPerWeek))
        }
    }

    static func calculateWorkoutDayIndexes(customWorkoutDays: [daysOfWeek]?, workoutDaysPerWeek: Int, startDay: daysOfWeek) -> [Int] {
        // 1) Create the reordered array of days
        let reordered = orderedDays(startingOn: startDay)
        
        // 2) If the user has custom days selected, find each day’s index in the reordered array
        if let customDays = customWorkoutDays, !customDays.isEmpty {
            return customDays.compactMap { day in
                reordered.firstIndex(of: day)
            }
        } else {
            // 3) No custom days => fallback to your original “3-day/4-day” logic
            //    But these indexes are now referencing the reordered array.
            let indexes: [Int]
            switch workoutDaysPerWeek {
            case 3:
                // [0,2,4] means: use the 0th, 2nd, 4th days in the *reordered* array
                indexes = [0, 2, 4]
            case 4:
                indexes = [0, 1, 3, 4]
            case 5:
                indexes = [0, 1, 2, 3, 4]
            case 6:
                indexes = [0, 1, 2, 3, 4, 5]
            default:
                indexes = []
            }
            
            // 4) Return those indexes as-is, meaning day #0 is `reordered[0]`, day #2 is `reordered[2]`, etc.
            return indexes
        }
    }*/
}

enum GraphView: String, Identifiable, Codable, CaseIterable {
    case exercisePerformance = "Exercise Performance"
    case bodyMeasurements = "Body Measurements"
    
    var id: String { self.rawValue }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case month = "month"
    case sixMonths = "6 months"
    case year = "year"
    case allTime = "all time"
    
    var id: String { rawValue }
}

enum RestTimerSetType: String, CaseIterable, Identifiable {
    case warmUp = "Warm-up Sets"
    case working = "Working Sets"
    
    var id: String { rawValue }
}


// New enum to handle different adjustment values
enum AdjustmentValue: Codable, Equatable, Hashable {
    case integer(Int)
    case string(String)
    
    var displayValue: String {
        switch self {
        case .integer(let value):
            return "\(value)"
        case .string(let value):
            return value
        }
    }
    
    static func from(_ stringValue: String) -> AdjustmentValue {
        if let intValue = Int(stringValue) {
            return .integer(intValue)
        } else {
            return .string(stringValue)
        }
    }
}

enum AdjustmentCategories: String, CaseIterable, Identifiable, Codable, Comparable, Hashable {
    case seatHeight = "Seat Height"
    case benchAngle = "Bench Angle"
    
    case rackHeight = "Rack Height"
    case pulleyHeight = "Pulley Height"
    
    case padHeight = "Pad Height"
    
    //case seatDepth = "Seat Depth"
    case backPadDepth = "Back Pad Depth"
    
    case footPlateHeight = "Foot Plate Height"
    
    case legPadPosition = "Leg Pad Position"
    
    
    case sundialAdjustment = "Sundial Adjustment"
    
    case handlePosition = "Handle Position"
    
    
    var id: String { self.rawValue }
    
    var image: String {
        // Construct the image name using the raw value and base path
        let basePath = "Adjustments/"
        // Replace spaces with underscores for the image file names
        let formattedName = self.rawValue.replacingOccurrences(of: " ", with: "_")
        return basePath + formattedName
    }
    
    
    static func < (lhs: AdjustmentCategories, rhs: AdjustmentCategories) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum SetupState: Codable {
    case welcomeView
    case healthKitView
    case detailsView
    case goalView
    case finished
}
