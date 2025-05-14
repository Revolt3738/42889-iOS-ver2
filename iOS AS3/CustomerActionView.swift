import SwiftUI

struct CustomerActionView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var navigationPath: [NavigationTarget]

    var body: some View {
        VStack(spacing: 30) {
            Text("Customer Actions")
                .font(.title)
                .padding(.bottom, 20)
            
            Button {
                print("DEBUG: View My Reservations button tapped")
                navigationPath.append(.myReservations(customerName: ""))
            } label: {
                Text("View My Reservations")
                    .modifier(MainMenuButtonModifier(backgroundColor: .orange))
            }
            
            Button {
                print("DEBUG: Make New Reservation button tapped")
                navigationPath.append(.addReservation)
                print("DEBUG: After append, navigationPath: \(navigationPath), count: \(navigationPath.count)")
            } label: {
                Text("Make New Reservation")
                    .modifier(MainMenuButtonModifier(backgroundColor: .green))
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Customer")
        .onAppear {
            print("DEBUG: CustomerActionView onAppear, navigationPath: \(navigationPath)")
        }
        .onDisappear {
            print("DEBUG: CustomerActionView onDisappear")
        }
    }
}

struct CustomerActionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CustomerActionView(navigationPath: .constant([]))
                .environmentObject(ReservationStore())
        }
    }
}
