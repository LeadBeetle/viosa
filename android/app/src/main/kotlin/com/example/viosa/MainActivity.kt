package com.example.viosa

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.viosa/audio_converter"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "convertToMp3" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")

                    if (inputPath == null || outputPath == null) {
                        result.error("INVALID_ARGUMENTS", "Input and output paths are required", null)
                        return@setMethodCallHandler
                    }

                    // Run conversion on background thread to avoid blocking UI
                    executor.execute {
                        try {
                            convertAudioToMp3(inputPath, outputPath)
                            // Post result back to main thread
                            mainHandler.post {
                                result.success(outputPath)
                            }
                        } catch (e: Exception) {
                            // Post error back to main thread
                            mainHandler.post {
                                result.error("CONVERSION_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Convert audio file to MP3-compatible format using Android's MediaCodec
     * This decodes the input audio and re-encodes it to AAC in MP4 container (M4A)
     * Note: Android doesn't natively support MP3 encoding, so we use AAC which provides
     * excellent quality and is widely compatible
     */
    private fun convertAudioToMp3(inputPath: String, outputPath: String) {
        android.util.Log.d("AudioConverter", "Starting conversion: $inputPath -> $outputPath")

        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null

        try {
            // Setup extractor
            extractor.setDataSource(inputPath)

            // Find audio track
            var trackIndex = -1
            var inputFormat: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    trackIndex = i
                    inputFormat = format
                    break
                }
            }

            if (trackIndex < 0 || inputFormat == null) {
                throw Exception("No audio track found in input file")
            }

            extractor.selectTrack(trackIndex)

            // Get original audio format
            val sampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)!!

            android.util.Log.d("AudioConverter", "Input format: $mime, ${sampleRate}Hz, $channelCount channels")

            // Create decoder
            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(inputFormat, null, null, 0)
            decoder.start()

            // Create encoder for AAC (Android's native audio codec)
            // AAC provides excellent quality and is compatible with most transcription services
            val encoderFormat = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC,
                sampleRate,
                channelCount
            )
            encoderFormat.setInteger(MediaFormat.KEY_BIT_RATE, 128000) // 128kbps
            encoderFormat.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)

            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder.configure(encoderFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()

            // Create muxer (MP4 container)
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Conversion loop
            val decoderBufferInfo = MediaCodec.BufferInfo()
            val encoderBufferInfo = MediaCodec.BufferInfo()
            var decoderDone = false
            var encoderDone = false
            var muxerStarted = false
            var audioTrackIndex = -1

            while (!encoderDone) {
                // Feed decoder
                if (!decoderDone) {
                    val inputBufferId = decoder.dequeueInputBuffer(10000)
                    if (inputBufferId >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputBufferId)!!
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)

                        if (sampleSize < 0) {
                            decoder.queueInputBuffer(inputBufferId, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            decoderDone = true
                            android.util.Log.d("AudioConverter", "Decoder input done")
                        } else {
                            val presentationTime = extractor.sampleTime
                            decoder.queueInputBuffer(inputBufferId, 0, sampleSize, presentationTime, 0)
                            extractor.advance()
                        }
                    }
                }

                // Get decoded data
                var encoderInputDone = false
                while (!encoderInputDone) {
                    val decoderOutputId = decoder.dequeueOutputBuffer(decoderBufferInfo, 10000)
                    if (decoderOutputId >= 0) {
                        val decoderOutputBuffer = decoder.getOutputBuffer(decoderOutputId)!!

                        // Feed to encoder
                        val encoderInputId = encoder.dequeueInputBuffer(10000)
                        if (encoderInputId >= 0) {
                            val encoderInputBuffer = encoder.getInputBuffer(encoderInputId)!!
                            encoderInputBuffer.clear()
                            encoderInputBuffer.put(decoderOutputBuffer)

                            val flags = if ((decoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            } else {
                                0
                            }

                            encoder.queueInputBuffer(
                                encoderInputId,
                                0,
                                decoderBufferInfo.size,
                                decoderBufferInfo.presentationTimeUs,
                                flags
                            )
                        }

                        decoder.releaseOutputBuffer(decoderOutputId, false)

                        if ((decoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            encoderInputDone = true
                        }
                    } else {
                        encoderInputDone = true
                    }
                }

                // Get encoded data and write to muxer
                val encoderOutputId = encoder.dequeueOutputBuffer(encoderBufferInfo, 10000)
                if (encoderOutputId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val newFormat = encoder.outputFormat
                    android.util.Log.d("AudioConverter", "Encoder output format changed: $newFormat")
                    audioTrackIndex = muxer.addTrack(newFormat)
                    muxer.start()
                    muxerStarted = true
                } else if (encoderOutputId >= 0) {
                    val encodedData = encoder.getOutputBuffer(encoderOutputId)!!

                    if ((encoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0 && muxerStarted) {
                        muxer.writeSampleData(audioTrackIndex, encodedData, encoderBufferInfo)
                    }

                    encoder.releaseOutputBuffer(encoderOutputId, false)

                    if ((encoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        encoderDone = true
                        android.util.Log.d("AudioConverter", "Encoder done")
                    }
                }
            }

            android.util.Log.d("AudioConverter", "Conversion completed successfully")

        } catch (e: Exception) {
            android.util.Log.e("AudioConverter", "Conversion error", e)
            throw e
        } finally {
            decoder?.stop()
            decoder?.release()
            encoder?.stop()
            encoder?.release()
            muxer?.stop()
            muxer?.release()
            extractor.release()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
    }
}