package com.antigravity.ownd

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class SafHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val channelName = "com.antigravity.ownd/saf"
    private val prefs: SharedPreferences =
        activity.getSharedPreferences("saf_prefs", Context.MODE_PRIVATE)
    private val KEY_BACKUP_DIR = "backup_directory_uri"

    private var pendingResult: MethodChannel.Result? = null

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger) {
        val channel = MethodChannel(messenger, channelName)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(result)
            "createFileInDirectory" -> {
                val directoryUri = call.argument<String>("directoryUri")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType") ?: "application/zip"
                val base64Data = call.argument<String>("data")
                if (directoryUri == null || fileName == null || base64Data == null) {
                    result.error("INVALID_ARGS", "Missing required arguments", null)
                    return
                }
                createFileInDirectory(directoryUri, fileName, mimeType, base64Data, result)
            }
            "openFile" -> openFilePicker(result)
            "getSavedDirectoryUri" -> {
                result.success(prefs.getString(KEY_BACKUP_DIR, null))
            }
            "clearSavedDirectoryUri" -> {
                prefs.edit().remove(KEY_BACKUP_DIR).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        activity.startActivityForResult(intent, REQUEST_CODE_PICK_DIR)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val result = pendingResult ?: return false

        when (requestCode) {
            REQUEST_CODE_PICK_DIR -> {
                pendingResult = null
                if (resultCode != Activity.RESULT_OK || data?.data == null) {
                    result.success(null)
                    return true
                }

                val uri = data.data!!
                try {
                    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    activity.contentResolver.takePersistableUriPermission(uri, flags)
                } catch (e: Exception) {
                    // Some providers may not support persistable permissions
                }

                prefs.edit().putString(KEY_BACKUP_DIR, uri.toString()).apply()
                result.success(uri.toString())
                return true
            }
            REQUEST_CODE_PICK_FILE -> {
                pendingResult = null
                if (resultCode != Activity.RESULT_OK || data?.data == null) {
                    result.success(null)
                    return true
                }
                readFileBytes(data.data!!, result)
                return true
            }
        }
        return false
    }

    private fun createFileInDirectory(
        directoryUri: String,
        fileName: String,
        mimeType: String,
        base64Data: String,
        result: MethodChannel.Result
    ) {
        try {
            val treeUri = Uri.parse(directoryUri)
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri)
            )
            val createdUri = DocumentsContract.createDocument(
                activity.contentResolver,
                documentUri,
                mimeType,
                fileName
            )
            if (createdUri == null) {
                result.error("CREATE_FAILED", "Failed to create file", null)
                return
            }

            val bytes = android.util.Base64.decode(base64Data, android.util.Base64.DEFAULT)
            activity.contentResolver.openOutputStream(createdUri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: run {
                result.error("WRITE_FAILED", "Failed to open output stream", null)
                return
            }

            result.success(createdUri.toString())
        } catch (e: Exception) {
            result.error("SAF_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun openFilePicker(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        activity.startActivityForResult(intent, REQUEST_CODE_PICK_FILE)
    }

    private fun readFileBytes(uri: Uri, result: MethodChannel.Result) {
        try {
            val bytes = activity.contentResolver.openInputStream(uri)?.use { stream ->
                val buffer = ByteArrayOutputStream()
                val data = ByteArray(4096)
                var bytesRead: Int
                while (stream.read(data).also { bytesRead = it } != -1) {
                    buffer.write(data, 0, bytesRead)
                }
                buffer.toByteArray()
            }
            if (bytes == null) {
                result.error("READ_FAILED", "Failed to read file", null)
                return
            }
            val base64 = android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
            result.success(base64)
        } catch (e: Exception) {
            result.error("SAF_ERROR", e.message, e.stackTraceToString())
        }
    }

    companion object {
        private const val REQUEST_CODE_PICK_DIR = 9001
        private const val REQUEST_CODE_PICK_FILE = 9002
    }
}
