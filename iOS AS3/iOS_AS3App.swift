import SwiftUI

@main
struct iOS_AS3App: App {
    @StateObject var reservationStore = ReservationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reservationStore)
        }
    }
}
