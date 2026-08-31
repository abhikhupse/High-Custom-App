package com.example.high_custom_frontend

import android.content.ClipData
import android.content.ClipboardManager
import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val clipboardChannel = "high_custom/image_clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            clipboardChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyPng" -> copyPngToClipboard(call.arguments as? ByteArray, result)
                "savePng" -> {
                    val arguments = call.arguments as? Map<*, *>
                    savePngToDownloads(
                        arguments?.get("bytes") as? ByteArray,
                        arguments?.get("name") as? String,
                        result,
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copyPngToClipboard(bytes: ByteArray?, result: MethodChannel.Result) {
        if (bytes == null || bytes.isEmpty()) {
            result.error("EMPTY_IMAGE", "No business card image was provided.", null)
            return
        }

        try {
            val clipboardDirectory = File(cacheDir, "clipboard_images").apply { mkdirs() }
            val imageFile = File(clipboardDirectory, "high-custom-business-card.png")
            imageFile.writeBytes(bytes)
            val imageUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                imageFile,
            )
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(
                ClipData.newUri(contentResolver, "High Custom Business Card", imageUri),
            )
            result.success(null)
        } catch (error: Exception) {
            result.error("COPY_FAILED", error.message, null)
        }
    }

    private fun savePngToDownloads(
        bytes: ByteArray?,
        requestedName: String?,
        result: MethodChannel.Result,
    ) {
        if (bytes == null || bytes.isEmpty()) {
            result.error("EMPTY_IMAGE", "No business card image was provided.", null)
            return
        }

        val fileName = requestedName?.takeIf { it.endsWith(".png") }
            ?: "high-custom-business-card.png"
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, "image/png")
                    put(
                        MediaStore.Downloads.RELATIVE_PATH,
                        "${Environment.DIRECTORY_DOWNLOADS}/High Custom",
                    )
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    values,
                ) ?: throw IllegalStateException("Could not create the download file.")
                contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw IllegalStateException("Could not write the download file.")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
            } else {
                @Suppress("DEPRECATION")
                val downloadDirectory = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                    "High Custom",
                ).apply { mkdirs() }
                val file = File(downloadDirectory, fileName)
                file.writeBytes(bytes)
                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(file.absolutePath),
                    arrayOf("image/png"),
                    null,
                )
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("SAVE_FAILED", error.message, null)
        }
    }
}
