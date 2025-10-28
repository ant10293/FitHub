//
//  MuscleTypes.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation

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
    case calves = "Calves" // accessory
    case forearms = "Forearms" // accessory
    case cervicalSpine = "Cervical Spine" // accessory - neck
    case adductors = "Adductors"
    case abductors = "Abductors"
    case tibialis = "Tibialis"
    
    var id: String { self.rawValue }
}

extension Muscle {
    private var shortName: String {
        switch self {
        case .abdominals: return "Abs"
        case .pectorals: return "Pecs"
        case .deltoids: return "Delts"
        case .trapezius: return "Traps"
        case .latissimusDorsi: return "Lats"
        case .erectorSpinae: return "Erectors"
        case .quadriceps: return "Quads"
        case .gluteus: return "Glutes"
        default: return self.rawValue
        }
    }
    
    var simpleName: String {
        switch self {
        case .pectorals: return "Chest"
        case .deltoids: return "Shoulders"
        case .erectorSpinae: return "Lower Back"
        case .cervicalSpine: return "Neck"
        default: return self.shortName
        }
    }
}

extension Muscle {
    static let SubMuscles: [Muscle: [SubMuscles]] = [
        .abdominals: [.upperAbs, .lowerAbs, .obliques, .externalObliques, .transverseAbdominis],
        .pectorals: [.clavicularHead, .sternocostalHead, .costalHead],
        .deltoids: [.frontDelt, .sideDelt, .rearDelt],
        .biceps: [.bicepsLongHead, .bicepsShortHead, .brachialis],
        .triceps: [.tricepsLongHead, .tricepsLateralHead, .tricepsMedialHead],
        .trapezius: [.upperTraps, .middleTraps, .lowerTraps],
        .erectorSpinae: [.iliocostalis, .longissimus, .spinalis],
        .forearms: [.brachioradialis, .forearmFlexors, .forearmExtensors, .forearmRotators],
        .quadriceps: [.rectusFemoris, .vastusMedialis, .vastusLateralis, .vastusIntermedius],
        .hamstrings: [.semitendinosus, .semimembranosus, .bicepsFemoris],
        .gluteus: [.gluteusMaximus, .gluteusMedius, .gluteusMinimus],
        .calves: [.gastrocnemius, .soleus, .plantaris],
        .tibialis: [.tibialisAnterior, .tibialisPosterior],
        .cervicalSpine: [.infrahyoid, .sternocleidomastoid, .scalenes, .longusFlexors]
    ]
    
    static func getSubMuscles(for category: Muscle) -> [SubMuscles] {
        return SubMuscles[category] ?? []
    }
}

extension Muscle {
    /*
    static let hasFrontImages: Set<Muscle> = [
        .all, .abdominals, .pectorals, .trapezius, .deltoids, .biceps, .triceps, .quadriceps, .calves, .forearms, .cervicalSpine, .hipComplex
    ]
    
    static let hasRearImages: Set<Muscle> = [
        .all, .deltoids, .triceps, .trapezius, .latissimusDorsi, .erectorSpinae, .hamstrings, .gluteus, .calves, .forearms, .scapularRetractors
    ]
    
    static let hasBothImages: Set<Muscle> = hasFrontImages.intersection(hasRearImages)
    
    static func getButtonForCategory(_ category: Muscle, gender: Gender) -> Image {
        let startPath = "Button/\(gender == .male ? "Male" : "Female")/"
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-")
        let fullPath = startPath + imageName
        return Image(fullPath)
    }
    */
    
    var splitCategory: SplitCategory? { SplitCategory.muscles.first { _, muscles in muscles.contains(self) }?.key }
    
    /// Returns the parent SplitCategory for this muscle.
    /// - Parameter forGeneration: If true, uses the generation map (no calves/forearms).
    func groupCategory(forGeneration: Bool = false) -> SplitCategory? {
        let map = SplitCategory.groups(forGeneration: forGeneration)
        return map.first(where: { $0.value.contains(self) })?.key
    }
}

