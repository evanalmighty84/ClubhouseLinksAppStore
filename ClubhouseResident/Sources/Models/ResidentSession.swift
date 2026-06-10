import Foundation
import SwiftUI

class ResidentSession: ObservableObject {

    @Published var residentId: Int = 0
    @Published var neighborhoodId: Int = 0
    @Published var neighborhoodName: String = ""

}