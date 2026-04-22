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
#if os(macOS)
import ScreenCaptureKit
#endif
public class StreamApi: @unchecked Sendable{
	var roomSessionManager: RoomSessionManager!
	
	/// Creates an instance of `StreamApi`.
	///
	/// Note that EventApi passed to this method needs to be made from the same Connection.
	///
	/// - Parameter connection: instance of `Connection`.
	/// - Parameter eventApi: instance of `EventApi`, made from the same `Connection`.
	///
	/// - Throws: if instantiating `StreamApi` fails
	///
	/// - Returns: an instance of `StreamApi`
	public static func create(
		connection: Connection,
		eventApi: inout EventApi,
	) throws -> StreamApi{
		
		let low = privmx.NativeStreamApiLowWrapper.create(connection.cxxApi, &eventApi.cxxApi)
		guard var api = low.result.value
		else{
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly received nil result"
			throw PESStreamsError.failedInstancingStreamApi(err)
		}
		var sa = StreamApi(
			api: api
		)
		try sa.bindRoomSessionManger(
		)
		return sa
	}

	/// Creates an instance of `StreamApi` from a `privmx.NativeStreamApiLowWrapper` instance.
	///
	/// This is intended to be used with PrivMXEndpointSwiftExtra
	///
	/// - Parameter streamApiLow: the instance of privmx.NativeStreamApiLowWrapper, It's meant to be used with the PrivMXEndpointSwiftExtra package.
	///
	/// - Throws: if instantiating `StreamApi` fails.
	///
	/// - Returns: an instance of `StreamApi`.
	public static func create(
		from streamApiLow: privmx.NativeStreamApiLowWrapper
	) throws -> StreamApi{
		var sa = StreamApi(
			api: streamApiLow
		)
		try sa.bindRoomSessionManger(
		)
		return sa
	}
	
	// MARK: - Rooms
	
	/// Creates a new Stream Room in given Context.
	///
	/// - Parameter contextId: ID of the Context to create the Stream Room in.
	/// - Parameter users: array of `UserWithPubKey` objects that indicate who will have access to the Stream Room.
	/// - Parameter managers: array of `UserWithPubKey` objects that indicate who will have access and management rights to the Stream Room.
	/// - Parameter publicMeta: public metadata of the Stream Room that won't be encrypted.
	/// - Parameter privateMeta: private metadata of the Stream Room that will be encrypted.
	/// - Parameter policies: the policies of the Stream Room (pass `nil` to use defaults).
	///
	/// - Throws: when the operation fails.
	///
	/// - Returns: Id of the created Stream Room.
	public func createStreamRoom(
		in contextId: String,
		for users: [privmx.endpoint.core.UserWithPubKey],
		managedBy managers: [privmx.endpoint.core.UserWithPubKey],
		withPublicMeta publicMeta: Data,
		privateMeta: Data,
		policies:privmx.endpoint.core.ContainerPolicy?
	) throws -> String{
		var uv = privmx.UserWithPubKeyVector()
		uv.reserve(users.count)
		for u in users{
			uv.push_back(u)
		}
		
		var mv = privmx.UserWithPubKeyVector()
		mv.reserve(managers.count)
		for m in managers{
			mv.push_back(m)
		}
		
		var op = privmx.OptionalContainerPolicy()
		if let policies{
			op = privmx.makeOptional(policies)
		}
		let res = cxxApi.createStreamRoom(
			std.string(contextId),
			uv,
			mv,
			publicMeta.asBuffer(),
			privateMeta.asBuffer(),
			op)
		guard res.error.value == nil
		else {
			throw PESStreamsError.failedCreatingStreamRoom(res.error.value!)
		}
		guard let result = res.result.value
		else{
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly received nil result"
			throw PESStreamsError.failedCreatingStreamRoom(err)
		}
		
		return String(result)
	}
	
	/// Updates a Stream Room by replacing its values with new ones.
	///
	/// - Parameter streamRoomId: ID of the Stream Room to update.
	/// - Parameter users: array of `UserWithPubKey` objects that indicate who will have access to the Stream Room.
	/// - Parameter managers: array of `UserWithPubKey` objects that indicate who will have access and management rights to the Stream Room.
	/// - Parameter publicMeta: public metadata of the Stream Room that won't be encrypted.
	/// - Parameter privateMeta: private metadata of the Stream Room that will be encrypted.
	/// - Parameter version: current version of the Stream Room to be updated.
	/// - Parameter force: forcibly update the Stream Room by bypassing the version check.
	/// - Parameter forceGenerateNewKey: force regenerating a new key for the Stream Room.
	/// - Parameter policies: the policies of the Stream Room (pass `nil` to use defaults).
	///
	/// - Throws: when the operation fails.
	///
	/// - Returns: Id of the created Stream Room.
	public func updateStreamRoom(
		_ streamRoomId: String,
		replacingUsers users: [privmx.endpoint.core.UserWithPubKey],
		managers: [privmx.endpoint.core.UserWithPubKey],
		publicMeta:Data,
		privateMeta: Data,
		atVersion version: Int64,
		force: Bool,
		forceGenerateNewKey: Bool,
		replacePolicies policies: privmx.endpoint.core.ContainerPolicy?
	) throws -> Void {
		
		var uv = privmx.UserWithPubKeyVector()
		uv.reserve(users.count)
		for u in users{
			uv.push_back(consuming: u)
		}
		
		var mv = privmx.UserWithPubKeyVector()
		mv.reserve(managers.count)
		for m in managers{
			mv.push_back(consuming: m)
		}
		var op = privmx.OptionalContainerPolicy()
		if let policies{
			op = privmx.makeOptional(policies)
		}
		
		let res = cxxApi.updateStreamRoom(
			std.string(streamRoomId),
			uv,
			mv,
			publicMeta.asBuffer(),
			privateMeta.asBuffer(),
			version,
			force,
			forceGenerateNewKey,
			op)
		guard res.error.value == nil else {
			throw PESStreamsError.failedUpdatingStreamRoom(res.error.value!)
		}
	}
	
	/// Gets a list of Stream Rooms in given Context.
	///
	/// - Parameter contextId: Id of the Context to list the Stream Rooms from.
	/// - Parameter query: object holding the parameters of the list query.
	///
	/// - Throws: When the operation fails.
	///
	/// - Returns: an object containing the results of the query.
	public func listStreamRooms(
		from contextId: String,
		basedOn query: privmx.endpoint.core.PagingQuery
	) throws -> privmx.StreamRoomList {
		let res = cxxApi.listStreamRooms(
			std.string(contextId),
			query)
		guard res.error.value == nil else {
			throw PESStreamsError.failedListingStreamRooms(res.error.value!)
		}
		guard let result = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PESStreamsError.failedListingStreamRooms(err)
		}
		return result
	}
	
	/// Gets a single StreamRoom by it's ID
	///
	/// - Parameter streamRoomId: ID of the Stream to be retrieved.
	///
	/// - Throws: when the operation fails.
	///
	/// - Returns: a `StreamRoom` object.
	public func getStreamRoom(
		_ streamRoomId: String
	) throws -> privmx.endpoint.stream.StreamRoom {
		let res = cxxApi.getStreamRoom(std.string(streamRoomId))
		if let err = res.error.value {
			throw PESStreamsError.failedGettingStreamRoom(err)
		}
		guard let result = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PESStreamsError.failedGettingStreamRoom(err)
		}
		return result
	}
	
	/// Deletes a StreamRoom.
	///
	/// - Parameter streamRoomId: Id of the Stream Room to be deleted.
	///
	/// - Throws: when the operation fails.
	public func deleteStreamRoom(
		_ streamRoomId: String
	) throws -> Void {
		let res = cxxApi.deleteStreamRoom(std.string(streamRoomId))
		if let err = res.error.value{
			throw PESStreamsError.failedDeletingStreamRoom(err)
		}
	}
	
	/// Joins a Stream Room.
	///
	/// This is required before any methods involving Streams, such as creating, publishing or subscribing to remote Streams in the Room.
	///
	/// - Parameter streamRoomId: Id of the Stream Room to join.
	/// - Parameter audioTrackHandler: the default handler that will be used for incoming Audio Tracks.
	/// - Parameter videoTrackHandler: the default handler that will be used for incoming Video Tracks.
	///
	/// - Throws: when the operation fails.
	public func joinStreamRoom(
		_ streamRoomId: String,
		audioTrackHandler: ((_ streamId:String,_ track:RTCAudioTrack) -> Void)?,
		videoTrackHandler: ((_ streamId:String,_ track:RTCVideoTrack) -> Void)?
	) throws -> Void {
		var session = try roomSessionManager.addRoomSessionFor(streamRoomId)
		guard let instance = session.webRTCInstance
		else {
			throw PESStreamsError.failedJoiningStreamRoom(
				.init(
					name: "Missing session for room",
					message: "",
					description: ""))
		}
		let res = cxxApi.joinStreamRoom(
			std.string(streamRoomId),
			instance.instance
		)
		if let err = res.error.value{
			roomSessionManager.roomSessions[streamRoomId] = nil
			throw PESStreamsError.failedJoiningStreamRoom(err)
		}
		roomSessionManager.setAudioStreamsHandler(audioTrackHandler)
		roomSessionManager.setVideoStreamsHandler(videoTrackHandler)
	}
	
	/// Leaves the Stream Room and removes associated session.
	///
	/// - Parameter roomId: ID of the room to leave.
	///
	/// - Throws: if the operation fails.
	public func leaveStreamRoom(
		_ roomId: String
	) throws -> Void {
		if let handle = roomSessionManager.roomIdsForHandles.first(where: {$0.value == roomId}){
			roomSessionManager.roomIdsForHandles[handle.key] = nil
		}
		
		let res = cxxApi.leaveStreamRoom(std.string(roomId))
		
		if let err = res.error.value{
			throw PESStreamsError.failedLeavingStreamRoom(err)
		}
		
		roomSessionManager.roomSessions[roomId] = nil
	}
	
	// MARK: - STREAMS
	
	/// Creates a local Stream.
	///
	/// This also creates a RTCPeerConnection for publishing.
	///  Note that `joinStreamRoom(_:)` must have been called before calling this method.
	///
	/// - Parameter streamRoomId: ID of the Stream Room in which to create a Stream.
	/// - Parameter onIceConnectionStateChanged: optional callback for reacting to changes in the Ice Connection state.
	/// - Parameter onPeerConnectionStateChanged: optional callback for reacting to changes in the Peer Connection state.
	/// - Throws: if the operation failed
	///
	/// - Returns: a handle to the local Stream.
	public func createStreamIn(
		_ streamRoomId: String,
		onIceConnectionStateChangedCallback:(@Sendable (RTCPeerConnection,RTCIceConnectionState)->Void)? = nil,
		onPeerConnectionStateChangedCallback:(@Sendable (RTCPeerConnection,RTCPeerConnectionState)->Void)? = nil
	) throws -> privmx.endpoint.stream.StreamHandle {
		guard var publisher = try roomSessionManager.roomSessions[streamRoomId]?.createPublisher()
		else {
			throw PESStreamsError.failedCreatingStream(.init(name: "Missing session", message: "", description: "There is no session for this Room."))
		}
		roomSessionManager.setPublisherRenegCallbacks(streamRoomId)
		publisher.setconnectionStateChangedCallbacks(
			onIceConnectionStateChangedCallback: onIceConnectionStateChangedCallback,
			onPeerConnectionStateChangedCallback: onPeerConnectionStateChangedCallback
		)
		let res = cxxApi.createStream(std.string(streamRoomId))
		guard res.error.value == nil else {
			throw PESStreamsError.failedCreatingStream(res.error.value!)
		}
		guard let streamHandle = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PESStreamsError.failedCreatingStream(err)
		}
		roomSessionManager.roomIdsForHandles[streamHandle] = streamRoomId
		return streamHandle
	}
	
	/// Updates the local Stream after it has been published,
	///
	/// - Parameter handle: Handle of the Stream to be updated.
	///
	/// - Throws: when the operation fails.
	///
	/// - Returns: result of the update operation.
	public func updateStream(
		_ handle: privmx.endpoint.stream.StreamHandle
	) throws -> privmx.endpoint.stream.StreamPublishResult {
		if let roomId = roomSessionManager.roomIdsForHandles[handle]{
			roomSessionManager.updateTurnCredentialsFor(roomId)
		}
		let res = cxxApi.updateStream(handle)
		if let err = res.error.value {
			throw PESStreamsError.failedUpdatingStream(err)
		}
		guard let result = res.result.value
		else {
			throw PESStreamsError.failedUpdatingStream(.init(name: "Missing value", message: "", description: ""))
		}
		
		return result
	}
	
	/// Publishes the local Stream —with currently staged tracks — to the server.
	///
	/// - Parameter streamHandle: handle of the Stream to be published.
	///
	/// - Throws: when the operation fails.
	///
	/// - Returns: the result of the publish operation.
	public func publishStream(
		_ streamHandle: privmx.endpoint.stream.StreamHandle
	) throws -> privmx.endpoint.stream.StreamPublishResult {
		
		guard let sh = roomSessionManager.roomIdsForHandles[streamHandle]
		else {
			throw PESStreamsError.failedPublishingStream(.init(
				name: "Unknown stream handle",
				message: "",
				description: "")
			)
		}
		roomSessionManager.updateTurnCredentialsFor(sh)
		
		guard let session = roomSessionManager.roomSessions[sh]
		else {
			throw PESStreamsError.failedPublishingStream(
				.init(
					name: "Couldn't create cryptor",
					message: "", description: ""
				)
			)
		}
		guard var publisher = session.publisher
		else {
			throw PESStreamsError.failedPublishingStream(.init(name: "Missing publisher", message: "", description: "The Publisher for this room doe not exist."))
		}
		
		let res = cxxApi.publishStream(streamHandle)
		
		if let err = res.error.value {
			throw PESStreamsError.failedPublishingStream(err)
		}
		guard let result = res.result.value
		else {
			throw PESStreamsError.failedPublishingStream(.init(name: "Missing publish result", message: "", description: ""))
		}
		
		return result
	}
	
	/// Gets a list of currently published Streams in given Stream Room.
	///
	/// - Parameter contextId: Id of the Stream Rooms from which to list the Streams.
	///
	/// - Throws: When the operation fails.
	///
	/// - Returns: a list of `StreamInfo` structs describing currently published streams.
	public func listStreams(
		in streamRoomId: String
	) throws -> [privmx.endpoint.stream.StreamInfo] {
		let res = cxxApi.listStreams(std.string(streamRoomId))
		guard res.error.value == nil else {
			throw PESStreamsError.failedListingStreams(res.error.value!)
		}
		guard let result = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PESStreamsError.failedListingStreams(err)
		}
		return result.map({$0})
	}
	
	/// Stops publishing the Stream.
	///
	/// - Parameter streamHandle: handle of the Stream to be unpublished.
	///
	/// - Throws: when the operation fails.
	public func unpublishStream(
		_ streamHandle: privmx.endpoint.stream.StreamHandle
	) throws -> Void {
		if let roomId = roomSessionManager.roomIdsForHandles[streamHandle]{
			roomSessionManager.updateTurnCredentialsFor(roomId)
		}
		let res = cxxApi.unpublishStream(streamHandle)
		guard res.error.value == nil else {
			throw PESStreamsError.failedUnpublishingStream(res.error.value!)
		}
	}
	
	/// Subscribes to selected remote Streams in the Stream Room.
	/// Optionally the specific Tracks to be subscribed to can be provided.
	/// This method creates the `RTCPeerConnection` for receiveing.
	///
	/// - Parameter streamRoomId: ID of the StreamRoom from which to receive Streams.
	/// - Parameter subscriptions: list of Stream subscription objects defining which streams or tracks to subscribe to.
	/// - Parameter onIceConnectionStateChanged: optional callback for reacting to changes in the Ice Connection state.
	/// - Parameter onPeerConnectionStateChanged: optional callback for reacting to changes in the Peer Connection state.
	/// - Parameter audioTrackHandler: optional handler that will be used for incoming Audio Tracks instead of the default one from now on.
	/// - Parameter videoTrackHandler: optional handler that will be used for incoming Video Tracks instead of the default one from now on.
	///
	/// - Throws: when the operation fails.
	public func subscribeToRemoteStreams(
		in streamRoomId: String,
		subscriptions: [privmx.endpoint.stream.StreamSubscription],
		onIceConnectionStateChanged: (@Sendable (RTCPeerConnection, RTCIceConnectionState) -> Void)? = nil,
		onPeerConnectionStateChanged: (@Sendable (RTCPeerConnection, RTCPeerConnectionState) -> Void)? = nil,
		audioTrackHandler: ((_ streamId:String,_ track:RTCAudioTrack) -> Void)? = nil,
		videoTrackHandler: ((_ streamId:String,_ track:RTCVideoTrack) -> Void)? = nil
	) throws -> Void {
		if let session = try roomSessionManager.roomSessions[streamRoomId] {
			if nil == session.subscriber{
				try session.createSubscriber()
				session.subscriber?.setconnectionStateChangedCallbacks(
					onIceConnectionStateChangedCallback: onIceConnectionStateChanged,
					onPeerConnectionStateChangedCallback: onPeerConnectionStateChanged)
			}
			if let audioTrackHandler {
				session.subscriber?.peerConnectionDelegate.setOnAudioTrackCallback(audioTrackHandler)
			}
			if let videoTrackHandler {
				session.subscriber?.peerConnectionDelegate.setOnVideoTrackCallback(videoTrackHandler)
			}
			
			roomSessionManager.updateTurnCredentialsFor(streamRoomId)
			var siv = privmx.StreamSubscriptiopnsVector()
			siv.reserve(subscriptions.count)
			for i in subscriptions{
				siv.push_back(i)
			}
			let res = cxxApi.subscribeToRemoteStreams(std.string(streamRoomId),
												   siv)
			if let err = res.error.value{
				throw PESStreamsError.failedSubscribingToRemoteStreams(err)
			}
		}
	}
	
	/// Modifies the current remote Streams subscriptions.
	///
	/// - Parameter streamRoomId: Id of the Stream Room for which the subscriptions should be changed.
	/// - Parameter subscriptionsToAdd: a list of objects describing the subscriptions to be added.
	/// - Parameter subscriptionsToRemove: a list of objects describing the subscriptions to be removed.
	///
	/// - Throws: when the operation fails.
	public func modifyRemoteStreamsSubscriptions(
		streamRoomId: String,
		subscriptionsToAdd: [privmx.endpoint.stream.StreamSubscription],
		subscriptionsToRemove: [privmx.endpoint.stream.StreamSubscription]
	) throws -> Void{
		
		roomSessionManager.updateTurnCredentialsFor(streamRoomId)
		
		var rsiv = privmx.StreamSubscriptiopnsVector()
		rsiv.reserve(subscriptionsToRemove.count)
		for i in subscriptionsToRemove{
			rsiv.push_back(i)
		}
		var asiv = privmx.StreamSubscriptiopnsVector()
		asiv.reserve(subscriptionsToAdd.count)
		for i in subscriptionsToAdd{
			asiv.push_back(i)
		}
		
		let res = cxxApi.modifyRemoteStreamsSubscriptions(
			std.string(streamRoomId),
			asiv,
			rsiv)
		if let err = res.error.value {
			throw PESStreamsError.failedModyfyingRemoteStreamsSubscriptions(err)
		}
	}
	
	/// Unsubscribes from the specified Streams in a Stream Room.
	///
	/// - Parameter streamRoomId: Id of the Stream Room for which the subscriptions should be removed.
	/// - Parameter subscriptionsToRemove: a list of objects describing the subscriptions to be removed.
	///
	/// - Throws: when the operation fails.
	public func unsubscribeFromRemoteStreams(
		_ subscriptionsToRemove: [privmx.endpoint.stream.StreamSubscription],
		in streamRoomId:String
	) throws -> Void {
			roomSessionManager.updateTurnCredentialsFor(streamRoomId)
		var siv = privmx.StreamSubscriptiopnsVector()
		siv.reserve(subscriptionsToRemove.count)
		for i in subscriptionsToRemove{
			siv.push_back(i)
		}
		let res = cxxApi.unsubscribeFromRemoteStreams(std.string(streamRoomId), siv)
		if let err =  res.error.value{
			throw PESStreamsError.failedUnsubscribingFromRemoteStreams(res.error.value!)
		}
	}
	
	/// Lists the `AVCaptureDevice`s that support capturing video.
	///
	/// - Returns: List of `AVCaptureDevices`
	public func listCameras(
	) -> [AVCaptureDevice]{
		RTCCameraVideoCapturer.captureDevices()
	}
	
	/// Configures whether to drop encrypted frames that cannot be decrypted.
	///
	/// - Parameter enable: whether the frames should or should not be dropped.
	/// - Parameter roomId: ID of the Stream Room for which this should apply.
	public func dropBrokenFrames(
		_ enable: Bool,
		in roomId:String
	) throws -> Void{
		guard let session = roomSessionManager.roomSessions[roomId]
		else {
			throw PESStreamsError.failedSettingDropBrokenFramesOption(.init(name: "No Session for Room", message: "", description: ""))
		}
		for c in session.subscriber?.peerConnectionDelegate.cryptors.value ?? [:] {
			c.value.0.setDropFramesIfCryptionFailed(enable)
		}
		for c in session.publisher?.peerConnectionDelegate.cryptors.value ?? [:] {
			c.value.0.setDropFramesIfCryptionFailed(enable)
		}
	}
	
	//MARK: - Tracks
	
	/// Adds a Video Track to the local Stream.
	///
	/// Optionally a `PMXFrameCryptorObserver` implementation can be provided.
	///
	/// - Parameter track: a `RTCVideoTrack` that will be added to room.
	/// - Parameter streamHandle: handle of the Stream to which the track will be added.
	/// - Parameter observer: an object implementing the `PMXFrameCryptorObserver` protocol.
	///
	/// - Throws: when the operation fails.
	public func addTrack(
		_ track: RTCVideoTrack,
		toStream streamHandle:privmx.endpoint.stream.StreamHandle,
		withCryptorObserver observer: (any PMXFrameCryptorObserver)? = nil
	) throws -> Void {
		try roomSessionManager.addVideoTrack(track, to: streamHandle,withCryptorObserver: observer)
	}
	
	/// Adds an Audio Track to the local Stream.
	///
	/// Optionally a `PMXFrameCryptorObserver` implementation can be provided.
	///
	/// - Parameter track: a `RTCAudioTrack` that will be added to room.
	/// - Parameter streamHandle: handle of the Stream to which the track will be added.
	/// - Parameter observer: an object implementing the `PMXFrameCryptorObserver` protocol.
	///
	/// - Throws: when the operation fails.
	public func addTrack(
		_ track: RTCAudioTrack,
		toStream streamHandle:privmx.endpoint.stream.StreamHandle,
		withCryptorObserver observer: (any PMXFrameCryptorObserver)? = nil
	) throws -> Void {
		try roomSessionManager.addAudioTrack(track, to: streamHandle,withCryptorObserver: observer)
	}
	
	
	
	/// Creates a local `RTCVideoTrack` and a `RTCVideoSource`.
	///
	/// - Parameter id: Id for the newly created local Track.
	/// - Parameter forScreenCast: whether the Source should be prepared for screen cast.
	///
	/// - Returns: a tuple containing the created Track and Source.
	public func createVideoTrackAndSource(
		id: String,
		forScreenCast: Bool = false
	) -> (track: RTCVideoTrack, source: RTCVideoSource) {
		var src = roomSessionManager.peerConnectionFactory.videoSource(forScreenCast: forScreenCast)
		var trk = roomSessionManager.peerConnectionFactory.videoTrack(with: src, trackId: id)
		return (trk,src)
	}
	
	/// Creates a local `RTCAudioTrack` and a `RTCAudioSource`.
	///
	/// - Parameter id: Id for the newly created local Track.
	///
	/// - Returns: a tuple containing the created Track and Source.
	public func createAudioTrackAndSource(
		id: String
	) -> (track: RTCAudioTrack, source: RTCAudioSource) {
		var src = roomSessionManager.peerConnectionFactory.audioSource(with: nil)
		var trk = roomSessionManager.peerConnectionFactory.audioTrack(with: src, trackId: id)
		return (trk,src)
	}

	
	/// Removes a Track from the local Stream,
	///
	/// - Parameter track: `RTCVideoTrack` to be removed.
	/// - Parameter handle: from which Stream the Track should be removed.
	///
	/// - Throws: when the operation fails.
	public func removeTrack(
		_ track: RTCVideoTrack,
		fromStream handle: privmx.endpoint.stream.StreamHandle
	) throws -> Void {
		try roomSessionManager.removeVideoTrack(track, from: handle)
	}
	
	/// Removes a Track from the local Stream,
	///
	/// - Parameter track: `RTCAudioTrack` to be removed.
	/// - Parameter handle: from which Stream the Track should be removed.
	///
	/// - Throws: when the operation fails.
	public func removeTrack(
		_ track: RTCAudioTrack,
		fromStream handle: privmx.endpoint.stream.StreamHandle
	) throws -> Void {
		try roomSessionManager.removeAudioTrack(track, from: handle)
	}
	
	// MARK: - EVENTS
	
	/// Subscribe for the Stream events on the given subscription query.
	///
	/// - Parameter subscriptionQueries: list of queries
	///
	/// - Throws: When subscribing for events fails.
	///
	/// - Returns: list of subscriptionIds in maching order to subscriptionQueries
	public func subscribeFor(
		_ subscriptionQueries: privmx.SubscriptionQueryVector
	) throws -> privmx.SubscriptionIdVector {
		let res = cxxApi.subscribeFor(subscriptionQueries)
		guard res.error.value == nil else {
			throw PrivMXEndpointError.failedSubscribingForEvents(res.error.value!)
		}
		guard let result = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PrivMXEndpointError.failedSubscribingForEvents(err)
		}
		return result
	}
	
	/// Unsubscribes from events for the given subscriptionId.
	///
	/// - Parameter subscriptionIds: list of subscriptionId
	///
	/// - Throws: When unsubscribing fails.
	public func unsubscribeFrom(
		_ subscriptionIds: privmx.SubscriptionIdVector
	) throws -> Void {
		let res = cxxApi.unsubscribeFrom(subscriptionIds)
		guard res.error.value == nil else {
			throw PrivMXEndpointError.failedUnsubscribingFromEvents(res.error.value!)
		}
	}
	
	/// Generate subscription Query for the Stream events.
	///
	/// - Parameter eventType: type of event which you listen for
	/// - Parameter selectorType: scope on which you listen for events
	/// - Parameter selectorId: ID of the selector
	///
	/// - Throws: When building the subscription Query fails.
	///
	/// - Returns: a properly formatted event subscription request.
	public func buildSubscriptionQuery(
		eventType: privmx.endpoint.stream.EventType,
		selectorType: privmx.endpoint.stream.EventSelectorType,
		selectorId: String
	) throws -> privmx.SubscriptionQuery {
		let res = cxxApi.buildSubscriptionQuery(eventType, selectorType, std.string(selectorId))
		guard res.error.value == nil else {
			throw PrivMXEndpointError.failedBuildingSubscriptionQuery(res.error.value!)
		}
		guard let result = res.result.value else {
			var err = privmx.InternalError()
			err.name = "Value error"
			err.description = "Unexpectedly recived nil result"
			throw PrivMXEndpointError.failedBuildingSubscriptionQuery(err)
		}
		return result
	}
	
	/// Sets the handler for new incoming `RTCVideoTracks`.
	///
	/// - Parameter roomId: Id of the Room for which the handler should be set.
	/// - Parameter handler: callback taking the `StreamID` and an incoming `RTCVideoTrack`
	public func setVideoStreamsHandlerFor(
		_ roomId: String,
		_ handler: ((String,RTCVideoTrack) -> Void)?
	) throws -> Void {
		guard var session = roomSessionManager.roomSessions[roomId]
		else {
			throw PESStreamsError.failedSettingTrackHandler(.init(
				name: "No session for Room",
				message: "", description: ""))
		}
		session.subscriber?.peerConnectionDelegate.onVideoTrack = handler
	}
	
	/// Sets the handler for new incoming `RTCAudioTrack`s.
	///
	/// - Parameter roomId: Id of the Room for which the handler should be set.
	/// - Parameter handler: callback taking the `StreamID` and an incoming `RTCAudioTrack`
	public func setAudioStreamsHandler(
		_ roomId: String,
		_ handler: ((String,RTCAudioTrack) -> Void)?
	) throws -> Void {
		guard var session = roomSessionManager.roomSessions[roomId]
		else {
			throw PESStreamsError.failedSettingTrackHandler(.init(
				name: "No session for Room",
				message: "", description: ""))
		}
		session.subscriber?.peerConnectionDelegate.onAudioTrack = handler
	}
	
	
	public var cxxApi: privmx.NativeStreamApiLowWrapper
	//MARK: - PRIVATE
	private init(
		api: privmx.NativeStreamApiLowWrapper,
	) {
		self.cxxApi = api
	}
	
	private func bindRoomSessionManger(
	) throws -> Void {
		self.roomSessionManager = RoomSessionManager.create(
			onTrickle: { sessionId, candidate in
				self.cxxApi.trickle(sessionId, std.string(candidate))
			},
			getTurnCredentials: {
				let res = self.cxxApi.getTurnCredentials()
				if let err = res.error.value{
					throw PESStreamsError.failedGettingTurnCredentials(err)
				}
				guard let resv = res.result.value
				else {
					throw PESStreamsError.failedGettingTurnCredentials(.init(
						name: "Value Error",
						message: "Unexpectedly received nil",
						description: "Could not get Turn Credentials"))
				}
				var result = [privmx.endpoint.stream.TurnCredentials]()
				resv.forEach({
					result.append($0)
				})
				return result
			},
			setNewOfferOnReconfigure: {
				sessionId, sdp in
				let res = self.cxxApi.setNewOfferOnReconfigure(sessionId, sdp)
				if let err = res.error.value{
					throw PESStreamsError.failedSettingNewOfferOnReconfigure(err)
				}
				RTCLogEx(.info, "[PMX] called setNewOffer on Reonfigure")
			},
			acceptOfferOnReconfigure: {
				sessionId, sdp in
				let res = self.cxxApi.acceptOfferOnReconfigure(sessionId, sdp)
				if let err = res.error.value{
					throw PESStreamsError.failedAcceptingOfferOnReconfigure(err)
				}
				RTCLogEx(.info, "[PMX] called acceptOffer on Reonfigure")
			},
		)
	}
	
}
