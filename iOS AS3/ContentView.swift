import SwiftUI

class Reservation: Identifiable, Equatable, Hashable, ObservableObject {
    let id: UUID
    @Published var customerName: String
    @Published var reservationTime: Date
    @Published var numberOfGuests: Int
    @Published var contactInfo: String
    @Published var selectedSeat: (table: Int, seat: Int)?
    
    init(customerName: String, reservationTime: Date, numberOfGuests: Int, contactInfo: String, selectedSeat: (table: Int, seat: Int)? = nil) {
        self.id = UUID()
        self.customerName = customerName
        self.reservationTime = reservationTime
        self.numberOfGuests = numberOfGuests
        self.contactInfo = contactInfo
        self.selectedSeat = selectedSeat
    }
    
    init(id: UUID, customerName: String, reservationTime: Date, numberOfGuests: Int, contactInfo: String, selectedSeat: (table: Int, seat: Int)? = nil) {
        self.id = id
        self.customerName = customerName
        self.reservationTime = reservationTime
        self.numberOfGuests = numberOfGuests
        self.contactInfo = contactInfo
        self.selectedSeat = selectedSeat
    }
    
    static func == (lhs: Reservation, rhs: Reservation) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
                    AddReservationView(navigationPath: $navigationPath, existingReservationId: nil)
                case .myReservations(let customerName):
                    MyReservationsView(navigationPath: $navigationPath, customerNameFilter: customerName)
                case .editReservation(let reservationId):
                    AddReservationView(navigationPath: $navigationPath, existingReservationId: reservationId)
                }
            }
        }
        .environmentObject(reservationStore)
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
