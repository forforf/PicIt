//

import SwiftUI
import os.log

// typealias Action = () -> Void

struct ThumbnailImageView: View {
    static let log = Logger(subsystem: "us.joha.PicIt", category: "ThumbnailImageView")
    
    let image: UIImage
    let localId: String
    let shareAction: NoArgClosure<Void>
    let deleteAction: NoArgClosure<Void>
        
    @State private var showOutputModal = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .gesture(TapGesture().onEnded({_ in
                Self.log.debug("Tapped Image with id: \(localId)")
                self.showOutputModal.toggle()
            }))
            .sheet(isPresented: $showOutputModal) {
                OutputHandlerView(showModal: $showOutputModal, uiImage: image, photoLocalId: localId, shareAction: shareAction, deleteAction: deleteAction)
            }
        // .animation(.spring())
    }
}

// Empty view also has no actions associated with it
struct ThumbnailEmptyView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(width: 60, height: 60, alignment: .center)
            .foregroundColor(.yellow)
    }
}

struct ThumbnailView: View {
    
    let photo: Photo?
    let localId: String?
    let shareAction: NoArgClosure<Void>
    let deleteAction: NoArgClosure<Void>
    
    var body: some View {
        Group {
            
            if photo?.image != nil {
                let photoLocalId = localId ?? ""
                ThumbnailImageView(image: photo!.image!, localId: photoLocalId, shareAction: shareAction, deleteAction: deleteAction)
            } else {
                ThumbnailEmptyView()
            }
        }
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("TBD")
//        ThumbnailView(photo: nil, localId: "AppIcon", shareAction: {})
    }
}
