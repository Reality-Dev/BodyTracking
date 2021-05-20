//
//  ContentView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 2/8/21.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @EnvironmentObject var data: DataModel
    var body: some View {

        ScrollView() {
            ARButton(arChoice: .face, name: "Face Tracking")
                .padding()
            ARButton(arChoice: .handTracking, name: "Hand Tracking")
                .padding()
            ARButton(arChoice: .twoD, name: "2D")
                .padding()
            ARButton(arChoice: .threeD, name: "3D")
                .padding()
            ARButton(arChoice: .bodyTrackedEntity, name: "Character Animation")
                .padding()
            ARButton(arChoice: .peopleOcclusion, name: "People Occlusion")
                .padding()
        }
    }
}


struct ARButton: View {
    @EnvironmentObject var model : DataModel
        
    @State var isPresented = false
        var arChoice: ARChoice
        var name : String
        
        var body: some View {
        Button(action: {
            DataModel.shared.selection = arChoice.rawValue
            isPresented.toggle()
        }, label: {
            Text("Show \(name)")
                .frame(width: 200, height: 100, alignment: .center)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(20)
        })
        .fullScreenCover(isPresented: $isPresented) {
            ZStack {
            ARViewContainer.shared.edgesIgnoringSafeArea(.all).onDisappear(){
                print("on Dissapear")
                DataModel.shared.arView = nil
            }
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Image(systemName: "chevron.backward")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding()
                })
                .position(x: 20, y: 10)
            }
        }
    }
}



struct ARViewContainer: UIViewRepresentable {
    static var shared = ARViewContainer()
    func makeUIView(context: Context) -> ARView {
        return DataModel.shared.arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}





#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DataModel.shared)
    }
}
#endif
