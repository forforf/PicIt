//
import SwiftUI

// TODO: Remove this dependency
import PhotosUI


typealias ShareAction = () -> Void
typealias PhotoDeletionCompletion = (Bool, Error?) -> Void

struct ShareImageSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
    
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

struct OutputHandlerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showShareSheet = false
    @Binding var showModal: Bool
    
    let uiImage: UIImage?
    let photoLocalId: String
    
        
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
                Button(action: {
                    //                    ShareViewController.shareCompletion(uiImage!)
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .font(.title)
                .padding()
                Button(action: {
                    
                    let deleteCompletion: PhotoDeletionCompletion = { (_, _) in
                        print("Photo deleted")
                        showModal = false
                    }
                    
                    print("TODO: Delete Photo: \(photoLocalId)")
                    //TODO: fetching and deleting should be done in service, not here
                    DispatchQueue.main.async {
                        
                        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoLocalId], options: nil)
                        print(assets)
                        
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.deleteAssets(assets)
                        }, completionHandler: deleteCompletion)
                    }
                    // Possible deletion code
//                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//                                    PHAssetChangeRequest.deleteAssets([self.asset!] as NSArray)
//                                    }, completionHandler: completionHandler)
                }) {
                    Image(systemName: "trash")
                }
                .font(.title)
                .padding()
            }
            
            Spacer()
            
            Text("Swipe down to dismiss")
            
        }
        .sheet(isPresented: $showShareSheet) {
            if uiImage != nil {
                ShareImageSheet(activityItems: [uiImage as Any])
            }
            
        }
    }
}

struct OutputHandlerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
      @State var showModal: Bool = false

      var body: some View {
          OutputHandlerView(showModal: $showModal, uiImage: UIImage(named: "AppIcon"), photoLocalId: "AppIcon")
      }
    }
    static var previews: some View {
        PreviewWrapper()
    }
}
