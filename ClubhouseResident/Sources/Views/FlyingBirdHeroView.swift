import SwiftUI

struct FlyingBirdHeroView: View {
    let completedProjects: [ResidentCompletedProject]
    let completedProjectsLoading: Bool
    let completedProjectsError: String

    @State private var isLaunchingService = false
    @State private var showStartService = false

    init(
    completedProjects: [ResidentCompletedProject] = [],
    completedProjectsLoading: Bool = false,
    completedProjectsError: String = ""
    ) {
        self.completedProjects = completedProjects
        self.completedProjectsLoading = completedProjectsLoading
        self.completedProjectsError = completedProjectsError
    }

    var body: some View {
        TabView {
            startProjectSlide

            ForEach(completedProjects) { project in
                completedProjectSlide(project)
            }
        }
        .frame(height: 560)
        .tabViewStyle(
            PageTabViewStyle(
                indexDisplayMode:
                completedProjects.isEmpty ? .never : .automatic
            )
        )
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
            .stroke(.cyan.opacity(0.45), lineWidth: 1)
        )
        .navigationDestination(
            isPresented: $showStartService
        ) {
            StartServiceView()
        }
    }

    private var startProjectSlide: some View {
        VStack(spacing: 14) {
            Group {
                if isLaunchingService {

                    /*
                     * KEEP the flying sprite.
                     * This is the transition shown
                     * after Start a Service is tapped.
                     */
                    FlyingBirdSpriteHeroView(
                        birdHeight: 230,
                        glowSize: 250,
                        containerHeight: 260,
                        flyInOffset: -340
                    )
                    .transition(
                        .opacity
                        .combined(with: .scale)
                    )

                } else {

                    /*
                     * New normal Start Your Next
                     * Project animation.
                     *
                     * This replaces the old
                     * waving bird only.
                     */
                    LoopingBirdVideoView(
                        resourceName:
                        "clubhouse-bird-newproject",
                        fileExtension:
                        "mp4"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 260)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 22
                        )
                    )
                    .allowsHitTesting(false)
                    .transition(
                        .opacity
                        .combined(with: .scale)
                    )
                }
            }
            .animation(
                .easeInOut(duration: 0.25),
                value: isLaunchingService
            )

            Text("Start Your Next Project")
            .font(.title.bold())
            .foregroundStyle(.white)

            Text(
                "Choose a service, compare trusted local vendors, and see who your neighbors have used."
            )
            .font(
                .subheadline.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                .white.opacity(0.72)
            )
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(.horizontal, 12)

            Button {
                beginServiceTransition()
            } label: {
                HStack(spacing: 10) {
                    if isLaunchingService {
                        ProgressView()
                        .tint(.white)
                    }

                    Text(
                        isLaunchingService
                        ? "Opening Service Options..."
                        : "Start a Service"
                    )
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            .purple,
                            .orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
                .shadow(
                    color: .cyan.opacity(0.4),
                    radius: 12
                )
            }
            .buttonStyle(.plain)
            .disabled(isLaunchingService)
            .padding(.top, 6)

            if completedProjectsLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    .tint(.cyan)

                    Text(
                        "Loading your completed projects..."
                    )
                }
                .font(.caption.bold())
                .foregroundStyle(
                    .white.opacity(0.7)
                )

            } else if !completedProjectsError.isEmpty {

                Text(completedProjectsError)
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)

            } else if !completedProjects.isEmpty {

                Text(
                    "Swipe to see your completed projects"
                )
                .font(.caption.bold())
                .foregroundStyle(
                    .cyan.opacity(0.95)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(
            .bottom,
            completedProjects.isEmpty ? 0 : 18
        )
    }

    private func completedProjectSlide(
    _ project: ResidentCompletedProject
    ) -> some View {
        VStack(spacing: 16) {
            Text("Your Completed Project")
            .font(.title2.bold())
            .foregroundStyle(.white)

            projectImage(project)

            VStack(spacing: 7) {
                Text(
                    project.vendor_name ??
                    "Vendor"
                )
                .font(.title3.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                Text(
                    project.service ??
                    "Service"
                )
                .font(.headline.bold())
                .foregroundStyle(.cyan)

                approvalBadge(
                    project.approval_status ??
                    "pending_review"
                )

                if let reason =
                project.photo_rejection_reason,
                !reason.isEmpty {

                    Text(reason)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                }
            }

            Text(
                "Swipe to return to Start a Service"
            )
            .font(.caption.bold())
            .foregroundStyle(
                .white.opacity(0.65)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private func projectImage(
    _ project: ResidentCompletedProject
    ) -> some View {

        if let imageUrl =
        project.image_url,
        !imageUrl.isEmpty,
        let url =
        URL(string: imageUrl) {

            AsyncImage(
                url: url
            ) { image in

                image
                .resizable()
                .scaledToFill()

            } placeholder: {

                projectImagePlaceholder
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 300)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )

        } else {

            projectImagePlaceholder
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 300)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )
        }
    }

    private var projectImagePlaceholder:
    some View {

        ZStack {
            RoundedRectangle(
                cornerRadius: 22
            )
            .fill(
                .black.opacity(0.25)
            )

            VStack(spacing: 10) {
                Image(
                    systemName:
                    "photo.on.rectangle.angled"
                )
                .font(
                    .system(size: 34)
                )
                .foregroundStyle(.cyan)

                Text("Project photo")
                .font(.caption.bold())
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }
        }
    }

    private func approvalBadge(
    _ status: String
    ) -> some View {

        let normalizedStatus =
        status
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .lowercased()

        let label: String
        let color: Color

        switch normalizedStatus {

        case "approved":
            label = "Approved"
            color = .green

        case "rejected":
            label = "Rejected"
            color = .red

        default:
            label = "Pending Review"
            color = .orange
        }

        return Text(label)
        .font(.caption.bold())
        .foregroundStyle(color)
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            6
        )
        .background(
            color.opacity(0.15)
        )
        .clipShape(Capsule())
    }

    private func beginServiceTransition() {
        guard !isLaunchingService else {
            return
        }

        withAnimation(
            .easeInOut(duration: 0.25)
        ) {
            isLaunchingService = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.0
        ) {
            isLaunchingService = false
            showStartService = true
        }
    }
}