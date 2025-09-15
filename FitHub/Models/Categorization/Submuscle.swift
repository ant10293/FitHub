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
    case externalObliques = "External Obliques"
    case transverseAbdominis = "Transverse Abdominis"
    
    // MARK: - Traps
    case upperTraps = "Upper Traps"
    case middleTraps = "Middle Traps"
    case lowerTraps = "Lower Traps"
    
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
    case forearmRotators = "Forarm Rotators" // Pronator Teres & Supinator
    
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

/*
enum SubMuscles: String, CaseIterable, Identifiable, Codable {
    // MARK: - Chest
    case clavicularHead, sternocostalHead, costalHead
    
    // MARK: - Shoulders
    case frontDelt, sideDelt, rearDelt
    
    // MARK: - Biceps
    case bicepsLongHead, bicepsShortHead, brachialis
    
    // MARK: - Triceps
    case tricepsLongHead, tricepsLateralHead, tricepsMedialHead
    
    // MARK: - Abs
    case upperAbs, lowerAbs, obliques, externalObliques, transverseAbdominis
    
    // MARK: - Traps
    case upperTraps, middleTraps, lowerTraps
    
    // MARK: - Erector Spinae
    case iliocostalis, longissimus, spinalis
    
    // MARK: - Cervical Spine
    case infrahyoid, sternocleidomastoid, scalenes, longusFlexors
    
    // MARK: - Forearms
    case brachioradialis, forearmFlexors, forearmExtensors, forearmRotators
    
    // MARK: - Quads
    case rectusFemoris, vastusMedialis, vastusLateralis, vastusIntermedius
    
    // MARK: - Hamstrings
    case semitendinosus, semimembranosus, bicepsFemoris
    
    // MARK: - Calves
    case gastrocnemius, soleus, plantaris
    
    // MARK: - Glutes
    case gluteusMaximus, gluteusMedius, gluteusMinimus
    
    // MARK: - Tibialis
    case tibialisAnterior, tibialisPosterior

    // Additional muscle groups as needed
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        // MARK: - Chest
        case .clavicularHead: return "Clavicular Head"
        case .sternocostalHead: return "Sternocostal Head"
        case .costalHead: return "Costal Head"
            
        // MARK: - Shoulders
        case .frontDelt: return "Front Deltoid"
        case .sideDelt: return "Side Deltoid"
        case .rearDelt: return "Rear Deltoid"
            
        // MARK: - Biceps
        case .bicepsLongHead: return "Biceps Long Head"
        case .bicepsShortHead: return "Biceps Short Head"
        case .brachialis: return "Brachialis"
            
        // MARK: - Triceps
        case .tricepsLongHead: return "Triceps Long Head"
        case .tricepsLateralHead: return "Triceps Lateral Head"
        case .tricepsMedialHead: return "Triceps Medial Head"
            
        // MARK: - Abs
        case .upperAbs: return "Upper Abdominals"
        case .lowerAbs: return "Lower Abdominals"
        case .obliques: return "Obliques"
        case .externalObliques: return "External Obliques"
        case .transverseAbdominis: return "Transverse Abdominis"
            
        // MARK: - Traps
        case .upperTraps: return "Upper Trapezius"
        case .middleTraps: return "Middle Trapezius"
        case .lowerTraps: return "Lower Trapezius"
            
        // MARK: - Erector Spinae
        case .iliocostalis: return "Iliocostalis"
        case .longissimus: return "Longissimus"
        case .spinalis: return "Spinalis"
            
        // MARK: - Cervical Spine
        case .infrahyoid: return "Infrahyoid"
        case .sternocleidomastoid: return "Sternocleidomastoid"
        case .scalenes: return "Scalenes"
        case .longusFlexors: return "Longus Flexors"
            
        // MARK: - Forearms
        case .brachioradialis: return "Brachioradialis"
        case .forearmFlexors: return "Forearm Flexors"
        case .forearmExtensors: return "Forearm Extensors"
        case .forearmRotators: return "Forearm Rotators"
            
        // MARK: - Quads
        case .rectusFemoris: return "Rectus Femoris"
        case .vastusMedialis: return "Vastus Medialis"
        case .vastusLateralis: return "Vastus Lateralis"
        case .vastusIntermedius: return "Vastus Intermedius"

        // MARK: - Hamstrings
        case .semitendinosus: return "Semitendinosus"
        case .semimembranosus: return "Semimembranosus"
        case .bicepsFemoris: return "Biceps Femoris"

        // MARK: - Calves
        case .gastrocnemius: return "Gastrocnemius"
        case .soleus: return "Soleus"
        case .plantaris: return "Plantaris"

        // MARK: - Glutes
        case .gluteusMaximus: return "Gluteus Maximus"
        case .gluteusMedius: return "Gluteus Medius"
        case .gluteusMinimus: return "Gluteus Minimus"

        // MARK: - Tibialis
        case .tibialisAnterior: return "Tibialis Anterior"
        case .tibialisPosterior: return "Tibialis Posterior"
        }
    }
}
*/
