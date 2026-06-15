package com.antigravity.ownd

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private lateinit var safHandler: SafHandler
    private lateinit var installPermissionHandler: InstallPermissionHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        safHandler = SafHandler(this)
        safHandler.register(flutterEngine.dartExecutor.binaryMessenger)
        installPermissionHandler = InstallPermissionHandler(this)
        installPermissionHandler.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (installPermissionHandler.onActivityResult(requestCode, resultCode, data)) {
            return
        }
        if (safHandler.onActivityResult(requestCode, resultCode, data)) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
