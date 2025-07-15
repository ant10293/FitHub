//
//  HealthKit.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//
/*
import SwiftUI

struct HealthKitSettings: View {
    @EnvironmentObject var ctx: AppContext

    var body: some View {
        //ZStack {
           // Color(UIColor.secondarySystemBackground)
           //     .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Button(action: {
                    ctx.healthKit.requestAuth(userData: ctx.userData, inSetupMode: false)
                }) {
                    Text(ctx.userData.settings.allowedHKPermission ? "Reinitialize HealthKit" : "Initialize HealthKit")
                        .foregroundColor(.white)
                        .padding()
                        .background(ctx.userData.settings.allowedHKPermission ? Color.gray : Color.blue)
                        //.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .navigationBarTitle("HealthKit Settings", displayMode: .inline)
       // }
    }
}
*/
