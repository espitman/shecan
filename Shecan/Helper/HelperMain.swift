import Foundation

@main
struct HelperMain {
    static func main() {
        let delegate = PrivilegedHelperService()
        let listener = NSXPCListener(machServiceName: ShecanHelperConstants.machServiceName)
        listener.delegate = delegate
        listener.resume()
        RunLoop.current.run()
    }
}
