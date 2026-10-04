package tech.xiaotai.yunting

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel

/**
 * 本机媒体（add-local-media）：读系统 MediaStore 索引，列出手机里的音频 / 视频。
 *
 * 不复制文件、不扫磁盘——系统早就建好了索引，读它既快又不用「所有文件访问」权限，
 * 只要「音乐和音频」/「照片和视频」两项媒体权限（Android 13 起分开申请，之前是读存储）。
 * 播放直接用 content:// 地址，just_audio 与 video_player 都认。
 */
object LocalMedia {
    const val REQUEST_CODE = 4107

    private var pending: MethodChannel.Result? = null

    private fun permissionsFor(kind: String): Array<String> = when {
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ->
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        kind != "video" -> arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
        // 14 起视频可以「只允许部分」：一并申请 USER_SELECTED，用户选部分时也能用
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> arrayOf(
            Manifest.permission.READ_MEDIA_VIDEO,
            Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED,
        )
        else -> arrayOf(Manifest.permission.READ_MEDIA_VIDEO)
    }

    /** 任一项被授予即可：「部分访问」时 MediaStore 只返回用户选中的那些。 */
    fun hasPermission(activity: Activity, kind: String): Boolean =
        permissionsFor(kind).any {
            activity.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }

    fun requestPermission(activity: Activity, kind: String, result: MethodChannel.Result) {
        if (hasPermission(activity, kind)) {
            result.success(true)
            return
        }
        pending?.success(false)
        pending = result
        activity.requestPermissions(permissionsFor(kind), REQUEST_CODE)
    }

    fun onPermissionResult(grantResults: IntArray) {
        val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
        pending?.success(granted)
        pending = null
    }

    /**
     * 列出全部音频或视频。路径按「/相对目录/文件名」给出（与网盘路径同一种形状），
     * 方便沿用按文件夹分组、自然排序那一套。
     */
    fun query(activity: Activity, kind: String): List<Map<String, Any?>> {
        val isVideo = kind == "video"
        val collection = if (isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val q = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val projection = buildList {
            add(MediaStore.MediaColumns._ID)
            add(MediaStore.MediaColumns.DISPLAY_NAME)
            add(MediaStore.MediaColumns.SIZE)
            add(MediaStore.MediaColumns.DATE_MODIFIED)
            add(MediaStore.MediaColumns.DURATION)
            // 10 起用相对路径；之前只有（已废弃但仍可用的）绝对路径 DATA
            add(if (q) MediaStore.MediaColumns.RELATIVE_PATH else MediaStore.MediaColumns.DATA)
        }.toTypedArray()
        // 录音机、通话录音这类零碎音频常被标成非音乐，不加 IS_MUSIC 过滤：有声书多半也不是「音乐」
        val out = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(collection, projection, null, null, null)?.use { c ->
            val id = c.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val name = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val size = c.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val mtime = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
            val duration = c.getColumnIndex(MediaStore.MediaColumns.DURATION)
            val where = c.getColumnIndexOrThrow(projection.last())
            while (c.moveToNext()) {
                val fileName = c.getString(name) ?: continue
                val path = if (q) {
                    "/" + (c.getString(where) ?: "").trimEnd('/') + "/" + fileName
                } else {
                    // /storage/emulated/0/Music/x.mp3 → /Music/x.mp3
                    (c.getString(where) ?: continue).replace(Regex("^/storage/[^/]+/[^/]+"), "")
                        .replace(Regex("^/storage/emulated/\\d+"), "")
                }
                val mediaId = c.getLong(id)
                out.add(
                    mapOf(
                        "id" to mediaId.toString(),
                        "uri" to ContentUris.withAppendedId(collection, mediaId).toString(),
                        "name" to fileName,
                        "path" to path.replace("//", "/"),
                        "size" to c.getLong(size),
                        "mtime" to c.getLong(mtime),
                        "durationMs" to if (duration >= 0) c.getLong(duration) else null,
                    )
                )
            }
        }
        return out
    }
}
