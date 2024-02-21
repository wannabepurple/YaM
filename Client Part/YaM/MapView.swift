import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
//    @State var camera: MapCameraPosition = .automatic
    
    var body: some View {
        Map(coordinateRegion: $viewModel.region, showsUserLocation: true)
            .ignoresSafeArea()
            .accentColor(.purple)
            .onAppear {
                viewModel.checkLocationServisesEnabled()
            }
    }
}


//#Preview {
//    ContentView()
//}
