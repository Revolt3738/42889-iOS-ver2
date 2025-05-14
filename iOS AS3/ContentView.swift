import SwiftUI

enum NavigationTarget: Hashable {
    case reservationList
    case customerActions
    case addReservation
    case myReservations(customerName: String)
    case editReservation(reservationId: UUID)
    case selectSeats(numberOfGuests: Int, selectedSeats: [(table: Int, seat: Int)])
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .reservationList:
            hasher.combine(0)
        case .customerActions:
            hasher.combine(1)
        case .addReservation:
            hasher.combine(2)
        case .myReservations(let customerName):
            hasher.combine(3)
            hasher.combine(customerName)
        case .editReservation(let reservationId):
            hasher.combine(4)
            hasher.combine(reservationId)
        case .selectSeats(let numberOfGuests, let selectedSeats):
            hasher.combine(5)
            hasher.combine(numberOfGuests)
            for seat in selectedSeats {
                hasher.combine(seat.table)
                hasher.combine(seat.seat)
            }
        }
    }
    
    static func == (lhs: NavigationTarget, rhs: NavigationTarget) -> Bool {
        switch (lhs, rhs) {
        case (.reservationList, .reservationList):
            return true
        case (.customerActions, .customerActions):
            return true
        case (.addReservation, .addReservation):
            return true
        case (.myReservations(let lhsName), .myReservations(let rhsName)):
            return lhsName == rhsName
        case (.editReservation(let lhsId), .editReservation(let rhsId)):
            return lhsId == rhsId
        case (.selectSeats(let lhsGuests, let lhsSeats), .selectSeats(let rhsGuests, let rhsSeats)):
            guard lhsGuests == rhsGuests else { return false }
            guard lhsSeats.count == rhsSeats.count else { return false }
            let sortedLhsSeats = lhsSeats.sorted { ($0.table, $0.seat) < ($1.table, $1.seat) }
            let sortedRhsSeats = rhsSeats.sorted { ($0.table, $0.seat) < ($1.table, $1.seat) }
            return sortedLhsSeats.enumerated().allSatisfy { index, seat in
                seat.table == sortedRhsSeats[index].table && seat.seat == sortedRhsSeats[index].seat
            }
        default:
            return false
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @State private var navigationPath: [NavigationTarget] = [] {
        didSet {
            print("DEBUG: Navigation path changed: \(navigationPath), count: \(navigationPath.count)")
        }
    }

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
                .onTapGesture {
                    print("DEBUG: Restaurant Owner button tapped")
                }

                NavigationLink(value: NavigationTarget.customerActions) {
                    Text("Customer")
                        .modifier(MainMenuButtonModifier(backgroundColor: .green))
                }
                .onTapGesture {
                    print("DEBUG: Customer button tapped")
                }

                Spacer()
            }
            .padding()
            .onAppear {
                print("DEBUG: ContentView appeared, navigationPath: \(navigationPath)")
            }
            .navigationDestination(for: NavigationTarget.self) { target in
                switch target {
                case .reservationList:
                    ReservationListView()
                        .onAppear {
                            print("DEBUG: ReservationListView appeared")
                        }
                case .customerActions:
                    CustomerActionView(navigationPath: $navigationPath)
                        .onAppear {
                            print("DEBUG: CustomerActionView appeared")
                        }
                case .addReservation:
                    AddReservationView(navigationPath: $navigationPath)
                        .onAppear {
                            print("DEBUG: AddReservationView displayed via navigation destination")
                        }
                case .myReservations(let customerName):
                    MyReservationsView(navigationPath: $navigationPath, customerNameFilter: customerName)
                        .onAppear {
                            print("DEBUG: MyReservationsView appeared with customerName: \(customerName)")
                        }
                case .editReservation(let reservationId):
                    AddReservationView(navigationPath: $navigationPath, existingReservationId: reservationId)
                        .onAppear {
                            print("DEBUG: Edit reservation view appeared for ID: \(reservationId)")
                        }
                case .selectSeats(let numberOfGuests, let selectedSeats):
                    SeatSelectionWrapper(navigationPath: $navigationPath, numberOfGuests: numberOfGuests, initialSelectedSeats: selectedSeats)
                        .onAppear {
                            print("DEBUG: SelectSeats view appeared for \(numberOfGuests) guests")
                        }
                }
            }
        }
    }
}

struct SeatSelectionWrapper: View {
    @Binding var navigationPath: [NavigationTarget]
    let numberOfGuests: Int
    let initialSelectedSeats: [(table: Int, seat: Int)]
    
    @State private var selectedSeats: [(table: Int, seat: Int)]
    
    init(navigationPath: Binding<[NavigationTarget]>, numberOfGuests: Int, initialSelectedSeats: [(table: Int, seat: Int)]) {
        self._navigationPath = navigationPath
        self.numberOfGuests = numberOfGuests
        self.initialSelectedSeats = initialSelectedSeats
        self._selectedSeats = State(initialValue: initialSelectedSeats)
    }
    
    private func confirmAndDismiss(selectedSeatsData: [(table: Int, seat: Int)]) {
        print("DEBUG: [SeatSelectionWrapper] confirmAndDismiss called with seats: \(selectedSeatsData)")
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        } else {
            print("DEBUG: [SeatSelectionWrapper] Warning: Navigation path empty, can't pop.")
        }
        
        let userInfo: [String: Any] = ["selectedSeats": self.selectedSeats]
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateSelectedSeats"),
            object: nil,
            userInfo: userInfo
        )
        print("DEBUG: [SeatSelectionWrapper] Sent notification with seats: \(self.selectedSeats)")
    }
    
    var body: some View {
        SelectSeatView(numberOfGuests: numberOfGuests, selectedSeats: $selectedSeats, onComplete: self.confirmAndDismiss)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("DEBUG: [SeatSelectionWrapper] Done button pressed, calling confirmAndDismiss")
                        self.confirmAndDismiss(selectedSeatsData: self.selectedSeats)
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
