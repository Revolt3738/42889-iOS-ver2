import SwiftUI

enum NavigationTarget: Hashable {
    case reservationList
    case customerActions
    case addReservation
    case myReservations(customerName: String)
    case editReservation(reservationId: UUID)
}

struct ContentView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @State private var navigationPath: [NavigationTarget] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 20) {
                Text("Restaurant Reservation System")
                    .font(.largeTitle)
                    .padding(.bottom, 20)

                NavigationLink(value: NavigationTarget.reservationList) {
                    Text("Restaurant Owner")
                        .modifier(MainMenuButtonModifier(backgroundColor: .blue))
                }

                NavigationLink(value: NavigationTarget.customerActions) {
                    Text("Customer")
                        .modifier(MainMenuButtonModifier(backgroundColor: .green))
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: NavigationTarget.self) { target in
                switch target {
                case .reservationList:
                    ReservationListView()
                case .customerActions:
                    CustomerActionView(navigationPath: $navigationPath)
                case .addReservation:
                    AddReservationView(navigationPath: $navigationPath)
                case .myReservations(let customerName):
                    MyReservationsView(navigationPath: $navigationPath, customerNameFilter: customerName)
                case .editReservation(let reservationId):
                    AddReservationView(navigationPath: $navigationPath, existingReservationId: reservationId)
                }
            }
        }
    }
}

struct MainMenuButtonModifier: ViewModifier {
    let backgroundColor: Color
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ReservationStore())
    }
}
