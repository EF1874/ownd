package com.antigravity.ownd

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class InstallPermissionHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val channelName = "com.antigravity.ownd/install_permission"
    private var pendingResult: MethodChannel.Result? = null

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger) {
        val channel = MethodChannel(messenger, channelName)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canRequestPackageInstalls" -> result.success(canRequestPackageInstalls())
            "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
            "openInstallPermissionSettings" -> openInstallPermissionSettings(result)
            "installApk" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath.isNullOrBlank()) {
                    result.error("INVALID_APK_PATH", "安装包路径无效，请重新下载", null)
                    return
                }
                installApk(filePath, result)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_INSTALL_PERMISSION) {
            return false
        }

        pendingResult?.success(canRequestPackageInstalls())
        pendingResult = null
        return true
    }

    private fun canRequestPackageInstalls(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                activity.packageManager.canRequestPackageInstalls()
    }

    private fun openInstallPermissionSettings(result: MethodChannel.Result) {
        if (canRequestPackageInstalls()) {
            result.success(true)
            return
        }

        pendingResult?.success(false)
        pendingResult = result

        var lastError: Exception? = null
        for (intent in installPermissionIntents()) {
            try {
                activity.startActivityForResult(intent, REQUEST_CODE_INSTALL_PERMISSION)
                return
            } catch (error: Exception) {
                lastError = error
            }
        }

        pendingResult = null
        result.error(
            "OPEN_SETTINGS_FAILED",
            "无法打开权限设置页，请在系统设置中允许本应用安装未知应用",
            lastError?.stackTraceToString()
        )
    }

    private fun installPermissionIntents(): List<Intent> {
        val packageUri = Uri.parse("package:${activity.packageName}")
        val appDetailsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)

        return listOf(
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                packageUri
            ),
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES),
            appDetailsIntent
        )
    }

    private fun installApk(filePath: String, result: MethodChannel.Result) {
        if (!canRequestPackageInstalls()) {
            openInstallPermissionSettings(result)
            return
        }

        val apkFile = File(filePath)
        if (!apkFile.exists()) {
            result.error("APK_NOT_FOUND", "安装包不存在，请重新下载", null)
            return
        }

        try {
            val apkUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    activity,
                    "${activity.packageName}.fileprovider",
                    apkFile
                )
            } else {
                Uri.fromFile(apkFile)
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error(
                "OPEN_INSTALLER_FAILED",
                "无法打开安装程序，请稍后重试",
                e.stackTraceToString()
            )
        }
    }

    companion object {
        private const val REQUEST_CODE_INSTALL_PERMISSION = 9101
    }
}
