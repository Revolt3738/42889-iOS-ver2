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
    @State private var selectedSeats: [(table: Int, seat: Int)] = []
    @State private var originalValues: (name: String, time: Date, guests: Int, contact: String, seats: [(table: Int, seat: Int)])?

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
                    .onChange(of: customerName) { newValue in
                        print("DEBUG: Name changed to: \(newValue)")
                    }
                TextField("Contact Information (e.g. Phone Number)", text: $contactInfo)
                    .keyboardType(.phonePad)
                    .onChange(of: contactInfo) { newValue in
                        print("DEBUG: Contact changed to: \(newValue)")
                    }
            }

            Section(header: Text("Reservation Details").font(.headline)) {
                DatePicker("Reservation Time", selection: $reservationTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: reservationTime) { newValue in
                        print("DEBUG: Time changed to: \(newValue)")
                    }
                Stepper("Number of Guests: \(numberOfGuests)", value: $numberOfGuests, in: 1...20)
                    .onChange(of: numberOfGuests) { newValue in
                        print("DEBUG: Guests changed to: \(newValue)")
                    }

                Button {
                    print("DEBUG: Navigate to seat selection button tapped")
                    // 直接将要选择的座位数量和当前已选座位传递给SelectSeatView
                    // 创建一个新的导航目标类型
                    navigationPath.append(.selectSeats(numberOfGuests: numberOfGuests, selectedSeats: selectedSeats))
                } label: {
                    HStack {
                        Text("Select seat")
                        Spacer()
                        if selectedSeats.isEmpty {
                            Text("未选择")
                                .foregroundColor(.gray)
                        } else {
                            Text(selectedSeats.map { "\($0.table)-\($0.seat)" }.joined(separator: ", "))
                                .foregroundColor(.accentColor)
                                .bold()
                        }
                    }
                }
            }

            Button(action: {
                print("DEBUG: Save button pressed")
                saveReservation()
            }) {
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
                    print("DEBUG: Back button pressed, hasChanges: \(hasChanges())")
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
            print("DEBUG: AddReservationView appeared")
            loadReservationData()
            // 添加通知监听器
            setupNotificationObserver()
        }
        .onDisappear {
            print("DEBUG: AddReservationView disappeared")
            // 移除通知监听器
            NotificationCenter.default.removeObserver(self)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    print("DEBUG: Alert dismissed with message: \(alertMessage)")
                    if alertMessage.contains("successfully") {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            )
        }
        .alert("Confirm Discard Changes", isPresented: $showCancelAlert) {
            Button("Continue Editing", role: .cancel) { 
                print("DEBUG: Continue editing selected")
            }
            Button("Discard Changes", role: .destructive) {
                print("DEBUG: Discard changes selected")
                if let original = originalValues {
                    customerName = original.name
                    reservationTime = original.time
                    numberOfGuests = original.guests
                    contactInfo = original.contact
                    selectedSeats = original.seats
                }

                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // 设置通知监听器
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateSelectedSeats"),
            object: nil,
            queue: .main
        ) { notification in
            if let seats = notification.userInfo?["selectedSeats"] as? [(table: Int, seat: Int)] {
                print("DEBUG: Received selected seats notification: \(seats)")
                selectedSeats = seats
            }
        }
    }

    private func loadReservationData() {
        print("DEBUG: Loading reservation data, isEditing: \(isEditing)")
        if isEditing, let id = existingReservationId,
           let reservationToEdit = reservationStore.reservations.first(where: { $0.id == id }) {
            customerName = reservationToEdit.customerName
            reservationTime = reservationToEdit.reservationTime
            numberOfGuests = reservationToEdit.numberOfGuests
            contactInfo = reservationToEdit.contactInfo
            selectedSeats = reservationToEdit.selectedSeats ?? []

            originalValues = (
                name: reservationToEdit.customerName,
                time: reservationToEdit.reservationTime,
                guests: reservationToEdit.numberOfGuests,
                contact: reservationToEdit.contactInfo,
                seats: reservationToEdit.selectedSeats ?? []
            )
            print("DEBUG: Loaded existing reservation: \(customerName)")
        }
    }

    private func hasChanges() -> Bool {
        guard let original = originalValues else { return true }

        let timeEqual = Calendar.current.isDate(reservationTime, equalTo: original.time, toGranularity: .minute)
        let nameEqual = customerName == original.name
        let guestsEqual = numberOfGuests == original.guests
        let contactEqual = contactInfo == original.contact
        let seatsEqual = areSeatArraysEqual(original.seats, selectedSeats)
        
        print("DEBUG: hasChanges - name: \(!nameEqual), time: \(!timeEqual), guests: \(!guestsEqual), contact: \(!contactEqual), seats: \(!seatsEqual)")
        
        return !nameEqual || !timeEqual || !guestsEqual || !contactEqual || !seatsEqual
    }

    private func seatSort(_ a: (table: Int, seat: Int), _ b: (table: Int, seat: Int)) -> Bool {
        if a.table != b.table { return a.table < b.table }
        return a.seat < b.seat
    }

    func saveReservation() {
        print("DEBUG: Attempting to save reservation")
        if customerName.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter customer name."
            showAlert = true
            print("DEBUG: Error - empty customer name")
            return
        }
        if contactInfo.isEmpty {
            alertTitle = "Input Error"
            alertMessage = "Please enter contact information."
            showAlert = true
            print("DEBUG: Error - empty contact info")
            return
        }
        if selectedSeats.count != numberOfGuests {
            alertTitle = "Seat Selection"
            alertMessage = "Please select exactly \(numberOfGuests) seat(s)."
            showAlert = true
            print("DEBUG: Error - seat count \(selectedSeats.count) doesn't match guests \(numberOfGuests)")
            return
        }

        if isEditing, let id = existingReservationId {
            print("DEBUG: Updating existing reservation with ID: \(id)")
            if let index = reservationStore.reservations.firstIndex(where: { $0.id == id }) {
                reservationStore.reservations[index].customerName = customerName
                reservationStore.reservations[index].reservationTime = reservationTime
                reservationStore.reservations[index].numberOfGuests = numberOfGuests
                reservationStore.reservations[index].contactInfo = contactInfo
                reservationStore.reservations[index].selectedSeats = selectedSeats
            }


            alertTitle = "Success"
            alertMessage = "Reservation updated successfully!"
        } else {
            print("DEBUG: Adding new reservation for \(customerName)")
            reservationStore.addReservation(
                customerName: customerName,
                reservationTime: reservationTime,
                numberOfGuests: numberOfGuests,
                contactInfo: contactInfo,
                selectedSeats: selectedSeats
            )

            alertTitle = "Success"
            alertMessage = "Reservation added successfully!"
        }

        showAlert = true
    }
}

func areSeatArraysEqual(_ a: [(table: Int, seat: Int)], _ b: [(table: Int, seat: Int)]) -> Bool {
    let sortedA = a.sorted { $0.table != $1.table ? $0.table < $1.table : $0.seat < $1.seat }
    let sortedB = b.sorted { $0.table != $1.table ? $0.table < $1.table : $0.seat < $1.seat }
    return sortedA.elementsEqual(sortedB, by: { $0.table == $1.table && $0.seat == $1.seat })
}
