package tech.xiaotai.yunting

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.widget.Toast
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// audio_service 要求宿主 Activity 继承 AudioServiceActivity，
// 否则后台播放与媒体按钮不会生效。
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yun/app").setMethodCallHandler { call, result ->
            when (call.method) {
                "versionName" -> result.success(
                    packageManager.getPackageInfo(packageName, 0).versionName
                )
                "download" -> {
                    val urls = call.argument<List<String>>("urls").orEmpty()
                    val version = call.argument<String>("version").orEmpty()
                    if (urls.isEmpty()) result.error("no_url", "没有可用的下载地址", null)
                    else result.success(AppInstaller.download(this, urls, version))
                }
                else -> result.notImplemented()
            }
        }
        // 本机媒体：查询放后台线程，几千个文件时不卡界面
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yun/media").setMethodCallHandler { call, result ->
            val kind = call.argument<String>("kind") ?: "audio"
            when (call.method) {
                "hasPermission" -> result.success(LocalMedia.hasPermission(this, kind))
                "requestPermission" -> LocalMedia.requestPermission(this, kind, result)
                "query" -> Thread {
                    try {
                        val rows = LocalMedia.query(this, kind)
                        runOnUiThread { result.success(rows) }
                    } catch (e: SecurityException) {
                        runOnUiThread { result.error("permission", e.message, null) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("query", e.message, null) }
                    }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LocalMedia.REQUEST_CODE) {
            LocalMedia.onPermissionResult(grantResults)
        }
    }

    override fun onResume() {
        super.onResume()
        // 刚在授权页允许了"安装未知应用"：继续安装
        AppInstaller.onResume(this)
    }
}

/** 下载并安装新版本：交给系统下载管理器，完成后打开安装界面。 */
object AppInstaller {
    private const val APK_MIME = "application/vnd.android.package-archive"

    /** 下载完成、但还没有"安装未知应用"权限时记下的下载 ID；授权后回到应用时自动安装。 */
    private var pendingInstall: Long? = null

    /**
     * 用系统下载管理器下载安装包（通知栏显示进度），返回下载 ID。
     * urls 按优先顺序排列：一个下载失败自动换下一个（镜像 → GitHub）。
     * 完成监听注册在应用级 Context 上：关掉更新弹窗（后台下载）后也会在下载完成时打开安装界面。
     */
    fun download(context: Context, urls: List<String>, version: String): Long {
        val app = context.applicationContext
        val dm = app.getSystemService(DownloadManager::class.java)
        val request = DownloadManager.Request(Uri.parse(urls.first()))
            .setTitle("云听书 $version")
            .setDescription("正在下载新版本")
            .setMimeType(APK_MIME)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalFilesDir(app, Environment.DIRECTORY_DOWNLOADS, "yunting-$version.apk")
        val id = dm.enqueue(request)
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                if (intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1) != id) return
                app.unregisterReceiver(this)
                if (succeeded(dm, id)) install(app, id)
                else {
                    dm.remove(id)
                    if (urls.size > 1) download(app, urls.drop(1), version)
                    else Toast.makeText(app, "下载失败，请稍后重试", Toast.LENGTH_LONG).show()
                }
            }
        }
        val filter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
        // 下载完成广播来自系统下载管理器，Android 13 起必须声明导出
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            app.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            app.registerReceiver(receiver, filter)
        }
        return id
    }

    private fun succeeded(dm: DownloadManager, id: Long): Boolean =
        dm.query(DownloadManager.Query().setFilterById(id))?.use { c ->
            c.moveToFirst() && c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS)) == DownloadManager.STATUS_SUCCESSFUL
        } == true

    fun onResume(context: Context) {
        val id = pendingInstall ?: return
        if (canInstall(context)) {
            pendingInstall = null
            install(context, id)
        }
    }

    private fun canInstall(context: Context) =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || context.packageManager.canRequestPackageInstalls()

    /** 打开系统安装界面；没有"安装未知应用"权限时先打开授权页（授权后回到应用自动继续）。 */
    private fun install(context: Context, downloadId: Long) {
        if (!canInstall(context)) {
            pendingInstall = downloadId
            Toast.makeText(context, "请允许云听书安装应用，返回后会自动继续安装", Toast.LENGTH_LONG).show()
            context.startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${context.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return
        }
        val uri = context.getSystemService(DownloadManager::class.java).getUriForDownloadedFile(downloadId) ?: return
        context.startActivity(
            Intent(Intent.ACTION_VIEW).setDataAndType(uri, APK_MIME)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }
}
