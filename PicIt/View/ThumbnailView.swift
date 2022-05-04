//

import SwiftUI

// typealias Action = () -> Void

struct ThumbnailImageView: View {
    static let log = PicItSelfLog<ThumbnailImageView>.get()
    
    let thumbnail: UIImage
    let shareItem: Any
    let localId: String
    let shareAction: NoArgClosure<Void>
    let deleteAction: NoArgClosure<Void>
        
    @State private var showOutputModal = false

    var body: some View {
        Image(uiImage: thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .gesture(TapGesture().onEnded({_ in
                Self.log.debug("Tapped Image with id: \(localId)")
                self.showOutputModal.toggle()
            }))
            .sheet(isPresented: $showOutputModal) {
                OutputHandlerView(
                    showModal: $showOutputModal,
                    thumbnail: thumbnail,
                    shareItem: shareItem,
                    mediaLocalId: localId, // used to identify item to be deleted
                    shareAction: shareAction,
                    deleteAction: deleteAction)
            }
        // .animation(.spring())
    }
}

// Empty view also has no actions associated with it
struct ThumbnailEmptyView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundColor(.picit.gray)
    }
}

struct ThumbnailView: View {
    
    let thumbnailImage: UIImage?
    let shareItem: Any?
    let localId: String?
    let shareAction: NoArgClosure<Void>
    let deleteAction: NoArgClosure<Void>
    
    var body: some View {
        Group {
            
            if thumbnailImage != nil {
                let mediaLocalId = localId ?? ""
                ThumbnailImageView(
                    thumbnail: thumbnailImage!,
                    shareItem: shareItem!,
                    localId: mediaLocalId, // used to find resource to delete
                    shareAction: shareAction,
                    deleteAction: deleteAction)
            } else {
                ThumbnailEmptyView()
            }
        }
        .frame(width: 60, height: 60)
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static let image = UIImage(systemName: "photo")!
    
    static var previews: some View {
        ThumbnailView(thumbnailImage: nil, shareItem: nil, localId: "AppIcon", shareAction: {}, deleteAction: {})
        ThumbnailView(thumbnailImage: image, shareItem: image, localId: "AppIcon", shareAction: {}, deleteAction: {})
    }
}
