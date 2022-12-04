package com.rashstudios.sharem


import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import kotlin.io.path.exists


class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "channel").setMethodCallHandler{ call, result -> when  {
                call.method.equals("getExternalDir") -> {
                    getExternalDir(call, result)
                }
                call.method.equals("openExplorer") -> {
                    openExplorer(call, result)
                }
            }
        }
    }

    private fun getExternalDir(call: MethodCall, result: MethodChannel.Result) {
        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
        if (dir != null) {
            val path = dir.path + "/sharem/"
            if (!Files.exists(Paths.get(path))) {
                Files.createDirectory(Paths.get(path))
            }
            result.success(path)
        } else {
            result.success(null)
        }
    }

    private fun openExplorer(call: MethodCall, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_VIEW)

        val url = FileProvider.getUriForFile(context,
            context.packageName +
             ".provider",
            File(call.argument<String>("path")),
        )
        intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        intent.flags = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

        intent.setDataAndType(url, call.argument<String>("type"))

        context.startActivity(intent)

        result.success(url.toString())
    }
}
