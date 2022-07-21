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

class GeneratingThread: Thread {

    private var storage: ChipStorage
    private var seconds = 20
    private var timer = Timer()
    private var counter = 1

    init(storage: ChipStorage) {
        self.storage = storage
    }

    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 2,
                                     target: self,
                                     selector: #selector(runTimedCode),
                                     userInfo: nil,
                                     repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }

    @objc func runTimedCode() {
        guard seconds > 0 else {
            timer.invalidate()
            self.cancel()
            return
        }
        storage.appendChip(Chip.make())
        print("Добавлена микросхема \(counter)")
        seconds -= 2
        counter += 1
    }
}

class WorkingThread: Thread {

    private var storage: ChipStorage
    private var counter = 1

    init(storage: ChipStorage) {
        self.storage = storage
    }

    override func main() {
    }
}


let storage = ChipStorage()

let generatingThread = GeneratingThread(storage: storage)
generatingThread.start()

