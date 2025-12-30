//
//  CalendarView.swift
//  postura
//
//  Created by YunHao Dong on 12/29/25.
//
import SwiftUI

struct CalendarSheetView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding()

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            Spacer()
        }
        .presentationDetents([.medium])
    }
}
