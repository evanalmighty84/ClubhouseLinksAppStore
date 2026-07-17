import SwiftUI

struct StartServiceView: View {
    @State private var selectedService = "Painting"
    @State private var selectedSubService = "Interior Painting"

    private let services = [
        "Painting",
        "Roofing",
        "Pool Service",
        "Landscaping",
        "Plumbing",
        "Electrical",
        "Cleaning",
        "General Contractor"
    ]

    private var subServices: [String] {
        switch selectedService {
        case "Painting":
            return ["Interior Painting", "Exterior Painting", "Cabinets", "Drywall Repair", "Fence Staining"]
        case "Roofing":
            return ["Roof Repair", "Roof Replacement", "Inspection", "Gutters"]
        case "Pool Service":
            return ["Weekly Service", "Pool Repair", "Leak Detection", "Equipment Replacement"]
        case "Landscaping":
            return ["Lawn Care", "Tree Trimming", "Flower Beds", "Irrigation"]
        case "Plumbing":
            return ["Leak Repair", "Water Heater", "Drain Cleaning", "Fixture Install"]
        case "Electrical":
            return ["Light Install", "Outlet Repair", "Panel Work", "Ceiling Fan"]
        case "Cleaning":
            return ["House Cleaning", "Deep Cleaning", "Move Out Cleaning", "Window Cleaning"]
        default:
            return ["General Repair", "Remodeling", "Handyman", "Project Estimate"]
        }
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Start a Service")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Choose what you need help with and we’ll guide you to the right local vendor.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Service")
                            .font(.headline)
                            .foregroundStyle(.cyan)

                        Picker("Service", selection: $selectedService) {
                            ForEach(services, id: \.self) { service in
                                Text(service).tag(service)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        Text("Sub Service")
                            .font(.headline)
                            .foregroundStyle(.cyan)

                        Picker("Sub Service", selection: $selectedSubService) {
                            ForEach(subServices, id: \.self) { subService in
                                Text(subService).tag(subService)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        Button {
                            print("Selected service:", selectedService)
                            print("Selected sub service:", selectedSubService)
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.cyan, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.cyan.opacity(0.45), lineWidth: 1)
                    )

                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .onChange(of: selectedService) { _ in
            selectedSubService = subServices.first ?? ""
        }
    }
}