//
// PrivMX Endpoint Swift
// Copyright © 2026 Simplito sp. z o.o.
//
// This file is part of PrivMX Platform (https://privmx.dev).
// This software is Licensed under the MIT License.
//
// See the License for the specific language governing permissions and
// limitations under the License.
//

import PrivMXEndpointSwiftNative
import PrivMXEndpointSwift
import Foundation
import WebRTC

public enum StreamsError: Error {
	case failedCreatingPeerConnection(privmx.InternalError)
	case failedInstancingStreamApi(privmx.InternalError)
	case failedCreatingStreamRoom(privmx.InternalError)
	case failedJoiningStreamRoom(privmx.InternalError)
	case failedLeavingStreamRoom(privmx.InternalError)
	case failedUpdatingStreamRoom(privmx.InternalError)
	case failedDeletingStreamRoom(privmx.InternalError)
	
	case failedAddingTrack(privmx.InternalError)
	case failedRemovingTrack(privmx.InternalError)
	case failedPublishingStream(privmx.InternalError)
	case failedUnpublishingStream(privmx.InternalError)
	
	case failedSubscribingForRemoteStreams(privmx.InternalError)
	case failedUnsubscribingFromRemoteStreams(privmx.InternalError)
	case failedModyfyingRemoteStreamsSubscriptions(privmx.InternalError)
	
}
