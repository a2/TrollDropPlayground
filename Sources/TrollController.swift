import CoreGraphics
import Foundation

func browserCallbackFunction(browser: TDKSFBrowser, node: TDKSFNode, children: CFArray, _: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    let controller = Unmanaged.fromOpaque(context).takeUnretainedValue() as TrollController
    controller.handleBrowserCallback(browser: browser, node: node, children: children)
}

func operationCallback(operation: TDKSFOperation, rawEvent: TDKSFOperationEvent.RawValue, results: AnyObject, context: UnsafeMutableRawPointer?) {
    guard let event = TDKSFOperationEvent(rawValue: rawEvent) else { return }
    guard let context = context else { return }
    let controller = Unmanaged.fromOpaque(context).takeUnretainedValue() as TrollController
    controller.handleOperationCallback(operation: operation, event: event, results: results)
}

func dataProviderRelease(_: UnsafeMutableRawPointer?, _: UnsafeRawPointer, _: Int) -> Void {
}


public class TrollController {
    private enum Trolling {
        case operation(TDKSFOperation)
        case workItem(DispatchWorkItem)

        func cancel() {
            switch self {
            case .operation(let operation):
                TDKSFOperationCancel(operation)
            case .workItem(let workItem):
                workItem.cancel()
            }
        }
    }

    /// The current browser
    private var browser: TDKSFBrowser?

    /// The currently known people
    private var people: Set<TDKSFNode>

    /// A map between known people and a Trolling (a currently running operation or a delayed work item)
    private var trollings: Dictionary<TDKSFNode, Trolling>

    /// The duration to wait after trolling before trolling again.
    public var rechargeDuration: TimeInterval

    /// The local file URL with which to troll. Defaults to a troll face image.
    public var sharedURL: URL

    /// Whether the scanner is currently active.
    public var isRunning: Bool {
        return browser != nil
    }

    /// A block handler that allows for fine-grained control of whom to troll.
    public var shouldTrollHandler: (Person) -> Bool

    /// A block handler that allows customization of the shared file for certain people.
    public var sharedURLOverrideHandler: (Person) -> URL?

    public init(sharedURL: URL) {
        TDKInitialize()
        people = []
        trollings = [:]
        rechargeDuration = 15
        shouldTrollHandler = { _ in true }
        sharedURLOverrideHandler = { _ in nil }
        self.sharedURL = sharedURL
    }

    deinit {
        stop()
    }

    /// Start the browser.
    public func start() {
        guard !isRunning else { return }

        var clientContext: TDKSFBrowserClientContext = (
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let browser = TDKSFBrowserCreate(kCFAllocatorDefault, kTDKSFBrowserKindAirDrop)
        TDKSFBrowserSetClient(browser, browserCallbackFunction, &clientContext)
        TDKSFBrowserSetDispatchQueue(browser, .main)
        TDKSFBrowserOpenNode(browser, nil, nil, 0)
        self.browser = browser
    }

    /// Stop the browser and clean up browsing state.
    public func stop() {
        guard isRunning else { return }

        // Cancel pending operations.
        for trolling in trollings.values {
            trolling.cancel()
        }

        // Empty operations map.
        trollings.removeAll()

        // Invalidate the browser.
        TDKSFBrowserInvalidate(browser!)
        browser = nil
    }

    /// Troll the person/device identified by \c node (\c TDKSFNodeRef)
    func troll(node: TDKSFNode) {
        let fileIcon: CGImage?
        let fileURL: URL
        if let fileURLOverride = sharedURLOverrideHandler(Person(node: node)) {
            fileIcon = nil
            fileURL = fileURLOverride
        } else {
            if let dataProvider = CGDataProvider(url: sharedURL as CFURL) {
                fileIcon = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
            } else {
                fileIcon = nil
            }

            fileURL = sharedURL
        }

        var clientContext: TDKSFBrowserClientContext = (
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let operation = TDKSFOperationCreate(kCFAllocatorDefault, kTDKSFOperationKindSender, nil, nil)
        TDKSFOperationSetClient(operation, operationCallback, &clientContext)
        TDKSFOperationSetProperty(operation, kTDKSFOperationItemsKey, [fileURL] as AnyObject)
        if let fileIcon = fileIcon {
            TDKSFOperationSetProperty(operation, kTDKSFOperationFileIconKey, fileIcon)
        }
        TDKSFOperationSetProperty(operation, kTDKSFOperationNodeKey, Unmanaged.fromOpaque(UnsafeRawPointer(node)).takeUnretainedValue())
        TDKSFOperationSetDispatchQueue(operation, .main)
        TDKSFOperationResume(operation)

        trollings[node] = .operation(operation)
    }

    func handleBrowserCallback(browser: TDKSFBrowser, node: TDKSFNode, children: CFArray) {
        let nodes = TDKSFBrowserCopyChildren(browser, nil) as [AnyObject]
        var newPeople = Set<TDKSFNode>(minimumCapacity: nodes.count)

        for nodeObject in nodes {
            let node = OpaquePointer(Unmanaged.passUnretained(nodeObject).toOpaque())
            let isAwareOfPerson = people.contains(node) || trollings[node] != nil
            let shouldTroll = shouldTrollHandler(Person(node: node))

            if !isAwareOfPerson && shouldTroll {
                troll(node: node)
            }

            newPeople.insert(node)
        }

        // If we no longer know about a person, cancel their trolling.
        for oldNode in people.subtracting(newPeople) {
            if let trolling = trollings.removeValue(forKey: oldNode) {
                trolling.cancel()
            }
        }

        people = newPeople
    }

    func handleOperationCallback(operation: TDKSFOperation, event: TDKSFOperationEvent, results: CFTypeRef) {
        switch event {
        case .askUser:
            // Seems that .askUser requires the operation to be resumed.
            TDKSFOperationResume(operation)

        case .canceled, .errorOccurred, .finished:
            // Schedule a new trolling if the operation has ended.
            let nodeObject = TDKSFOperationCopyProperty(operation, kTDKSFOperationNodeKey)
            let node = OpaquePointer(Unmanaged.passUnretained(nodeObject).toOpaque())
            let workItem = DispatchWorkItem {
                self.troll(node: node)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(Int(rechargeDuration * Double(NSEC_PER_SEC))), execute: workItem)
            trollings[node] = .workItem(workItem)

        default:
            break
        }
    }
}
