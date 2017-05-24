import Dispatch
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let trollController = TrollController(sharedURL: #fileLiteral(resourceName: "trollface.jpg"))
trollController.start()

dispatchMain()
