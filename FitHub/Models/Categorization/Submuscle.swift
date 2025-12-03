//
//  Submuscle.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/14/25.
//

import Foundation


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
    case brachialis = "Brachialis" // deep
    
    // MARK: - Triceps
    case tricepsLongHead = "Triceps Long Head"
    case tricepsLateralHead = "Triceps Lateral Head"
    case tricepsMedialHead = "Triceps Medial Head"
    
    // MARK: - Abs
    case upperAbs = "Upper Abs"
    case lowerAbs = "Lower Abs"
    case obliques = "Obliques"
    case transverseAbdominis = "Transverse Abdominis"
    case serratusAnterior = "Serratus Anterior"
    
    // MARK: - Traps
    case upperTraps = "Upper Traps"
    case middleTraps = "Middle Traps"
    case lowerTraps = "Lower Traps"
    case rhomboids = "Rhomboids"
    
    // MARK: - Erector Spinae
    case iliocostalis = "Iliocostalis"
    case longissimus = "Longissimus"
    case spinalis = "Spinalis" // deep
    
    // MARK: - Cervical Spine
    case infrahyoid = "Infrahyoid" // sternohyoid, sternothyoid, thryohyoid, omohyoid
    case sternocleidomastoid = "Sternocleidomastoid"
    case scalenes = "Scalenes" // anterior, middle, posterior
    case longusFlexors = "Longus Flexors" // longus colli, longus capitus
    
    // MARK: - Forearms
    case brachioradialis = "Brachioradialis"
    case forearmFlexors = "Forearm Flexors"
    case forearmExtensors = "Forearm Extensors"
    case forearmRotators = "Forearm Rotators" // Pronator Teres & Supinator
    
    // MARK: - Quads
    case rectusFemoris = "Rectus Femoris"
    case vastusMedialis = "Vastus Medialis"
    case vastusLateralis = "Vastus Lateralis"
    case vastusIntermedius = "Vastus Intermedius"
    
    // MARK: - Hamstrings
    case semitendinosus = "Semitendinosus" // medial
    case semimembranosus = "Semimembranosus" // medial
    case bicepsFemoris = "Biceps Femoris" // lateral
    
    // MARK: - Calves
    case gastrocnemius = "Gastrocnemius"
    case soleus = "Soleus"
    case plantaris = "Plantaris"
    
    // MARK: - Glutes
    case gluteusMaximus = "Gluteus Maximus"
    case gluteusMedius = "Gluteus Medius"
    case gluteusMinimus = "Gluteus Minimus" // deep
    
    // MARK: - Tibialis
    case tibialisAnterior = "Tibialis Anterior"
    case tibialisPosterior = "Tibialis Posterior"

    // Additional muscle groups as needed
    var id: String { self.rawValue }
}


extension SubMuscles {
    var simpleName: String {
        switch self {
        case .clavicularHead: return "Upper Chest"
        case .sternocostalHead: return "Middle Chest"
        case .costalHead: return "Lower Chest"
          
        case .tricepsLongHead, .bicepsLongHead: return "Long Head"
        case .tricepsLateralHead: return "Lateral Head"
        case .tricepsMedialHead: return "Medial Head"
          
        case .bicepsShortHead: return "Short Head"
          
        case .forearmFlexors: return "Flexors"
        case .forearmExtensors: return "Extensors"
          
        default: return self.rawValue
        }
    }
}
