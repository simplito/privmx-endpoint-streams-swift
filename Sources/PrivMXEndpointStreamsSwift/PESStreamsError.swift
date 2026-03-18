//
// PrivMX Endpoint Streams Swift
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

public enum PESStreamsError: Error {
	case failedInstancingStreamApi(privmx.InternalError)
	
	case failedCreatingStreamRoom(privmx.InternalError)
	case failedJoiningStreamRoom(privmx.InternalError)
	case failedLeavingStreamRoom(privmx.InternalError)
	case failedUpdatingStreamRoom(privmx.InternalError)
	case failedDeletingStreamRoom(privmx.InternalError)
	case failedGettingStreamRoom(privmx.InternalError)
	case failedListingStreamRooms(privmx.InternalError)
	
	case failedCreatingPeerConnection(privmx.InternalError)
	
	case failedAddingTrack(privmx.InternalError)
	case failedRemovingTrack(privmx.InternalError)
	
	case failedCreatingStream(privmx.InternalError)
	case failedPublishingStream(privmx.InternalError)
	case failedUpdatingStream(privmx.InternalError)
	case failedUnpublishingStream(privmx.InternalError)
	case failedListingStreams(privmx.InternalError)
	
	case failedSubscribingToRemoteStreams(privmx.InternalError)
	case failedUnsubscribingFromRemoteStreams(privmx.InternalError)
	case failedModyfyingRemoteStreamsSubscriptions(privmx.InternalError)
	
	case failedGettingTurnCredentials(privmx.InternalError)
	
	case failedSettingNewOfferOnReconfigure(privmx.InternalError)
	case failedAcceptingOfferOnReconfigure(privmx.InternalError)
	
	case failedSettingDropBrokenFramesOption(privmx.InternalError)
	
	case failedReconfiguringPeer(privmx.InternalError)
	
	case failedCreatingDesktopCapturer(privmx.InternalError)
	
	
	public func getName(
	) -> String {
		switch self{
			case .failedAcceptingOfferOnReconfigure(let e),
					.failedInstancingStreamApi(let e),
					.failedCreatingStreamRoom(let e),
					.failedJoiningStreamRoom(let e),
					.failedLeavingStreamRoom(let e),
					.failedUpdatingStreamRoom(let e),
					.failedDeletingStreamRoom(let e),
					.failedGettingStreamRoom(let e),
					.failedListingStreamRooms(let e),
					.failedCreatingPeerConnection(let e),
					.failedAddingTrack(let e),
					.failedRemovingTrack(let e),
					.failedCreatingStream(let e),
					.failedPublishingStream(let e),
					.failedUpdatingStream(let e),
					.failedUnpublishingStream(let e),
					.failedListingStreams(let e),
					.failedSubscribingToRemoteStreams(let e),
					.failedUnsubscribingFromRemoteStreams(let e),
					.failedModyfyingRemoteStreamsSubscriptions(let e),
					.failedGettingTurnCredentials(let e),
					.failedSettingNewOfferOnReconfigure(let e),
					.failedReconfiguringPeer(let e),
					.failedCreatingDesktopCapturer(let e),
					.failedSettingDropBrokenFramesOption(let e):
				String(e.name)
				
		}
	}
	public func getDescription(
	) -> String {
		switch self{
			case .failedAcceptingOfferOnReconfigure(let e),
					.failedInstancingStreamApi(let e),
					.failedCreatingStreamRoom(let e),
					.failedJoiningStreamRoom(let e),
					.failedLeavingStreamRoom(let e),
					.failedUpdatingStreamRoom(let e),
					.failedDeletingStreamRoom(let e),
					.failedGettingStreamRoom(let e),
					.failedListingStreamRooms(let e),
					.failedCreatingPeerConnection(let e),
					.failedAddingTrack(let e),
					.failedRemovingTrack(let e),
					.failedCreatingStream(let e),
					.failedPublishingStream(let e),
					.failedUpdatingStream(let e),
					.failedUnpublishingStream(let e),
					.failedListingStreams(let e),
					.failedSubscribingToRemoteStreams(let e),
					.failedUnsubscribingFromRemoteStreams(let e),
					.failedModyfyingRemoteStreamsSubscriptions(let e),
					.failedGettingTurnCredentials(let e),
					.failedSettingNewOfferOnReconfigure(let e),
					.failedReconfiguringPeer(let e),
					.failedCreatingDesktopCapturer(let e),
					.failedSettingDropBrokenFramesOption(let e):
				String(e.description)
				
		}
	}
	public func getMessage(
	) -> String {
		switch self{
			case .failedAcceptingOfferOnReconfigure(let e),
					.failedInstancingStreamApi(let e),
					.failedCreatingStreamRoom(let e),
					.failedJoiningStreamRoom(let e),
					.failedLeavingStreamRoom(let e),
					.failedUpdatingStreamRoom(let e),
					.failedDeletingStreamRoom(let e),
					.failedGettingStreamRoom(let e),
					.failedListingStreamRooms(let e),
					.failedCreatingPeerConnection(let e),
					.failedAddingTrack(let e),
					.failedRemovingTrack(let e),
					.failedCreatingStream(let e),
					.failedPublishingStream(let e),
					.failedUpdatingStream(let e),
					.failedUnpublishingStream(let e),
					.failedListingStreams(let e),
					.failedSubscribingToRemoteStreams(let e),
					.failedUnsubscribingFromRemoteStreams(let e),
					.failedModyfyingRemoteStreamsSubscriptions(let e),
					.failedGettingTurnCredentials(let e),
					.failedSettingNewOfferOnReconfigure(let e),
					.failedReconfiguringPeer(let e),
					.failedCreatingDesktopCapturer(let e),
					.failedSettingDropBrokenFramesOption(let e):
				String(e.message)
				
		}
	}
	
	public func getCode(
	) -> UInt32? {
		switch self{
			case .failedAcceptingOfferOnReconfigure(let e),
					.failedInstancingStreamApi(let e),
					.failedCreatingStreamRoom(let e),
					.failedJoiningStreamRoom(let e),
					.failedLeavingStreamRoom(let e),
					.failedUpdatingStreamRoom(let e),
					.failedDeletingStreamRoom(let e),
					.failedGettingStreamRoom(let e),
					.failedListingStreamRooms(let e),
					.failedCreatingPeerConnection(let e),
					.failedAddingTrack(let e),
					.failedRemovingTrack(let e),
					.failedCreatingStream(let e),
					.failedPublishingStream(let e),
					.failedUpdatingStream(let e),
					.failedUnpublishingStream(let e),
					.failedListingStreams(let e),
					.failedSubscribingToRemoteStreams(let e),
					.failedUnsubscribingFromRemoteStreams(let e),
					.failedModyfyingRemoteStreamsSubscriptions(let e),
					.failedGettingTurnCredentials(let e),
					.failedSettingNewOfferOnReconfigure(let e),
					.failedReconfiguringPeer(let e),
					.failedCreatingDesktopCapturer(let e),
					.failedSettingDropBrokenFramesOption(let e):
				e.code.value
		}
	}
	
	public func getscope(
	) -> String? {
		switch self{
			case .failedAcceptingOfferOnReconfigure(let e),
					.failedInstancingStreamApi(let e),
					.failedCreatingStreamRoom(let e),
					.failedJoiningStreamRoom(let e),
					.failedLeavingStreamRoom(let e),
					.failedUpdatingStreamRoom(let e),
					.failedDeletingStreamRoom(let e),
					.failedGettingStreamRoom(let e),
					.failedListingStreamRooms(let e),
					.failedCreatingPeerConnection(let e),
					.failedAddingTrack(let e),
					.failedRemovingTrack(let e),
					.failedCreatingStream(let e),
					.failedPublishingStream(let e),
					.failedUpdatingStream(let e),
					.failedUnpublishingStream(let e),
					.failedListingStreams(let e),
					.failedSubscribingToRemoteStreams(let e),
					.failedUnsubscribingFromRemoteStreams(let e),
					.failedModyfyingRemoteStreamsSubscriptions(let e),
					.failedGettingTurnCredentials(let e),
					.failedSettingNewOfferOnReconfigure(let e),
					.failedReconfiguringPeer(let e),
					.failedCreatingDesktopCapturer(let e),
					.failedSettingDropBrokenFramesOption(let e):
				if let v = e.scope.value{
					return String(v)
				}
				return nil
		}
	}
}
