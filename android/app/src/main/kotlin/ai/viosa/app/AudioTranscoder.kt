package ai.viosa.app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Dekodiert eine beliebige vom Gerät unterstützte Audiodatei in eine
 * PCM-16-WAV-Datei.
 *
 * Der Transkriptionsanbieter lehnt den MP4/AAC-Container ab, also läuft jeder
 * Import vor dem Upload hier durch.
 */
object AudioTranscoder {

    private const val HEADER_SIZE = 44
    private const val TIMEOUT_US = 10_000L
    private const val PCM_FLOAT = 4

    class TranscodeException(message: String) : Exception(message)

    /**
     * Schreibt [sourcePath] als Mono-WAV mit [targetSampleRate] nach
     * [targetPath] und liefert den Zielpfad zurück.
     */
    fun toWav(sourcePath: String, targetPath: String, targetSampleRate: Int): String {
        if (!File(sourcePath).exists()) {
            throw TranscodeException("Datei nicht gefunden: " + sourcePath)
        }

        val extractor = MediaExtractor()
        extractor.setDataSource(sourcePath)

        val trackIndex = audioTrackOf(extractor)
        if (trackIndex < 0) {
            extractor.release()
            throw TranscodeException("Keine Audiospur in " + sourcePath)
        }

        val inputFormat = extractor.getTrackFormat(trackIndex)
        val mime = inputFormat.getString(MediaFormat.KEY_MIME)
        if (mime == null) {
            extractor.release()
            throw TranscodeException("Spur ohne MIME-Typ")
        }

        extractor.selectTrack(trackIndex)

        val codec = MediaCodec.createDecoderByType(mime)
        val output = RandomAccessFile(targetPath, "rw")

        try {
            output.setLength(0)
            output.write(ByteArray(HEADER_SIZE))

            codec.configure(inputFormat, null, null, 0)
            codec.start()

            val written = decode(extractor, codec, output, targetSampleRate)
            writeHeader(output, written, targetSampleRate)
        } finally {
            runCatching { codec.stop() }
            codec.release()
            extractor.release()
            output.close()
        }

        return targetPath
    }

    private fun audioTrackOf(extractor: MediaExtractor): Int {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)
            if (mime != null && mime.startsWith("audio/")) return index
        }
        return -1
    }

    /**
     * Fährt den Decoder leer und schreibt die Samples gemischt und auf
     * [targetSampleRate] gerechnet nach [output]. Liefert die Anzahl Bytes.
     */
    private fun decode(
        extractor: MediaExtractor,
        codec: MediaCodec,
        output: RandomAccessFile,
        targetSampleRate: Int,
    ): Int {
        val info = MediaCodec.BufferInfo()
        val resampler = Resampler(targetSampleRate)
        var written = 0
        var inputDone = false
        var outputDone = false

        while (!outputDone) {
            if (!inputDone) {
                val inputIndex = codec.dequeueInputBuffer(TIMEOUT_US)
                if (inputIndex >= 0) {
                    val buffer = codec.getInputBuffer(inputIndex)!!
                    val size = extractor.readSampleData(buffer, 0)
                    if (size < 0) {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            0,
                            0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        inputDone = true
                    } else {
                        codec.queueInputBuffer(inputIndex, 0, size, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            val outputIndex = codec.dequeueOutputBuffer(info, TIMEOUT_US)
            if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                resampler.configure(codec.outputFormat)
            } else if (outputIndex >= 0) {
                val buffer = codec.getOutputBuffer(outputIndex)!!
                if (info.size > 0) {
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    written += writeSamples(output, resampler.resample(buffer))
                }
                codec.releaseOutputBuffer(outputIndex, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    outputDone = true
                }
            }
        }

        return written
    }

    private fun writeSamples(output: RandomAccessFile, samples: ShortArray): Int {
        if (samples.isEmpty()) return 0

        val bytes = ByteBuffer.allocate(samples.size * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (sample in samples) bytes.putShort(sample)
        output.write(bytes.array())
        return samples.size * 2
    }

    /**
     * Schreibt den WAV-Kopf, sobald die Länge der Daten feststeht.
     */
    private fun writeHeader(output: RandomAccessFile, dataSize: Int, sampleRate: Int) {
        val header = ByteBuffer.allocate(HEADER_SIZE).order(ByteOrder.LITTLE_ENDIAN)

        header.put("RIFF".toByteArray())
        header.putInt(HEADER_SIZE - 8 + dataSize)
        header.put("WAVE".toByteArray())
        header.put("fmt ".toByteArray())
        header.putInt(16)
        header.putShort(1)
        header.putShort(1)
        header.putInt(sampleRate)
        header.putInt(sampleRate * 2)
        header.putShort(2)
        header.putShort(16)
        header.put("data".toByteArray())
        header.putInt(dataSize)

        output.seek(0)
        output.write(header.array())
    }

    /**
     * Mischt die dekodierten Kanäle zu Mono und rechnet linear interpoliert auf
     * die Zielabtastrate um. Der Übertrag zwischen zwei Puffern bleibt erhalten,
     * damit an den Puffergrenzen kein Knacken entsteht.
     */
    private class Resampler(private val targetSampleRate: Int) {
        private var sourceSampleRate = targetSampleRate
        private var channels = 1
        private var pcmEncoding = 2
        private var previous: Short? = null
        private var position = 0.0

        fun configure(format: MediaFormat) {
            sourceSampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            pcmEncoding = if (format.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                format.getInteger(MediaFormat.KEY_PCM_ENCODING)
            } else {
                2
            }
        }

        fun resample(buffer: ByteBuffer): ShortArray {
            val mono = toMono(buffer)
            if (mono.isEmpty()) return ShortArray(0)

            if (sourceSampleRate == targetSampleRate) {
                previous = mono[mono.size - 1]
                return mono
            }

            val step = sourceSampleRate.toDouble() / targetSampleRate
            val result = ArrayList<Short>((mono.size / step).toInt() + 2)

            while (position < mono.size) {
                val index = position.toInt()
                val fraction = position - index
                val left = if (index == 0) previous ?: mono[0] else mono[index - 1]
                val right = mono[index]
                result.add((left + (right - left) * fraction).toInt().toShort())
                position += step
            }

            position -= mono.size
            previous = mono[mono.size - 1]

            val samples = ShortArray(result.size)
            for (index in result.indices) samples[index] = result[index]
            return samples
        }

        private fun toMono(buffer: ByteBuffer): ShortArray {
            val samples = readSamples(buffer)
            if (channels <= 1) return samples

            val frames = samples.size / channels
            val mono = ShortArray(frames)
            for (frame in 0 until frames) {
                var sum = 0
                for (channel in 0 until channels) {
                    sum += samples[frame * channels + channel]
                }
                mono[frame] = (sum / channels).toShort()
            }
            return mono
        }

        private fun readSamples(buffer: ByteBuffer): ShortArray {
            buffer.order(ByteOrder.LITTLE_ENDIAN)

            if (pcmEncoding == PCM_FLOAT) {
                val floats = buffer.asFloatBuffer()
                val samples = ShortArray(floats.remaining())
                for (index in samples.indices) {
                    val value = floats.get(index).coerceIn(-1f, 1f)
                    samples[index] = (value * Short.MAX_VALUE).toInt().toShort()
                }
                return samples
            }

            val shorts = buffer.asShortBuffer()
            val samples = ShortArray(shorts.remaining())
            shorts.get(samples)
            return samples
        }
    }
}
