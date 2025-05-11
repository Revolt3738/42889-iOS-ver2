import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var navigationPath: [NavigationTarget]
    @Environment(\.presentationMode) var presentationMode

    var existingReservationId: UUID? = nil

    @State private var customerName: String = ""
    @State private var reservationTime: Date = Date()
    @State private var numberOfGuests: Int = 1
    @State private var contactInfo: String = ""
    @State private var selectedSeat: (table: Int, seat: Int)? = nil
    @State private var originalValues: (name: String, time: Date, guests: Int, contact: String, seat: (table: Int, seat: Int)?)?
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Information"
    @State private var showCancelAlert = false
    
    private var isEditing: Bool {
        existingReservationId != nil
    }

    var body: some View {
        Form {
            Section(header: Text("Customer Information").font(.headline)) {
                TextField("Name", text: $customerName)
                TextField("Contact Information (e.g. Phone Number)", text: $contactInfo)
                    .keyboardType(.phonePad)
            }

            Section(header: Text("Reservation Details").font(.headline)) {
                DatePicker("Reservation Time", selection: $reservationTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                Stepper("Number of Guests: \(numberOfGuests)", value: $numberOfGuests, in: 1...20)
                
                NavigationLink(destination: SelectSeatView(numberOfGuests: numberOfGuests, selectedSeat: $selectedSeat)) {
                   HStack {
                       Text("Select seat")
                       Spacer()
                       if let seat = selectedSeat {
                           Text("\(seat.table)-\(seat.seat)")
                               .foregroundColor(.accentColor)
                               .bold()
                       } else {
                           Text("未选择")
                               .foregroundColor(.gray)
                       }
                   }
               }
            }

            Button(action: saveReservation) {
                Text(isEditing ? "Update Reservation" : "Confirm Reservation")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical)
            .listRowBackground(Color.accentColor)
            .foregroundColor(.white)
        }
        .navigationTitle(isEditing ? "Edit Reservation" : "Add Reservation")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    if hasChanges() {
                        showCancelAlert = true
                    } else {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadReservationData()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage == "Reservation updated successfully!" || alertMessage == "Reservation added successfully!" {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            )
        }
        .alert("Confirm Discard Changes", isPresented: $showCancelAlert) {
            Button("Continue Editing", role: .cancel) { }
            Button("Discard Changes", role: .destructive) {
                if let original = originalValues {
                    customerName = original.name
                    reservationTime = original.time
                    numberOfGuests = original.guests
                    contactInfo = original.contact
                    selectedSeat = original.seat
                }
                
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    private func loadReservationData() {
        if isEditing, let id = existingReservationId,
           let reservationToEdit = reservationStore.reservations.first(where: { $0.id == id }) {
            customerName = reservationToEdit.customerName
            reservationTime = reservationToEdit.reservationTime
            numberOfGuests = reservationToEdit.numberOfGuests
            contactInfo = reservationToEdit.contactInfo
            selectedSeat = reservationToEdit.selectedSeat
            
            originalValues = (
                name: reservationToEdit.customerName,
                time: reservationToEdit.reservationTime,
                guests: reservationToEdit.numberOfGuests,
                contact: reservationToEdit.contactInfo,
                seat: reservationToEdit.selectedSeat
            )
        }
    }
    
    private func hasChanges() -> Bool {
        guard let original = originalValues else { return true }
        
        // 比较座位信息的新方法
        let seatChanged: Bool = {
            switch (selectedSeat, original.seat) {
            case (nil, nil): return false
            case (let s1?, let s2?): return s1.table != s2.table || s1.seat != s2.seat
            default: return true
            }
        }()
        
        return customerName != original.name ||
               !Calendar.current.isDate(reservationTime, equalTo: original.time, toGranularity: .minute) ||
               numberOfGuests != original.guests ||
               contactInfo != original.contact ||
               seatChanged
    }

    func saveReservation() {
        if customerName.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter customer name."
            showAlert = true
            return
        }
        if contactInfo.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter contact information."
            showAlert = true
            return
        }
        
        if isEditing, let id = existingReservationId {
            if let existingReservation = reservationStore.reservations.first(where: { $0.id == id }) {
                existingReservation.customerName = customerName
                existingReservation.reservationTime = reservationTime
                existingReservation.numberOfGuests = numberOfGuests
                existingReservation.contactInfo = contactInfo
                existingReservation.selectedSeat = selectedSeat
                
                reservationStore.objectWillChange.send()
            }
            
            alertTitle = "Success"
            alertMessage = "Reservation updated successfully!"
        } else {
            reservationStore.addReservation(
                customerName: customerName,
                reservationTime: reservationTime,
                numberOfGuests: numberOfGuests,
                contactInfo: contactInfo,
                selectedSeat: selectedSeat
            )
            
            alertTitle = "Success"
            alertMessage = "Reservation added successfully!"
        }
        
        showAlert = true
    }
}

struct AddReservationView_Previews: PreviewProvider {
    static var previews: some View {
        let store = ReservationStore()
        store.addReservation(
            customerName: "Test User",
            reservationTime: Date(),
            numberOfGuests: 2,
            contactInfo: "12345",
            selectedSeat: (1, 2)
        )
        
        return NavigationStack {
            AddReservationView(navigationPath: .constant([]), existingReservationId: nil)
                .environmentObject(store)
        }
    }
}
