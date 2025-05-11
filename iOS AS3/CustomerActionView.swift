import SwiftUI

struct CustomerActionView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var navigationPath: [NavigationTarget]
    @State private var customerName: String = ""

    var body: some View {
        VStack(spacing: 30) {
            Text("Customer Actions")
                .font(.title)
                .padding(.bottom, 20)
            
            TextField("Your Name", text: $customerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button {
                navigationPath.append(.myReservations(customerName: customerName))
            } label: {
                Text("View My Reservations")
                    .modifier(MainMenuButtonModifier(backgroundColor: .orange))
            }
            .disabled(customerName.isEmpty)

            Button {
                navigationPath.append(.addReservation)
            } label: {
                Text("Make New Reservation")
                    .modifier(MainMenuButtonModifier(backgroundColor: .green))
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Customer")
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
