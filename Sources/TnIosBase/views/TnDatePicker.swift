//
//  TnDatePicker.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/11/21.
//

import SwiftUI

struct TnDatePicker: View {
    var title: String = "Select date"
    
    @Binding var value: Date
    var from: Date? = nil
    var to: Date? = nil
    var format: String = Date.Format.date.rawValue
    var displayedComponents: DatePickerComponents = .date
    var validator: ((Date) -> Bool)? = nil

    @State private var showPicker: Bool = false
    @State private var internalValue: Date = .now()

//    private var selectedDate: Binding<Date> {
//        Binding<Date>(
//            get: { self.value },
//            set : {
//                self.value = $0
//                self.setDateString()
//            }
//        )
//    } // This private var I found… somewhere. I wish I could remember where
    
    func getDatePicker() -> DatePicker<Text> {
        if from != nil && to != nil {
            return DatePicker("", selection: $internalValue, in: from!...to!, displayedComponents: displayedComponents)
        } else if from != nil {
            return DatePicker("", selection: $internalValue, in: PartialRangeFrom(from!), displayedComponents: displayedComponents)
        } else if to != nil {
            return DatePicker("", selection: $internalValue, in: PartialRangeThrough(to!), displayedComponents: displayedComponents)
        } else {
            return DatePicker("", selection: $internalValue, displayedComponents: displayedComponents)
        }
    }
    
    var body: some View {
        Text(value.toString(format))
            .bold()
            .padding(.all, 8)
            .foregroundColor(.blue)
//            .background(Color.background85)
//            .cornerRadius(4)
            .onTapGesture {
                showPicker.toggle()
            }
            .onAppear {
                internalValue = value
            }
            .sheet(isPresented: $showPicker) {
                VStack {
                    tnText(title).bold()
                    Divider()
                    
                    getDatePicker()
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()

                    Divider()
                    HStack {
                        Spacer()
                        tnTextButton("Close") {
                            internalValue = value
                            showPicker = false
                        }
                        tnTextButton("Select") {
                            if validator == nil || validator!(internalValue) {
                                value = internalValue
                            } else {
                                internalValue = value
                            }
                            showPicker = false
                        }
                        Spacer()
                    }

                    Spacer()
                }.padding()
            }
    }
}
