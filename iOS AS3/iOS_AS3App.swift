import SwiftUI

@main
struct iOS_AS3App: App {
    @StateObject var reservationStore = ReservationStore()
    
    init() {
        // 设置全局错误处理
        setupExceptionHandling()
        print("DEBUG: App initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reservationStore)
                .onAppear {
                    print("DEBUG: Root ContentView appearing")
                    // 打印 iOS 版本信息，帮助确认兼容性问题
                    // 这里不需要检查iOS版本，因为部署目标确保了我们运行在iOS 16.0+上
                    print("DEBUG: Running on iOS 16.0 or newer")
                }
        }
    }
    
    private func setupExceptionHandling() {
        // 设置全局异常处理以捕获未处理的错误
        NSSetUncaughtExceptionHandler { exception in
            print("DEBUG: CRASH DETECTED - \(exception.name): \(exception.reason ?? "unknown reason")")
            print("DEBUG: Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
        }
    }
}
