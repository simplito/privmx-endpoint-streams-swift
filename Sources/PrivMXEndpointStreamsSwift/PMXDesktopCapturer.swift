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

#if os(macOS)
import WebRTC
import ScreenCaptureKit
import PrivMXEndpointSwiftNative
import PrivMXEndpointSwift


final class StreamOutput:NSObject, SCStreamOutput{
	weak var capturer: PMXDesktopCapturer?
	public func stream(
		_ stream: SCStream,
		didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
		of type: SCStreamOutputType
	) -> Void {
		if type == SCStreamOutputType.screen{
			if let imbuf = CMSampleBufferGetImageBuffer(sampleBuffer), let capturer{
				let pixbuf = RTCCVPixelBuffer(pixelBuffer: imbuf)
				
				capturer.delegate?.capturer(capturer, didCapture: RTCVideoFrame(
					buffer: pixbuf,
					rotation: RTCVideoRotation._0,
					timeStampNs: Int64(sampleBuffer.decodeTimeStamp.value)))
			}
		}
	}

}

/// `RTCVideoCapturer` implementing Desktop caputre using ScreenCaptureKit.
public final class PMXDesktopCapturer: RTCVideoCapturer, @unchecked Sendable{
	private var sampleHandlerQueue = DispatchQueue(label: "sample_handler")
	nonisolated(unsafe) private let stream: SCStream
	let output = StreamOutput()
	
	/// Initialises the Desktop Capturer with a `RTCVideoCapturerDelegate`, `SCContentFilter` and `SCStreamConfiguration`.
	///
	/// - Parameter videoDelegate: an object implementing the `RTCVideoCapturerDelegate`, this will usualy be an instance of RTCVideoSource.
	/// - Parameter filter: SCContentFilter describing what part of the screen will be captured.
	/// - Parameter configuration: configuration object for the SCStream.
	///
	/// - Throws: when the configuration object specifies a pixel format different from `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`.
	public init(
		videoDelegate: RTCVideoCapturerDelegate,
		filter: SCContentFilter,
		configuration: SCStreamConfiguration
	) throws {
		if configuration.pixelFormat != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange{
			throw PESStreamsError.failedCreatingDesktopCapturer(privmx.InternalError(
				name: "Illegal pixel format",
				message: "",
				description: ""))
		}
		self.stream = SCStream(
			filter: filter,
			configuration: configuration,
			delegate: nil)
		super.init(delegate: videoDelegate)
	}
	
	/// Replaces the `SCContentFilter`.
	///
	/// - Parameter filter: the new filter to be used.
	///
	/// - Throws: when the update fails.
	public func updateFilter(
		_ filter: SCContentFilter
	) async throws -> Void {
		try await stream.updateContentFilter(filter)
	}
	
	/// Replaces the `SCStreamConfiguration`.
	///
	/// - Parameter filter: the new filter to be used.
	///
	/// - Throws: when the update fails.
	public func updateConfiguration(
		_ config: SCStreamConfiguration
	) async throws -> Void {
		try await stream.updateConfiguration(config)
	}
	
	/// Starts recording the screen.
	public func startRecording(
	) async throws -> Void {
		if nil == output.capturer{
			output.capturer = self
		}
		try stream.addStreamOutput(
			output,
			type: .screen,
			sampleHandlerQueue: sampleHandlerQueue)
		try await stream.startCapture()
	}
	
	/// Stops recording the screen.
	public func stopRecording(
	) async throws -> Void {
		try await stream.stopCapture()
		
	}
}
#endif
