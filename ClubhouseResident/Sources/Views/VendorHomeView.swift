import SwiftUI

struct VendorHomeView: View {
    @AppStorage("vendorCompanyName")
    private var vendorCompanyName = ""

    @AppStorage("vendorCategory")
    private var vendorCategory = ""

    @AppStorage("residentSelectedTab")
    private var selectedTab = "home"

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text(
                            vendorCompanyName.isEmpty
                                ? "Vendor Account"
                                : vendorCompanyName
                        )
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                        if !vendorCategory.isEmpty {
                            Text(vendorCategory)
                                .font(.headline)
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(.top, 18)

                    VStack(spacing: 16) {
                        Image(
                            systemName:
                                "bell.badge.fill"
                        )
                        .font(.system(size: 54))
                        .foregroundStyle(.cyan)

                        Text("Resident Service Requests")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(
                            "New requests from residents will be delivered to your Contact inbox."
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(0.72)
                        )
                        .multilineTextAlignment(.center)

                        Button {
                            selectedTab = "contact"
                        } label: {
                            Label(
                                "Open Request Inbox",
                                systemImage:
                                    "tray.full.fill"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(
                                    colors: [
                                        .cyan,
                                        .purple
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18
                                )
                            )
                        }
                    }
                    .padding(22)
                    .background(
                        .white.opacity(0.07)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 28
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 28
                        )
                        .stroke(
                            .cyan.opacity(0.45),
                            lineWidth: 1
                        )
                    )

                    Spacer(minLength: 120)
                }
                .padding()
            }
        }
        .onAppear {
            VendorPushRegistration.syncStoredToken()
        }
    }
}
