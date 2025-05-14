import SwiftUI

struct Seat: Identifiable, Equatable {
    let id = UUID()
    let seatNumber: Int
    var isSelected: Bool = false
    var isOccupied: Bool = false
}

struct Table: Identifiable {
    let id = UUID()
    let tableNumber: Int
    var seats: [Seat]
}

struct SelectSeatView: View {
    @EnvironmentObject var reservationStore: ReservationStore
    @Binding var selectedSeats: [(table: Int, seat: Int)]
    let numberOfGuests: Int

    @State private var tables: [Table] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 修改 onComplete 以在 init 中赋值
    // 移除默认实现，它将由 SeatSelectionWrapper 提供
    let onComplete: ([(table: Int, seat: Int)]) -> Void

    init(numberOfGuests: Int, selectedSeats: Binding<[(table: Int, seat: Int)]>, onComplete: @escaping ([(table: Int, seat: Int)]) -> Void) {
        print("DEBUG: SelectSeatView init with \(numberOfGuests) guests. onComplete callback is being set.")
        self.numberOfGuests = numberOfGuests
        self._selectedSeats = selectedSeats
        self.onComplete = onComplete // 保存从父视图传递过来的回调
        
        var tempTables: [Table] = []
        for tableNum in 1...10 {
            var seats: [Seat] = []
            for seatNum in 1...4 {
                seats.append(Seat(seatNumber: seatNum))
            }
            tempTables.append(Table(tableNumber: tableNum, seats: seats))
        }
        _tables = State(initialValue: tempTables)
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var selectedCount: Int {
        let count = tables.reduce(0) { $0 + $1.seats.filter { $0.isSelected }.count }
        print("DEBUG: Currently selected seat count: \(count)")
        return count
    }

    private var remainingSeats: Int {
        numberOfGuests - selectedCount
    }

    private var canConfirm: Bool {
        selectedCount == numberOfGuests
    }

    var body: some View {
        VStack {
            Text("Select \(numberOfGuests) seats")
                .font(.headline)
                .padding(.top)
            
            Text("Currently selected: \(selectedCount)/\(numberOfGuests)")
                .font(.caption)
                .foregroundColor(selectedCount == numberOfGuests ? .green : .orange)
                .padding(.bottom, 5)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(tables.indices, id: \.self) { index in
                        TableView(table: $tables[index], reservationStore: reservationStore, selectedCount: selectedCount, maxSelection: numberOfGuests)
                    }
                }
                .padding()
            }
            
            Text("Red seats are already occupied")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.bottom, 2)
                
            Text("Blue seats are your selection")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.bottom, 5)

            // 确认选择按钮
            Button(action: {
                print("DEBUG: Confirm selection button pressed")
                confirmSelection()
            }) {
                Text(remainingSeats > 0 ?
                     "Select \(remainingSeats) more seat(s)" :
                     "Confirm Selection")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canConfirm ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .disabled(!canConfirm)
        }
        .navigationTitle("Seat Selection")
        .onAppear {
            print("DEBUG: SelectSeatView appeared")
            checkOccupiedSeats()
        }
        .onDisappear {
            print("DEBUG: SelectSeatView disappeared")
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Seat Selection Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func checkOccupiedSeats() {
        print("DEBUG: Checking occupied seats")
        for tableIndex in tables.indices {
            for seatIndex in tables[tableIndex].seats.indices {
                let tableNum = tables[tableIndex].tableNumber
                let seatNum = tables[tableIndex].seats[seatIndex].seatNumber
                let isOccupied = reservationStore.isSeatOccupied(table: tableNum, seat: seatNum)
                tables[tableIndex].seats[seatIndex].isOccupied = isOccupied
                
                if isOccupied {
                    print("DEBUG: Seat \(tableNum)-\(seatNum) is occupied")
                }

                if selectedSeats.contains(where: { $0.table == tableNum && $0.seat == seatNum }) {
                    tables[tableIndex].seats[seatIndex].isSelected = true
                    print("DEBUG: Seat \(tableNum)-\(seatNum) is pre-selected")
                }
            }
        }
    }

    private func confirmSelection() {
        print("DEBUG: Confirming selection of \(selectedCount) seats")
        
        // 验证选择的座位数量
        if selectedCount != numberOfGuests {
            errorMessage = "Please select exactly \(numberOfGuests) seat(s)."
            showErrorAlert = true
            return
        }
        
        // 更新选定的座位
        let updatedSeats = tables.flatMap { table in
            table.seats.filter { $0.isSelected }.map { (table.tableNumber, $0.seatNumber) }
        }
        print("DEBUG: Selected seats: \(updatedSeats)")
        selectedSeats = updatedSeats // 更新绑定状态，这将更新 SeatSelectionWrapper 中的状态
        
        // 触发完成回调，通知父视图处理完成动作
        self.onComplete(updatedSeats) // 调用从 SeatSelectionWrapper 传递过来的回调
        
        print("DEBUG: Selection confirmed, selectedSeats updated. Called onComplete.")
    }
}

struct TableView: View {
    @Binding var table: Table
    @ObservedObject var reservationStore: ReservationStore
    let selectedCount: Int
    let maxSelection: Int

    var body: some View {
        VStack(spacing: 10) {
            Text("Table \(table.tableNumber)")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 15) {
                ForEach(table.seats.indices, id: \.self) { seatIndex in
                    let seat = table.seats[seatIndex]
                    SeatView(seat: seat)
                        .onTapGesture {
                            print("DEBUG: Seat \(table.tableNumber)-\(seat.seatNumber) tapped, occupied: \(seat.isOccupied), selected: \(seat.isSelected)")
                            if !seat.isOccupied {
                                if seat.isSelected {
                                    table.seats[seatIndex].isSelected = false
                                    print("DEBUG: Deselected seat \(table.tableNumber)-\(seat.seatNumber)")
                                } else if selectedCount < maxSelection {
                                    table.seats[seatIndex].isSelected = true
                                    print("DEBUG: Selected seat \(table.tableNumber)-\(seat.seatNumber)")
                                } else {
                                    print("DEBUG: Cannot select more seats, already at max (\(maxSelection))")
                                }
                            } else {
                                print("DEBUG: Cannot select occupied seat \(table.tableNumber)-\(seat.seatNumber)")
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SeatView: View {
    let seat: Seat

    var body: some View {
        Circle()
            .fill(seat.isOccupied ? Color.red : (seat.isSelected ? Color.blue : Color.green))
            .frame(width: 40, height: 40)
            .overlay(
                Text("\(seat.seatNumber)")
                    .foregroundColor(.white)
                    .bold()
            )
            .opacity(seat.isOccupied ? 0.6 : 1)
            .animation(.easeInOut, value: seat.isSelected)
            .animation(.easeInOut, value: seat.isOccupied)
    }
}
