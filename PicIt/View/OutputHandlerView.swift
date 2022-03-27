//
import SwiftUI

// TODO: Remove this dependency
import PhotosUI

typealias PhotoDeletionCompletion = (Bool, Error?) -> Void

struct ShareImageSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let callback: Callback?
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}

extension ShareImageSheet {
    
}

struct OutputHandlerView: View {
    static let log = PicItSelfLog<OutputHandlerView>.get()
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showShareSheet = false
    @Binding var showModal: Bool
    
    let uiImage: UIImage?
    let photoLocalId: String
    let shareAction: NoArgClosure<Void>?
    let deleteAction: NoArgClosure<Void>?
       
    var body: some View {
        VStack {
            if uiImage != nil {
                Image(uiImage: uiImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            HStack {
                
                // Share Button
                Button(action: {
                    showShareSheet = true
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                })
                .font(.title)
                .padding()
                
                // Delete Button
                Button(action: {
                    let deleteCompletion: PhotoDeletionCompletion = { (_, _) in
                        Self.log.debug("Photo deleted from inside closure")
                        showModal = false
                        deleteAction?()
                    }
                    
                    // TODO: fetching and deleting should be done in service, not here
                    DispatchQueue.main.async {
                        
                        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoLocalId], options: nil)
                        Self.log.debug("Fetched photo handler assets: \(String(describing: assets))")
                        
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.deleteAssets(assets)
                        }, completionHandler: deleteCompletion)
                    }

                }, label: {
                    Image(systemName: "trash")
                })
                .font(.title)
                .padding()
            }
            
            Spacer()
            
            Text("Swipe down to dismiss")
            
        }
        .sheet(isPresented: $showShareSheet) {
            let shareCallback: ShareImageSheet.Callback = { (activityType: UIActivity.ActivityType?, completed: Bool, _: [Any]?, _: Error?) in
                Self.log.debug("Share Callback in share sheet closure")
                Self.log.debug("  \(activityType.debugDescription)")
                Self.log.debug("  \(completed)")

                shareAction?()
            }
            if uiImage != nil {
                ShareImageSheet(activityItems: [uiImage as Any], callback: shareCallback)
            }
            
        }
    }
}

struct OutputHandlerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
      @State var showModal: Bool = false

      var body: some View {
          Text("TBD")
//          OutputHandlerView(showModal: $showModal, uiImage: UIImage(named: "AppIcon"), photoLocalId: "AppIcon")
      }
    }
    static var previews: some View {
        PreviewWrapper()
    }
}
