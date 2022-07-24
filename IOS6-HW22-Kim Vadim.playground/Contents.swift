import Foundation

class ChipStorage {
    private var chipArray = [Chip]()
    private let queue = DispatchQueue(label: "myQueue", qos: .utility, attributes: .concurrent)
    private var isGeneratingThreadInProccess = true
    var boolPredicate = false
    private let condition = NSCondition()

    func appendChip(_ value: Chip) {
        queue.async(flags: .barrier) {
            self.chipArray.append(value)
            self.boolPredicate = true
            //inform Working Thread that chip could be taken from storage to work with
            self.condition.signal()
        }
    }

    func getChip() -> Chip {
        queue.sync {
            return chipArray.removeLast()
        }
    }

    ///Returns true if storage can give item to work with, otherwise returns false
    func getStorageState() -> Bool {
        if chipArray.count > 0 || isGeneratingThreadInProccess {
            return true
        } else {
            return false
        }
    }

    func getStorageChipsCount() -> Int {
        chipArray.count
    }

    func toggleIsGeneratingThreadInProccess() {
        isGeneratingThreadInProccess.toggle()
    }

    func waitForChipBeenAdded() {
        self.condition.wait()
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
        print("Начало выполнения генерирующего потока: \(Date.getCurrentTime())\n")
        timer = Timer.scheduledTimer(timeInterval: 2,
                                     target: self,
                                     selector: #selector(runTimedCode),
                                     userInfo: nil,
                                     repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }

    @objc func runTimedCode() {
        seconds -= 2
        guard seconds > 0 else {
            timer.invalidate()
            storage.toggleIsGeneratingThreadInProccess()
            print("\nКонец выполнения генерирующего потока: \(Date.getCurrentTime())\n")
            self.cancel()
            return
        }
        storage.appendChip(Chip.make())
        print("Добавлена микросхема \(counter) - \(Date.getCurrentTime())")
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
        print("Начало выполнения рабочего потока: \(Date.getCurrentTime())\n")
        while storage.getStorageState() {
            while !storage.boolPredicate {
                //wait for the moment when the chip been added to the storage
                storage.waitForChipBeenAdded()
            }

            storage.getChip().sodering()
            print("Припаяна микросхема  \(counter) - \(Date.getCurrentTime())")
            counter += 1

            if storage.getStorageChipsCount() < 1  {
                storage.boolPredicate = false
            }
        }
        print("\nКонец выполнения рабочего потока: \(Date.getCurrentTime())")
        self.cancel()
    }
}

let storage = ChipStorage()

let generatingThread = GeneratingThread(storage: storage)
generatingThread.start()

let workingThread = WorkingThread(storage: storage)
workingThread.start()
