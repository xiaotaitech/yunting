package tech.xiaotai.yunting

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/** 封面（add-covers）：从本机媒体里取图，以及让用户从相册挑一张。 */
object Covers {
    const val PICK_REQUEST = 4108
    private var pendingPick: MethodChannel.Result? = null

    /**
     * 本机文件的封面字节：音频取内嵌专辑图，视频取第 1 秒附近的一帧（缩到 512 内）。
     * 没有就返回 null。content:// 地址直接交给系统读，不需要额外权限。
     */
    fun extract(activity: Activity, uri: String, kind: String): ByteArray? {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(activity, Uri.parse(uri))
            if (kind == "video") {
                val frame = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    r.getScaledFrameAtTime(1_000_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, 512, 512)
                } else {
                    r.getFrameAtTime(1_000_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                } ?: return null
                ByteArrayOutputStream().use {
                    frame.compress(Bitmap.CompressFormat.JPEG, 85, it)
                    it.toByteArray()
                }
            } else {
                r.embeddedPicture
            }
        } catch (e: Exception) {
            null
        } finally {
            r.release()
        }
    }

    /**
     * 系统照片选择器挑一张图，拷到缓存目录后返回路径（取消返回 null）。
     * 13 起用系统照片选择器，不需要任何权限；之前用 GET_CONTENT，同样不需要。
     */
    fun pick(activity: Activity, result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // 不设类型时照片选择器连视频一起列出来
            Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*")
        } else {
            Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
        }
        activity.startActivityForResult(intent, PICK_REQUEST)
    }

    fun onPickResult(activity: Activity, resultCode: Int, data: Intent?) {
        val result = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            val out = File(activity.cacheDir, "picked-cover-${System.currentTimeMillis()}")
            activity.contentResolver.openInputStream(uri)?.use { input ->
                out.outputStream().use { input.copyTo(it) }
            }
            result.success(out.absolutePath)
        } catch (e: Exception) {
            result.error("pick", e.message, null)
        }
    }
}
