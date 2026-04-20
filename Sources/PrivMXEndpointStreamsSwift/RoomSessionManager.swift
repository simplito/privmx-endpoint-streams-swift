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

import PrivMXEndpointSwift
import PrivMXEndpointSwiftNative
import WebRTC
import Foundation

final class RoomSessionManager: Sendable{
	
	nonisolated(unsafe) let localAnalyzer : PMXAudioLevelAnalyzer
	private let getTurnCredentials: @Sendable () throws -> [privmx.endpoint.stream.TurnCredentials]
	nonisolated(unsafe) var onAudioTrack: ((String,RTCAudioTrack) -> Void)?
	nonisolated(unsafe)var onVideoTrack: ((String,RTCVideoTrack) -> Void)?
	
	nonisolated(unsafe) var roomIdsForHandles: [privmx.endpoint.stream.StreamHandle:String] = [:]
	nonisolated(unsafe) var roomSessions: [String:RoomJanusSession] = [:]
	
	private let onTrickle: @Sendable (Int64,String) throws -> Void
	nonisolated(unsafe) let peerConnectionFactory: RTCPeerConnectionFactory
	
	private let setNewOfferOnReconfigure: @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void
	private let acceptOfferOnReconfigure: @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void
	static func create(
		onTrickle: @escaping @Sendable (Int64,String) throws -> Void,
		getTurnCredentials: @escaping @Sendable () throws -> [privmx.endpoint.stream.TurnCredentials],
		setNewOfferOnReconfigure: @escaping @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void,
		acceptOfferOnReconfigure: @escaping @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void,
	) -> RoomSessionManager {
		var encf = RTCDefaultVideoEncoderFactory()
		var analyzer = PMXAudioLevelAnalyzer()
		encf.preferredCodec = .init(name: kRTCVp8CodecName)
		
		var mgr = RoomSessionManager(
			audioLevelAnalyzer: analyzer,
			onTrickle: onTrickle,
			getTurnCredentials: getTurnCredentials,
			peerConnectionFactory: RTCPeerConnectionFactory(
				bypassVoiceProcessing: false,
				encoderFactory: encf,
				decoderFactory: RTCDefaultVideoDecoderFactory(),
				audioProcessingModule: RTCDefaultAudioProcessingModule(
					config: nil,
					capturePostProcessingDelegate: analyzer,
					renderPreProcessingDelegate: nil
				)
			),
			onSetNewOfferOnReconfigure: setNewOfferOnReconfigure,
			onAcceptOfferOnReconfigure: acceptOfferOnReconfigure,
		)
		return mgr
	}
	
	func setPublisherRenegCallbacks(_ roomId: String){
		guard let publisher = roomSessions[roomId]?.publisher
		else {
			return
		}
		
		publisher.peerConnectionDelegate.setIceCandidateGeneratedCallback({
			peerConnection, candidate in
			
			RTCLogEx(.info, "[PMX] will try trickling publisher")
			if !candidate.sdp.isEmpty, publisher.sessionId > -1{
				var iceCandidate = candidate.sdp
				Task{
					do{
						RTCLogEx(.info, "[PMX] trickling publisher")
						try self.onTrickle(publisher.sessionId,iceCandidate)
					}catch{
						RTCLogEx(.info,"Failed to trickle candidate \(error)")
					}
				}
			}
		})
		
		publisher.peerConnectionDelegate.setShouldRenegotiateCallback({
			peer in
			if publisher.sessionId > -1{
				RTCLogEx(.info, "[PMX][Renegotiate][Publisher] Received Should Renegotiate Callback")
				Task{
					do{
						let offer = try peer.offer(for: RTCMediaConstraints(mandatoryConstraints:nil,optionalConstraints: nil)) {description,error in
							if let description{
								RTCLogEx(.info, "[PMX][Renegotiate][publisher] Has publisher and description")
								let tp = switch description.type {
									case .answer:
										"answer"
									case .prAnswer:
										"prAnswer"
									case .offer:
										"offer"
									case .rollback:
										"rollback"
									@unknown default:
										"UNKNOWN"
								}
								Task{@Sendable in
									let sid = publisher.sessionId
									do{
										RTCLogEx(.info, "[pmx][reneg] publisher will set new offer")
										try self.setNewOfferOnReconfigure(sid,.init(sdp: std.string(description.sdp), type: std.string(tp)))
									}catch let err{
										RTCLogEx(.error, "[pmx][reneg][error] \(err)")
									}
									try await peer.setLocalDescription(description)
									//if let swr = await try? publisher.reconfigure(sdp: description.sdp, type: String(tp), roomId: roomId){
									//	let swt = privmx.endpoint.stream.SdpWithTypeModel(sdp: swr.sdp, type: swr.type )
									// else {
									//	RTCLogEx(.error, "[PMX][reneg] Failed reconfigure")
									//}
								}
							}
						}
					}catch let err{
						print("[PMX][reneg][error] \(err)")
					}
				}
			}
		})
	}
	
	@discardableResult
	func addRoomSessionFor(
		_ roomId: String
	) throws -> RoomJanusSession {
		guard roomSessions[roomId] == nil
		else {
			throw PESStreamsError.failedJoiningStreamRoom(.init(
				name: "Room Session already exists",
				message: "You have already joined this StreamRoom",
				description: "")
			)
		}
		var ks = PMXKeyStore()
		nonisolated(unsafe)var rjs = RoomJanusSession(
			keyStore: ks,
			roomId: roomId,
			_getPeerConnectionWithDelegate:{
				return self.createPeerConnection(keyStore: &ks,streamRoomId: roomId)
			}
		)
		setCppCallbacksInSession(&rjs)
		
		roomSessions[roomId] = rjs
		return rjs
	}
	
	
	func addVideoTrack(
		_ track: RTCVideoTrack,
		to streamHandle: privmx.endpoint.stream.StreamHandle,
		withCryptorObserver observer: PMXFrameCryptorObserver? = nil
	) throws -> Void {
		guard let roomId = roomIdsForHandles[streamHandle], let session = roomSessions[roomId]
		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "No session for room",
					message: "", description: ""
				)
			)
		}
		let pub = try session.createPublisher()
		guard nil == pub.videoTracks[track.trackId] else
		{
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Track already added",
					message: "", description: ""
				)
			)
		}
		var tinit = RTCRtpTransceiverInit()
		tinit.direction = .sendOnly
		guard var sender = pub.peerConnection.addTransceiver(with: track, init: tinit)

		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Couldn't create sender",
					message: "", description: ""
				)
			)
		}
		
		guard var cryptor = PMXFrameCryptorTransformer(
			for: sender.sender,
			   with: peerConnectionFactory,
			pmxKeyStore: session.keyStore.value,
			audioLevelAnalyzer:PMXAudioLevelAnalyzer())
		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Couldn't create cryptor",
					message: "", description: ""
				)
			)
		}
		if let observer{
			cryptor.register(observer)
		}
		pub.videoTracks[track.trackId] = VideoTrackInfo(
			track: track,
			sender: sender.sender,
			frameCryptor: cryptor)
		sender.sender.track
	}
	
	func addAudioTrack(
		_ track: RTCAudioTrack,
		to streamHandle: privmx.endpoint.stream.StreamHandle,
		withCryptorObserver observer: PMXFrameCryptorObserver? = nil
	) throws -> Void {
		localAnalyzer.enable(true)
		guard let roomId = roomIdsForHandles[streamHandle],let session = roomSessions[roomId]
		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "No session for room",
					message: "", description: ""
				)
			)
		}
		let pub = try session.createPublisher()
		guard nil == pub.videoTracks[track.trackId] else
		{
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Track already added",
					message: "", description: ""
				)
			)
		}
		
		var tinit = RTCRtpTransceiverInit()
		tinit.direction = .sendOnly
		guard var sender = pub.peerConnection.addTransceiver(with: track,init: tinit)
		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Couldn't create sender",
					message: "", description: ""
				)
			)
		}
		//let analyzer = PMXAudioLevelAnalyzer()
		//analyzer.enable(true)
		guard var cryptor = PMXFrameCryptorTransformer(
			for: sender.sender,
			with: peerConnectionFactory,
			pmxKeyStore: session.keyStore.value,
			audioLevelAnalyzer:localAnalyzer)
		else {
			throw PESStreamsError.failedAddingTrack(
				.init(
					name: "Couldn't create cryptor",
					message: "", description: ""
				)
			)
		}
		if let observer{
			cryptor.register(observer)
		}
		pub.audioTracks[track.trackId] = AudioTrackInfo(
			track: track,
			sender: sender.sender,
			frameCryptor: cryptor,
		audioLevelAnalyzer: localAnalyzer)
	}
	
	func removeVideoTrack(
		_ track: RTCVideoTrack,
		from handle: privmx.endpoint.stream.StreamHandle
	) throws -> Bool {
		guard let rid = roomIdsForHandles[handle], let publisher = roomSessions[rid]?.publisher
		else {
			throw PESStreamsError.failedRemovingTrack(.init(name: "No publisher found", message: "", description: ""))
		}
		if let sender = publisher.videoTracks[track.trackId]?.sender {
			return publisher.peerConnection.removeTrack(sender)
		} else {
			throw PESStreamsError.failedRemovingTrack(.init(name: "No sender for track", message: "", description: ""))
		}
	}
	
	func removeAudioTrack(
		_ track: RTCAudioTrack,
		from handle: privmx.endpoint.stream.StreamHandle
	) throws -> Bool {
		guard let rid = roomIdsForHandles[handle], let publisher = roomSessions[rid]?.publisher
		else {
			throw PESStreamsError.failedRemovingTrack(.init(name: "No publisher found", message: "", description: ""))
		}
		if let sender = publisher.audioTracks[track.trackId]?.sender {
			return publisher.peerConnection.removeTrack(sender)
		} else {
			throw PESStreamsError.failedRemovingTrack(.init(name: "No sender for track", message: "", description: ""))
		}
		
	}
	
	func setAudioStreamsHandler(
	_ handler: ((String,RTCAudioTrack) -> Void)?
	) -> Void{
		self.onAudioTrack = handler
	}
	
	func setVideoStreamsHandler(
	_ handler: ((String,RTCVideoTrack) -> Void)?
	) -> Void{
		self.onVideoTrack = handler
	}
	
	func createPeerConnection(
		keyStore:inout PMXKeyStore,
		streamRoomId: String
	) -> (RTCPeerConnection?, PMXPeerConnectionDelegate){
		var observer = PMXPeerConnectionDelegate(
			streamRoomId: streamRoomId,
			peerConnectionFactory: self.peerConnectionFactory,
			currentKeys: &keyStore
		)
		let it = Unmanaged<PMXPeerConnectionDelegate>.passUnretained(observer)
		observer.setTracksAddedCallback({
			pc, receiver, mediaStreams in
			let that = Unmanaged<PMXPeerConnectionDelegate>.takeUnretainedValue(it)
			if let trackId = receiver.track?.trackId, mediaStreams.count > 0{
				let streamId = mediaStreams[0].streamId
				that().track2Stream[trackId] = streamId
				print("[PMX][Observer]",trackId,that().track2Stream[trackId])
				let ut = that().unprocessedTracks
				for t in ut{
					if t.value.kind == kRTCMediaStreamTrackKindVideo {
						if let track = t.value as? RTCVideoTrack{
							RTCLogEx(.info,"[PMX][Observer]Got an unprocessed Video Track")
							//that().onVideoTrack?(streamId, track)
						} else {
							RTCLogEx(.info,"[PMX][Observer]Couldn't cast media track as video track")
						}
					}
					else if t.value.kind == kRTCMediaStreamTrackKindAudio {
						if let track = t.value as? RTCAudioTrack{
							RTCLogEx(.info,"[PMX][Observer]Got an unprocessed Audio Track")
							//that().onAudioTrack?(streamId,track)
						}else{
							RTCLogEx(.info,"[PMX][Observer]Couldn't cast media track as audio track")
						}
					}
					that().unprocessedTracks[t.key] = nil
				}
			}
			
		})
		observer.setOnAudioTrackCallback(onAudioTrack)
		observer.setOnVideoTrackCallback(onVideoTrack)
		observer.setStartedReceivingCallback({
			pc,transciever in
			RTCLogEx(.info,"[PMX][Observer]started receiving cb called with \(transciever.receiver.track?.trackId)")
			
			if let track = transciever.receiver.track{
				let that = Unmanaged<PMXPeerConnectionDelegate>.takeUnretainedValue(it)
				if let streamId = that().track2Stream[track.trackId]{
					print("[PMX][Observer] has track",track,"and streamId",streamId)
					if track.kind == kRTCMediaStreamTrackKindVideo {
						if let track = track as? RTCVideoTrack{
							RTCLogEx(.info,"[PMX][Observer]Got a Video Track")
							that().onVideoTrack?(streamId, track)
						} else {
							RTCLogEx(.info,"[PMX][Observer]Couldn't cast media track as video track")
						}
					}
					else if track.kind == kRTCMediaStreamTrackKindAudio {
						if let track = track as? RTCAudioTrack{
							RTCLogEx(.info,"[PMX][Observer]Got an Audio Track")
								that().onAudioTrack?(streamId,track)
						}else{
							RTCLogEx(.info,"[PMX][Observer]Couldn't cast media track as audio track")
						}
					}
				} else {
					print("[PMX][Observer] has track",track,"and no streamID")
					that().unprocessedTracks[track.trackId] = track
				}
			}
		})
		var conf = RTCConfiguration()
		if let turncreds = try? getTurnCredentials(){
			conf.iceTransportPolicy = .all
			turncreds.forEach({
				cred in
				conf.iceServers.append(.init(urlStrings: [String(cred.url)], username: String(cred.username), credential: String(cred.password)))
			})
		}
		return (self.peerConnectionFactory.peerConnection(
			with: conf,
			constraints: RTCMediaConstraints.init(
				mandatoryConstraints: [:],
				optionalConstraints: nil),
			delegate: observer), observer)
	}
	
	private init(
		audioLevelAnalyzer: PMXAudioLevelAnalyzer,
		onTrickle: @escaping @Sendable (Int64,String) throws -> Void,
		getTurnCredentials: @escaping @Sendable () throws -> [privmx.endpoint.stream.TurnCredentials],
		peerConnectionFactory: RTCPeerConnectionFactory,
		onSetNewOfferOnReconfigure: @escaping @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void,
		onAcceptOfferOnReconfigure: @escaping @Sendable (Int64,privmx.endpoint.stream.SdpWithTypeModel) throws -> Void,
	){
		self.localAnalyzer = audioLevelAnalyzer
		self.onTrickle = onTrickle
		self.getTurnCredentials = getTurnCredentials
		self.peerConnectionFactory = peerConnectionFactory
		self.setNewOfferOnReconfigure = onSetNewOfferOnReconfigure
		self.acceptOfferOnReconfigure = onAcceptOfferOnReconfigure
	}
	
	func updateTurnCredentialsFor(
		_ roomId:String
	) -> Void {
		if var session = roomSessions[roomId], let creds = try? getTurnCredentials(){
			
			var iceServers = [RTCIceServer]()
			creds.forEach {
				iceServers.append(.init(
					urlStrings: [String($0.url)],
					username: String($0.username),
					credential: String($0.password)))
			}
			if var conf = session.subscriber?.peerConnection.configuration{
				conf.iceServers = iceServers
				session.subscriber?.peerConnection.setConfiguration(conf)
			}
			if var conf = session.publisher?.peerConnection.configuration{
				conf.iceServers = iceServers
				session.publisher?.peerConnection.setConfiguration(conf)
			}
		}
	}
	
	private func setCppCallbacksInSession(
	_ session: inout RoomJanusSession
	) {
		session.webRTCInstance = privmx.WRTCIIHolder(
			{ context in//CreateOfferAndSetLocalDescription
				nonisolated(unsafe)var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeUnretainedValue()
				nonisolated(unsafe)var result = privmx.StringWithError()
				nonisolated(unsafe)var done = false
				nonisolated(unsafe) let streamRoomId = context!.pointee.roomId
				Task.detached(){
					@Sendable in
					if let jc = try this.publisher{
						let pc = jc.peerConnection
						do{
							RTCLogEx(.info, "[pmx][state]\(pc.iceConnectionState)")
							let res = try await pc.offer(for: RTCMediaConstraints(mandatoryConstraints: [:], optionalConstraints: [:]))
							result = privmx.StringWithError(
								result: std.string(res.sdp),
								isvalid: true,
								errname: "",
								errwhat: "")
							RTCLogEx(.info,"[pmx]create offer set loc desc")
							try await pc.setLocalDescription(res)
							done=true
						} catch let err{
							result = privmx.StringWithError(
								result: "",
								isvalid: true,
								errname: "Failed creating SDP",
								errwhat: std.string(err.localizedDescription))
							done = true
						}
					}else {
						result = privmx.StringWithError(
							result: "", isvalid: true,
							errname: "Missing Publisher",
							errwhat: "")
						done = true
					}
				}
				while !done {
					usleep(100)
				}
				return result
			},
			{ context in//CreateAnswerAndSetDescriptions
				nonisolated(unsafe) var result = privmx.StringWithError()
				nonisolated(unsafe) var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeUnretainedValue()
				nonisolated(unsafe) var done = false
				nonisolated(unsafe) let streamRoomId = context!.pointee.roomId,
										sdp = context!.pointee.sdp,
										type = context!.pointee.type
				Task.detached{
					@Sendable in
					defer {done = true}
					if let jc = this.subscriber{
						do{
							let lpa = try await jc.reconfigure(
								sdp: String(sdp),
								type: String(type),
								roomId: String(streamRoomId)
							)
							result.result = lpa.sdp
							result.isvalid = true
						}catch let err{
							result = privmx.StringWithError(
								result: "",
								isvalid: true,
								errname: std.string("\((err as? PESStreamsError)?.getName() ?? "ERROR")"),
								errwhat: std.string("\((err as? PESStreamsError)?.getDescription())")
							)
						}
					} else {
						result = privmx.StringWithError(
							result: "",
							isvalid: true,
							errname:"could not get a PeerConnection",
							errwhat: "")
					}
				}
				while !done {
					usleep(100)
				}
				return result
			},
			{context in//SetAnswerAndSetRemoteDescription
				nonisolated(unsafe) var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeUnretainedValue()
				nonisolated(unsafe) var res = privmx.InternalError()
				nonisolated(unsafe) var done = false
				nonisolated(unsafe) let streamRoomId = String(context!.pointee.roomId),
										sdp = String(context!.pointee.sdp),
										type = String(context!.pointee.type)
				
				Task.detached{@Sendable in
					do{
						try await this.createPublisher()
							.reconfigure(
								sdp: sdp,
								type: type,
								roomId: streamRoomId)
					
					}catch let err{
						res = privmx.InternalError(
							name: "Error Updating Session",
							message: "",
							description: err.localizedDescription)
					}
					done = true
				}
				while !done {
					usleep(100)
				}
				return res
			},
			{ context in//UpdateSessionId
				RTCLogEx(RTCLoggingSeverity.info, "[PMX] Updating Session Id")
				var res = privmx.InternalError()
				var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeUnretainedValue()
				let streamRoomId = context!.pointee.roomId,
					sessionId = context!.pointee.sessionId,
					connectiontype = context!.pointee.connectionType,
					srid = String(streamRoomId)
				do{
					if connectiontype == "publisher"{
						try this.publisher?.updateSessionId(sessionId)
					} else if connectiontype == "subscriber" {
						try this.subscriber?.updateSessionId(sessionId)
					} else {
						res = privmx.InternalError(
							name: "Unknown ConnectionType",
							message: "", description: "")
					}
				}catch let err{
					res = privmx.InternalError(
						name: "Error Updating Session",
						message: "",
						description: err.localizedDescription)
				}
				return res
			},
			{ context in//UpdateKeys
				RTCLogEx(RTCLoggingSeverity.info, "[PMX] Updating Keys")
				var res = privmx.InternalError()
				var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeUnretainedValue()
				var nkeys = [PMXKSKey]()
				for k in context!.pointee.keys{
					let ktype = if k.type == privmx.endpoint.stream.LOCAL{PMXKSKeyType.LOCAL} else {PMXKSKeyType.REMOTE}
					let kkey = k.key.getData() ?? Data()
					nkeys.append(PMXKSKey.init(
						keyId: String(k.keyId),
						key: kkey,
						type:ktype)
					)
				}
				this.updateKeys(nkeys)
				
				return ""
			},
			{ context in//Close
				RTCLogEx(.info,"[PMX][swift][dbg][close] callback called")
				var res = privmx.InternalError()
				if nil != context{
					RTCLogEx(.info,"[PMX][swift][dbg][close] has context")
					var this = Unmanaged<RoomJanusSession>.fromOpaque(context!.pointee.context).takeRetainedValue()
					RTCLogEx(.info,"[PMX][swift][dbg][close] has this from context")
					let streamRoomId = context!.pointee.roomId
					RTCLogEx(.info,"[PMX][swift][dbg][close] has roomid from context")
					let srid = String(streamRoomId)
					RTCLogEx(.info,"[PMX][swift][dbg][close] got values")
					do{
						this.publisher?.close()
						this.subscriber?.close()
					}catch let err{
						res = privmx.InternalError(
							name: "Error Closing Session",
							message: "",
							description: err.localizedDescription)
						RTCLogEx(.info,"[PMX][swift][dbg][close] caught error")
					}
				} else {
					res.name = "Missing Context"
					RTCLogEx(.info,"[PMX][swift][dbg][close] Missing Context")
				}
				return res
			},
			Unmanaged.passRetained(session).toOpaque())

	}
	func removeSession(_ roomId: String){
		self.roomSessions[roomId] = nil
	}
	
}
