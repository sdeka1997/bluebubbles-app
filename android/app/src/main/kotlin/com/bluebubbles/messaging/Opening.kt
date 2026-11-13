package com.bluebubbles.messaging

import android.app.Activity
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.RectF
import android.graphics.Shader
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.view.Choreographer
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * BubbleBeam's opening: the glass message bubble on the BubbleBeam gradient while bubbles rise past
 * it, from Android's launch screen until the chat list has loaded.
 *
 * Drawn into its own surface from its own thread. The app's Dart code runs on the main thread, and
 * an opening drawn by Flutter stalled whenever startup work did; this one keeps moving however busy
 * that is. The bubbles are the app's loading animation (lib/app/components/rising_bubbles.dart).
 */
class Opening(private val activity: Activity, private val onGone: () -> Unit) :
    SurfaceHolder.Callback, Choreographer.FrameCallback {
    companion object {
        private const val loopMs = 3000L
        private const val easeMs = 250L
        private const val minimumMs = 1200L
        private const val maximumMs = 4000L
        private const val fadeMs = 350L

        // (x across the screen, phase offset, radius as a fraction of its width, sideways sway)
        private val bubbles = arrayOf(
            floatArrayOf(0.10f, 0.00f, 0.050f, 0.04f),
            floatArrayOf(0.30f, 0.55f, 0.035f, 0.03f),
            floatArrayOf(0.84f, 0.20f, 0.060f, 0.05f),
            floatArrayOf(0.68f, 0.75f, 0.030f, 0.03f),
            floatArrayOf(0.93f, 0.45f, 0.025f, 0.02f),
            floatArrayOf(0.05f, 0.35f, 0.028f, 0.02f),
            floatArrayOf(0.50f, 0.90f, 0.022f, 0.02f),
        )
    }

    private val view = SurfaceView(activity)
    private val main = Handler(Looper.getMainLooper())
    private val thread = HandlerThread("BubbleBeamOpening").apply { start() }
    private val render = Handler(thread.looper)
    private val bubble = BitmapFactory.decodeResource(activity.resources, R.drawable.opening_bubble)
    private val launch = ContextCompat.getColor(activity, R.color.opening_launch)
    private val top = ContextCompat.getColor(activity, R.color.opening_top)
    private val bottom = ContextCompat.getColor(activity, R.color.opening_bottom)
    private val density = activity.resources.displayMetrics.density
    private val start = SystemClock.uptimeMillis()

    // Main thread only.
    private var ending = false
    private var gone = false

    // When the fade began, 0 while showing. Set on the main thread, read on the render thread.
    @Volatile private var fadeFrom = 0L

    // Render thread only.
    private var surface: SurfaceHolder? = null
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

    fun show() {
        view.holder.setFormat(PixelFormat.TRANSLUCENT)
        view.setZOrderOnTop(true)
        view.holder.addCallback(this)
        // Covers the app while it plays, as the launch screen does.
        view.isClickable = true
        (activity.window.decorView as ViewGroup).addView(
            view, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        main.postDelayed({ end() }, maximumMs)
    }

    /** The app has something to show: fades out once the opening has played for at least [minimumMs]. */
    fun end() {
        if (ending || gone) return
        ending = true
        main.removeCallbacksAndMessages(null)
        val wait = max(0L, start + minimumMs - SystemClock.uptimeMillis())
        main.postDelayed({
            fadeFrom = SystemClock.uptimeMillis()
            main.postDelayed({ dispose() }, fadeMs + 50)
        }, wait)
    }

    /** Removes the opening at once (also when the activity goes away). */
    fun dispose() {
        if (gone) return
        gone = true
        main.removeCallbacksAndMessages(null)
        (view.parent as? ViewGroup)?.removeView(view)
        thread.quitSafely()
        onGone()
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        render.post {
            surface = holder
            draw()
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        // The surface is gone once this returns, so stop drawing into it first.
        val stopped = CountDownLatch(1)
        val posted = render.post {
            surface = null
            Choreographer.getInstance().removeFrameCallback(this)
            stopped.countDown()
        }
        if (posted) stopped.await(500, TimeUnit.MILLISECONDS)
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (surface == null) return
        draw()
        Choreographer.getInstance().postFrameCallback(this)
    }

    private fun draw() {
        val holder = surface ?: return
        val canvas = try {
            holder.surface.lockHardwareCanvas()
        } catch (e: Exception) {
            return
        }
        try {
            paint(canvas, SystemClock.uptimeMillis())
        } finally {
            holder.surface.unlockCanvasAndPost(canvas)
        }
    }

    private fun paint(canvas: Canvas, now: Long) {
        val w = canvas.width.toFloat()
        val h = canvas.height.toFloat()
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val fadeStart = fadeFrom
        val opacity = if (fadeStart == 0L) 1f else (1f - (now - fadeStart).toFloat() / fadeMs).coerceIn(0f, 1f)
        if (opacity < 1f) canvas.saveLayerAlpha(0f, 0f, w, h, (255 * opacity).roundToInt())

        // Eases from Android's flat launch colour into the gradient.
        val t = ((now - start).toFloat() / easeMs).coerceIn(0f, 1f)
        paint.shader = LinearGradient(0f, 0f, w, h, lerp(launch, top, t), lerp(launch, bottom, t), Shader.TileMode.CLAMP)
        canvas.drawRect(0f, 0f, w, h, paint)
        paint.shader = null

        drawBubbles(canvas, w, h, ((now - start) % loopMs).toFloat() / loopMs)

        val bw = w * 0.42f
        val bh = bw * bubble.height / bubble.width
        paint.alpha = 255
        canvas.drawBitmap(bubble, null, RectF((w - bw) / 2, (h - bh) / 2, (w + bw) / 2, (h + bh) / 2), paint)

        if (opacity < 1f) canvas.restore()
    }

    /** RisingBubblesPainter.paint, in white. */
    private fun drawBubbles(canvas: Canvas, w: Float, h: Float, progress: Float) {
        for ((x, phase, r, sway) in bubbles.map { listOf(it[0], it[1], it[2], it[3]) }) {
            val p = (progress + phase) % 1f
            val fade = if (p < 0.15f) p / 0.15f else if (p > 0.85f) (1 - p) / 0.15f else 1f
            val radius = r * w * (0.7f + 0.3f * p)
            val cx = (x + sway * sin((p * 2 + phase) * 2 * PI).toFloat()) * w
            val cy = h * (1.05f - 1.1f * p)

            paint.style = Paint.Style.FILL
            paint.color = Color.argb((30 * fade).roundToInt(), 255, 255, 255)
            canvas.drawCircle(cx, cy, radius, paint)

            paint.style = Paint.Style.STROKE
            paint.strokeWidth = max(1f * density, radius * 0.14f)
            paint.color = Color.argb((140 * fade).roundToInt(), 255, 255, 255)
            canvas.drawCircle(cx, cy, radius, paint)

            paint.style = Paint.Style.FILL
            paint.color = Color.argb((200 * fade).roundToInt(), 255, 255, 255)
            canvas.drawCircle(cx - radius * 0.35f, cy - radius * 0.35f, radius * 0.2f, paint)
        }
    }

    private fun lerp(from: Int, to: Int, t: Float): Int = Color.argb(
        255,
        (Color.red(from) + (Color.red(to) - Color.red(from)) * t).roundToInt(),
        (Color.green(from) + (Color.green(to) - Color.green(from)) * t).roundToInt(),
        (Color.blue(from) + (Color.blue(to) - Color.blue(from)) * t).roundToInt(),
    )
}
