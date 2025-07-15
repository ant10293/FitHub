//
//  MuscleTypes.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI



struct SubMuscleEngagement: Hashable, Codable {
    var submuscleWorked: SubMuscles
    var engagementPercentage: Double
}

struct MuscleEngagement: Hashable, Codable {
    var muscleWorked: Muscle
    var engagementPercentage: Double
    var isPrimary: Bool
    var submusclesWorked: [SubMuscleEngagement]?
}
extension MuscleEngagement {
    /// Returns a list of SubMuscles for the muscle engagement, or an empty array if `submusclesWorked` is nil.
    var allSubMuscles: [SubMuscles] {
        submusclesWorked?.map { $0.submuscleWorked } ?? []
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
    case lumbarStabilizers = "Lumbar Stabilizers"   // accessory
    case hipComplex = "Hip Complex" // accessory
    case deepHipRotators = "Deep Hip Rotators"
    case scapularRetractors = "Scapular Retractors" // accessory
    case rotatorCuff = "Rotator Cuff"
    case calves = "Calves" // accessory
    case forearms = "Forearms" // accessory
    case cervicalSpine = "Cervical Spine" // accessory - neck
    case tibialis = "Tibialis"
    case peroneals = "Peroneals"   // or "Fibularis Group"
    case serratus = "Serratus"
    
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
        case .lumbarStabilizers: return "Lumbar"
        case .hipComplex: return "Hips"
        case .scapularRetractors: return "Scapular"
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
    
    // Property to check if the muscle should be included
    var isVisible: Bool {
        switch self {
        case .all, .scapularRetractors, .lumbarStabilizers, .hipComplex, .deepHipRotators, .rotatorCuff, .tibialis, .peroneals, .serratus:
            return false
        default:
            return true
        }
    }
    
    /*
    static let Groups: [SplitCategory: [Muscle]] = [
           .arms: [.biceps, .triceps, .forearms],
           .legs: [.hipComplex, .quadriceps, .hamstrings, .gluteus, .calves, .tibialis],
           .back: [.trapezius, .latissimusDorsi, .erectorSpinae, .scapularStabilizers]
    ]
     */
    
    static let SubMuscles: [Muscle: [SubMuscles]] = [
        .abdominals: [.upperAbs, .lowerAbs, .obliques, .externalObliques, .transverseAbdominis],
        .pectorals: [.clavicularHead, .sternocostalHead, .costalHead],
        .deltoids: [.frontDelt, .sideDelt, .rearDelt],
        .biceps: [.bicepsLongHead, .bicepsShortHead, .bicepsBrachialis],
        .triceps: [.tricepsLongHead, .tricepsLateralHead, .tricepsMedialHead],
        .trapezius: [.upperTraps, .middleTraps, .lowerTraps],
        .latissimusDorsi: [.upperLats, .lowerLats, .teresMajor],
        .erectorSpinae: [.iliocostalis, .longissimus, .spinalis, .multifidus, .quadratusLumborum],
        .forearms: [.brachioradialis, .forearmFlexors, .forearmExtensors, .forearmRotators],
        .cervicalSpine: [.infrahyoid, .sternocleidomastoid, .scalenes, .longusFlexors],
        .lumbarStabilizers: [.multifidus, .quadratusLumborum],
        .hipComplex: [.adductors, .abductors, .iliopsoas, .sartorius, .tensorFasciaeLatae],
        .deepHipRotators: [.piriformis, .obturators, .gemelli, .quadratusFemoris],
        .scapularRetractors: [.rhomboids, .levatorScapulae],
        .rotatorCuff: [.supraspinatus, .infraspinatus, .teresMinor, .subscapularis],
        .quadriceps: [.rectusFemoris, .vastusMedialis, .vastusLateralis, .vastusIntermedius],
        .hamstrings: [.semitendinosus, .semimembranosus, .bicepsFemoris],
        .gluteus: [.gluteusMaximus, .gluteusMedius, .gluteusMinimus],
        .calves: [.calvesGastrocnemius, .calvesSoleus, .plantaris],
        .tibialis: [.tibialisAnterior, .tibialisPosterior],
        .peroneals: [.peroneusLongus, .peroneusBrevis, .peroneusTertius],
        .serratus: [.serratusAnterior, .serratusPosteriorSuperior, .serratusPosteriorInferior]
    ]
    
    static func getSubMuscles(for category: Muscle) -> [SubMuscles] {
        return SubMuscles[category] ?? []
    }
    
    static let hasFrontImages: Set<Muscle> = [
        .all, .abdominals, .pectorals, .trapezius, .deltoids, .biceps, .triceps, .quadriceps, .calves, .forearms, .cervicalSpine, .hipComplex
    ]
    
    static let hasRearImages: Set<Muscle> = [
        .all, .deltoids, .triceps, .trapezius, .latissimusDorsi, .erectorSpinae, .hamstrings, .gluteus, .calves, .forearms, .scapularRetractors
    ]
    
    static let hasBothImages: Set<Muscle> = hasFrontImages.intersection(hasRearImages)
}

extension Muscle {
    static func getButtonForCategory(_ category: Muscle, gender: Gender) -> Image {
        let startPath = "Button/\(gender == .male ? "Male" : "Female")/"
        let imageName = category.rawValue.replacingOccurrences(of: " ", with: "-")
        let fullPath = startPath + imageName
        return Image(fullPath)
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
    case upperAbs = "Upper Abs"
    case lowerAbs = "Lower Abs"
    case obliques = "Obliques"
    case externalObliques = "External Obliques"
    case transverseAbdominis = "Transverse Abdominis"
    
    // MARK: - Traps
    case upperTraps = "Upper Traps"
    case middleTraps = "Middle Traps"
    case lowerTraps = "Lower Traps"
    
    // MARK: - Lats
    case upperLats = "Upper Lats"
    case lowerLats = "Lower Lats"
    case teresMajor = "Teres Major"
    
    // MARK: - Erector Spinae
    case iliocostalis = "Iliocostalis"
    case longissimus = "Longissimus"
    case spinalis = "Spinalis" // deep
    
    // MARK: - Scapular Retractors
    case rhomboids = "Rhomboids"
    case levatorScapulae = "Levator Scapulae"
    
    // MARK: - Rotator Cuff
    case supraspinatus = "Supraspinatus"
    case infraspinatus = "Infraspinatus"
    case teresMinor = "Teres Minor"
    case subscapularis = "Subscapularis"
    
    // MARK: - Cervical Spine
    case infrahyoid = "Infrahyoid" // sternohyoid, sternothyoid, thryohyoid, omohyoid
    case sternocleidomastoid = "Sternocleidomastoid"
    case scalenes = "Scalenes" // anterior, middle, posterior
    case longusFlexors = "Longus Flexors" // longus colli, longus capitus
    
    // MARK: - Forearms
    case brachioradialis = "Brachioradialis"
    case forearmFlexors = "Forearm Flexors"
    case forearmExtensors = "Forearm Extensors"
    case forearmRotators = "Forarm Rotators" // Pronator Teres & Supinator
    
    // MARK: - Quads
    case rectusFemoris = "Rectus Femoris"
    case vastusMedialis = "Vastus Medialis"
    case vastusLateralis = "Vastus Lateralis"
    case vastusIntermedius = "Vastus Intermedius" 
        
    // MARK: – Lumbar Stabilizers
    case multifidus = "Multifidus"
    case quadratusLumborum = "Quadratus Lumborum"
    
    // MARK: - Hip Complex
    case adductors = "Adductors"
    case abductors = "Abductors"
    case iliopsoas = "Iliopsoas"
    case sartorius = "Sartorius"
    case tensorFasciaeLatae = "Tensor Fasciae Latae"
    
    // MARK: – Deep Hip Rotators
    case piriformis = "Piriformis"
    case obturators = "Obturators" // Obturator Internus & Externus
    case gemelli = "Gemelli" // Superior & Inferior Gemellus
    case quadratusFemoris = "Quadratus Femoris"
    
    // MARK: - Hamstrings
    case semitendinosus = "Semitendinosus" // medial
    case semimembranosus = "Semimembranosus" // medial
    case bicepsFemoris = "Biceps Femoris" // lateral
    
    // MARK: - Calves
    case calvesGastrocnemius = "Calves Gastrocnemius"
    case calvesSoleus = "Calves Soleus"
    case plantaris = "Plantaris"
    
    // MARK: - Glutes
    case gluteusMaximus = "Gluteus Maximus"
    case gluteusMedius = "Gluteus Medius"
    case gluteusMinimus = "Gluteus Minimus" // deep
    
    // MARK: - Tibialis
    case tibialisAnterior = "Tibialis Anterior"
    case tibialisPosterior = "Tibialis Posterior"
    
    // MARK: - Peroneals
    case peroneusLongus = "Peroneus Longus"
    case peroneusBrevis = "Peroneus Brevis"
    case peroneusTertius = "Peroneus Tertius" // optional
    
    // MARK: - Serratus
    case serratusAnterior = "Serratus Anterior"
    case serratusPosteriorSuperior = "Serratus Posterior Superior"
    case serratusPosteriorInferior = "Serratus Posterior Inferior"

    
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
            
        case .tensorFasciaeLatae: return "TFL"
            
        case .forearmFlexors: return "Flexors"
        case .forearmExtensors: return "Extensors"
            
       // case .semitendinosus, .semimembranosus: return "Lateral Hamstring"
        case .bicepsFemoris: return "Medial Hamstring"
            
        case .calvesGastrocnemius: return "Gastrocnemius"
        case .calvesSoleus: return "Soleus"
            
        default : return self.rawValue
        }
    }
    
    var note: String? {
        switch self {
        case .infrahyoid:
            return "Includes four midline strap muscles: sternohyoid, sternothyroid, thyrohyoid, and omohyoid."
        case .scalenes:
            return "Three lateral neck muscles (anterior, middle, posterior) that stabilize and laterally flex the cervical spine."
        case .longusFlexors:
            return "Deep prevertebral flexors: longus colli and longus capitis, key for neck flexion and stabilization."
        case .teresMajor:
            return "A humeral adductor/internal rotator (the “little lat”), often trained alongside latissimus dorsi."
        default:
            return nil
        }
    }
    
    static let colorRed: Set<SubMuscles> = [
        .clavicularHead, .frontDelt, .bicepsLongHead, .tricepsLongHead, .upperAbs, .upperTraps, .upperLats, .iliocostalis, .infrahyoid, .brachioradialis, .rectusFemoris, .adductors, .bicepsFemoris, .calvesGastrocnemius, .gluteusMaximus
    ]
    
    static let colorGreen: Set<SubMuscles> = [
        .sternocostalHead, .sideDelt, .bicepsShortHead, .tricepsLateralHead, .lowerAbs, .lowerTraps, .lowerLats, .longissimus, .sternocleidomastoid, .forearmFlexors, .vastusMedialis, .abductors, .semitendinosus, .semimembranosus, .calvesSoleus, .gluteusMedius
    ]
    
    static let colorBlue: Set<SubMuscles> = [
        .costalHead, .rearDelt, .bicepsBrachialis, .tricepsMedialHead, .obliques, .teresMajor, .spinalis, .infraspinatus, .forearmExtensors, .vastusLateralis, .gluteusMinimus
    ]
    
    static let colorYellow: Set<SubMuscles> = [
        .externalObliques, .rhomboids, .longusFlexors
    ]
    
    static let hasFrontImages: Set<SubMuscles> = [
        .clavicularHead, .sternocostalHead, .costalHead, .upperTraps, .frontDelt, .sideDelt, .bicepsLongHead, .bicepsShortHead, .tricepsLateralHead, .upperAbs, .lowerAbs, .externalObliques, .obliques, .brachioradialis, .forearmFlexors, .forearmExtensors, .rectusFemoris, .vastusMedialis, .vastusLateralis, .adductors, .calvesSoleus, .calvesGastrocnemius, .infrahyoid
    ]
    
    static let hasRearImages: Set<SubMuscles> = [
        .rearDelt, .tricepsLongHead, .tricepsMedialHead, .tricepsLateralHead, .upperTraps, .lowerTraps, .upperLats, .lowerLats, .teresMajor, .brachioradialis, .forearmExtensors, .iliocostalis, .longissimus, .semitendinosus, .semimembranosus, .bicepsFemoris, .calvesSoleus, .calvesGastrocnemius, .abductors, .gluteusMaximus, .gluteusMedius
    ]
    
    static let hasBothImages: Set<SubMuscles> = hasFrontImages.intersection(hasRearImages)
    
    static let hasNoImages: Set<SubMuscles> = [
        .bicepsBrachialis, .spinalis, .gluteusMinimus,
        .teresMinor, .infraspinatus, .rhomboids, .levatorScapulae,
        .sternocleidomastoid, .scalenes, .longusFlexors
    ]
}
