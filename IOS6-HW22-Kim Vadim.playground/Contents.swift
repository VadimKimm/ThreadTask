import Foundation

class ChipStorage {
    private var chipArray = [Chip]()
    private let queue = DispatchQueue(label: "myQueue", qos: .utility, attributes: .concurrent)

    func appendChip(_ value: Chip) {
        queue.async(flags: .barrier) {
            self.chipArray.append(value)
        }
    }

    func getChip() -> Chip {
        queue.sync {
            return chipArray.removeLast()
        }
    }
}

let storage = ChipStorage()


