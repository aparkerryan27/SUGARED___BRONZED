//CardParser.swift, Created by Jason Clark on 6/28/16. Copyright © 2016 Raizlabs. All rights reserved.


//MARK: - CardType

enum CardType {
    case amex
    case visa
    case masterCard
    case discover
    case jcb
    case dinersClub
    case maestro
    case solo
    case samsung
    case shinhan
    case kookmin
    case lotte
    case keb
    case bc
    case hyunDai
    case naps
    case electronVisa
    case deltaVisa
    case nh
    case jeju
    
    static let allValues: [CardType] = [.visa, .masterCard, .amex, .dinersClub, .discover, .jcb, .dinersClub, .maestro, .solo, .samsung, .shinhan, .kookmin, .lotte, .keb, .bc, .hyunDai, .naps, .electronVisa, .deltaVisa, .nh, .jeju]
    
    private var validationRequirements: ValidationRequirement {
        let prefix: [PrefixContainable]
        let length: [Int]
        
        switch self {
            /* // IIN prefixes and length requriements retreived from https://en.wikipedia.org/wiki/Bank_card_number on August 12, 2019 */
            
        case .amex:
            prefix = ["34", "37"]
            length = [15]
            
        case .visa:
            prefix = ["4"]
            length = [16]
            
        case .masterCard:
            prefix = ["51"..."55", "2221"..."2720"]
            length = [16]
            
        case .discover:
            prefix = ["6011", "65", "644"..."649", "622126"..."622925"]
            length = [16, 17, 18, 19]
            
        case .jcb:
            prefix = ["3528"..."3589"]
            length = [16]
            
        case .dinersClub:
            prefix = ["300"..."305", "309", "36", "38"..."39"]
            length = [14, 15, 16, 17, 18, 19]
            
        case .maestro:
            prefix = ["50", "56"..."69"]
            length = [12,13,14,15,16,17,18,19]
            
        case .solo:
            prefix = ["300"..."305", "309", "36", "38"..."39"]
            length = [16, 18, 19]
            
        case .samsung:
            prefix = [""]  //???
            length = [0] //????
            
        case .shinhan:
            prefix = [""] //???
            length = [0] //????
            
        case .kookmin:
            prefix = [""] //????
            length = [14] //????
            
        case .lotte:
            prefix = ["534291"] //????
            length = [14] //????
            
        case .keb:
            prefix = [""]
            length = [14]
            
        case .bc:
            prefix = [""]
            length = [14]
            
        case .hyunDai:
            prefix = [""]
            length = [14]
            
        case .naps:
            prefix = [""]
            length = [14]
            
        case .electronVisa:
            prefix = ["4026", "417500", "4405", "4508", "4844", "4913", "4917"]
            length = [16]
            
        case .deltaVisa:
            prefix = [""]
            length = [14]
            
        case .nh:
            prefix = [""]
            length = [14]
            
        case .jeju:
            prefix = [""]
            length = [14]
            
        }
        
        return ValidationRequirement(prefixes: prefix, lengths: length)
    }
    
    // Mapping of card prefix to pattern is taken from
    // https://baymard.com/checkout-usability/credit-card-patterns
    var spacingFormat: String {
        switch self {
            
        case .amex, .dinersClub:
            return "465"
        case .visa, .electronVisa, .discover, .masterCard, .jcb, .solo:
            return "4444"
        case .maestro: return "4444" //??? for all below
        case .samsung: return "4444"
        case .shinhan: return "4444"
        case .kookmin: return "4444"
        case .lotte: return "4444"
        case .keb: return "4444"
        case .bc: return "4444"
        case .hyunDai: return "4444"
        case .naps: return "4444"
        case .deltaVisa: return "4444"
        case .nh: return "4444"
        case .jeju: return "4444"
            
        }
    }
    
    var maxLength: Int {
        return validationRequirements.lengths.max() ?? 16
    }
    
    var bookerID: Int {
        switch self {
        case .amex: return 1
        case .visa: return 2
        case .masterCard: return 3
        case .discover: return 4
        case .jcb: return 5
        case .dinersClub: return 6
        case .maestro: return 7
        case .solo: return 8
        case .samsung: return 9
        case .shinhan: return 10
        case .kookmin: return 11
        case .lotte: return 12
        case .keb: return 13
        case .bc: return 14
        case .hyunDai: return 15
        case .naps: return 16
        case .electronVisa: return 18
        case .deltaVisa: return 19
        case .nh: return 20
        case .jeju: return 21
        }
    }
    
    
    func isValid(_ accountNumber: String) -> Bool {
        return validationRequirements.isValid(accountNumber) && CardType.luhnCheck(accountNumber)
    }
    
    func isPrefixValid(_ accountNumber: String) -> Bool {
        return validationRequirements.isPrefixValid(accountNumber)
    }
    
}

fileprivate extension CardType {
    
    struct ValidationRequirement {
        let prefixes: [PrefixContainable]
        let lengths: [Int]
        
        func isValid(_ accountNumber: String) -> Bool {
            return isLengthValid(accountNumber) && isPrefixValid(accountNumber)
        }
        
        func isPrefixValid(_ accountNumber: String) -> Bool {
            guard prefixes.count > 0 else { return true }
            return prefixes.contains { $0.hasCommonPrefix(with: accountNumber) }
        }
        
        func isLengthValid(_ accountNumber: String) -> Bool {
            guard lengths.count > 0 else { return true }
            return lengths.contains { accountNumber.count == $0 }
        }
    }
    
    // from: https://gist.github.com/cwagdev/635ce973e8e86da0403a -- checks the validity of the card
    static func luhnCheck(_ cardNumber: String) -> Bool {
        var sum = 0
        let reversedCharacters = cardNumber.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else { return false }
            switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit
            }
        }
        return sum % 10 == 0
    }
    
}





//MARK: - CardState
enum CardState {
    case identified(CardType)
    case indeterminate([CardType])
    case invalid
}

extension CardState: Equatable {}
func ==(lhs: CardState, rhs: CardState) -> Bool {
    switch (lhs, rhs) {
    case (.invalid, .invalid): return true
    case (let .indeterminate(cards1), let .indeterminate(cards2)): return cards1 == cards2
    case (let .identified(card1), let .identified(card2)): return card1 == card2
    default: return false
    }
}

extension CardState {
    
    init(fromNumber number: String) {
        if let card = CardType.allValues.first(where: { $0.isValid(number) }) {
            self = .identified(card)
        }
        else {
            self = .invalid
        }
    }
    
    init(fromPrefix prefix: String) {
        let possibleTypes = CardType.allValues.filter { $0.isPrefixValid(prefix) }
        if possibleTypes.count >= 2 {
            self = .indeterminate(possibleTypes)
        }
        else if possibleTypes.count == 1, let card = possibleTypes.first {
            self = .identified(card)
        }
        else {
            self = .invalid
        }
    }
    
}

//MARK: - PrefixContainable
fileprivate protocol PrefixContainable {
    
    func hasCommonPrefix(with text: String) -> Bool
    
}

extension ClosedRange: PrefixContainable {
    
    func hasCommonPrefix(with text: String) -> Bool {
        //cannot include Where clause in protocol conformance, so have to ensure Bound == String :(
        guard let lower = lowerBound as? String, let upper = upperBound as? String else { return false }
        
        let trimmedRange: ClosedRange<String> = {
            let length = text.count
            let trimmedStart = String(lower.prefix(length))
            let trimmedEnd = String(upper.prefix(length))
            return trimmedStart...trimmedEnd
        }()
        
        let trimmedText = String(text.prefix(trimmedRange.lowerBound.count))
        return trimmedRange ~= trimmedText
    }
    
}

extension String: PrefixContainable {
    
    func hasCommonPrefix(with text: String) -> Bool {
        return hasPrefix(text) || text.hasPrefix(self)
    }
    
}

