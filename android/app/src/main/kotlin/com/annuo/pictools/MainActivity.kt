package com.annuo.pictools

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val writer = Executors.newSingleThreadExecutor()
    private var permissionResult: MethodChannel.Result? = null
    private val storageRequest = 8194

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pictools/photo_library")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (hasWritePermission()) result.success(null)
                        else if (permissionResult != null) result.error("busy", "Permission request in progress", null)
                        else {
                            permissionResult = result
                            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), storageRequest)
                        }
                    }
                    "openSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                            result.success(null)
                        } catch (error: Exception) { result.error("settings_failed", error.message, null) }
                    }
                    "saveImage" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val name = call.argument<String>("fileName")?.substringAfterLast('/')?.substringAfterLast('\\')
                        val ext = call.argument<String>("extension")
                        if (bytes == null || bytes.isEmpty() || name.isNullOrBlank() || ext !in listOf("png", "jpg")) {
                            result.error("invalid_image", "PNG or JPEG required", null)
                        } else if (!hasWritePermission()) {
                            result.error("permission_denied", "Storage permission denied", null)
                        } else {
                            writer.execute {
                                try {
                                    savePhoto(bytes, name, if (ext == "jpg") "image/jpeg" else "image/png")
                                    runOnUiThread { result.success(null) }
                                } catch (error: Exception) {
                                    runOnUiThread { result.error("save_failed", error.message, null) }
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasWritePermission() = Build.VERSION.SDK_INT >= 29 ||
        checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == storageRequest) {
            val result = permissionResult
            permissionResult = null
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) result?.success(null)
            else result?.error("permission_denied", "Storage permission denied", null)
        }
    }

    private fun savePhoto(bytes: ByteArray, name: String, mime: String) {
        if (Build.VERSION.SDK_INT >= 29) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, mime)
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Pictools")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: error("Cannot create photo")
            try {
                val stream = contentResolver.openOutputStream(uri) ?: error("Cannot open photo")
                stream.use { it.write(bytes) }
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                check(contentResolver.update(uri, values, null, null) > 0) { "Cannot publish photo" }
            } catch (error: Exception) {
                contentResolver.delete(uri, null, null)
                throw error
            }
        } else {
            @Suppress("DEPRECATION")
            val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Pictools")
            check(directory.isDirectory || directory.mkdirs()) { "Cannot create Pictures folder" }
            // Atomic exclusive creation avoids ever overwriting an existing export.
            var output = File(directory, name)
            var suffix = 1
            val dot = name.lastIndexOf('.')
            val stem = if (dot > 0) name.substring(0, dot) else name
            val extension = if (dot > 0) name.substring(dot) else ""
            while (!output.createNewFile()) output = File(directory, "$stem (${suffix++})$extension")
            try { output.outputStream().use { it.write(bytes) } }
            catch (error: Exception) { output.delete(); throw error }
            MediaScannerConnection.scanFile(applicationContext, arrayOf(output.absolutePath), arrayOf(mime), null)
        }
    }

    override fun onDestroy() {
        permissionResult?.error("cancelled", "Activity closed", null)
        permissionResult = null
        writer.shutdown()
        super.onDestroy()
    }
}
