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

import Foundation
import WebRTC
import PrivMXEndpointSwiftNative

public struct DataChannelMeta: Hashable{
	var name: String
	// TODO: fill Data Channel Metadata or remove
}

public struct AudioTrackInfo{
	public var track: RTCAudioTrack
	public var sender: RTCRtpSender
	public var frameCryptor: PMXFrameCryptorTransformer
	public var frameCryptorDelegate: PMXFrameCryptorObserver?
}

public struct VideoTrackInfo{
	public var track: RTCVideoTrack
	public var sender: RTCRtpSender
	public var frameCryptor: PMXFrameCryptorTransformer
	public var frameCryptorDelegate: PMXFrameCryptorObserver?
}
