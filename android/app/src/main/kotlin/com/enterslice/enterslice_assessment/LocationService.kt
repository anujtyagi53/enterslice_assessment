package com.enterslice.enterslice_assessment

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.os.Looper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class LocationService : Service() {

  companion object {
    const val CHANNEL = "location_tracker"
    const val NOT_ID = 42
    var isRunning = false
    var locationSink: EventChannel.EventSink? = null

    fun updateInterval(context: Context, intervalSeconds: Int) {
      context.getSharedPreferences("all_prefs", Context.MODE_PRIVATE)
        .edit().putInt("interval", intervalSeconds).apply()
      if (!isRunning) return
      val intent =
        Intent(context, LocationService::class.java).putExtra("interval", intervalSeconds)
      context.stopService(Intent(context, LocationService::class.java))
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent)
      else context.startService(intent)
    }
  }

  private lateinit var fusedClient: FusedLocationProviderClient
  private lateinit var locationCallback: LocationCallback
  private lateinit var dao: LocationDao
  private lateinit var prefs: SharedPreferences
  private lateinit var notifManager: NotificationManager

  override fun onCreate() {
    super.onCreate()
    fusedClient = LocationServices.getFusedLocationProviderClient(this)
    dao = LocationDao(LocationDatabase(this))
    prefs = getSharedPreferences("all_prefs", MODE_PRIVATE)
    notifManager = getSystemService(NotificationManager::class.java)
    createNotificationChannel()
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val intervalSec = intent?.getIntExtra("interval", prefs.getInt("interval", 30))
      ?: prefs.getInt("interval", 30)
    prefs.edit()
      .putInt("interval", intervalSec)
      .putBoolean("is_tracking", true)
      .apply()

    if (::locationCallback.isInitialized) {
      fusedClient.removeLocationUpdates(locationCallback)
    }

    startForeground(NOT_ID, buildNotification("Waiting...", "", ""))
    isRunning = true
    requestLocationUpdates(intervalSec.toLong() * 1000)
    return START_STICKY
  }

  override fun onDestroy() {
    if (::locationCallback.isInitialized) {
      fusedClient.removeLocationUpdates(locationCallback)
    }
    isRunning = false
    prefs.edit().putBoolean("is_tracking", false).apply()
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun requestLocationUpdates(intervalMs: Long) {
    locationCallback = object : LocationCallback() {
      override fun onLocationResult(result: LocationResult) {
        val loc = result.lastLocation ?: return
        val timestamp = System.currentTimeMillis()

        val rowId = dao.insert(loc.latitude, loc.longitude, loc.accuracy, timestamp)

        val data = mapOf(
          "id" to rowId,
          "latitude" to loc.latitude,
          "longitude" to loc.longitude,
          "accuracy" to loc.accuracy.toDouble(),
          "timestamp" to timestamp
        )
        locationSink?.success(data)

        val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date(timestamp))
        val latLng = "%.6f, %.6f".format(loc.latitude, loc.longitude)
        notifManager.notify(
          NOT_ID,
          buildNotification(latLng, "±%.1fm".format(loc.accuracy), time)
        )
      }
    }

    val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs)
      .setMinUpdateIntervalMillis(intervalMs / 2)
      .build()

    try {
      fusedClient.requestLocationUpdates(request, locationCallback, Looper.getMainLooper())
    } catch (e: SecurityException) {
      locationSink?.error("PERMISSION_DENIED", e.message, null)
      stopSelf()
    }
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL, "Location Tracker", NotificationManager.IMPORTANCE_LOW
      ).apply { description = "Location tracking...." }
      notifManager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(latLng: String, accuracy: String, time: String): Notification {
    val tapIntent = PendingIntent.getActivity(
      this, 0,
      Intent(this, MainActivity::class.java),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    val contentText = if (time.isEmpty()) latLng else "$latLng  $accuracy  $time"
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Notification.Builder(this, CHANNEL)
        .setContentTitle("Location Tracker is active")
        .setContentText(contentText)
        .setSmallIcon(android.R.drawable.ic_menu_mylocation)
        .setContentIntent(tapIntent)
        .setOngoing(true)
        .build()
    } else {
      @Suppress("DEPRECATION")
      Notification.Builder(this)
        .setContentTitle("Location Tracker is active")
        .setContentText(contentText)
        .setSmallIcon(android.R.drawable.ic_menu_mylocation)
        .setContentIntent(tapIntent)
        .setOngoing(true)
        .build()
    }
  }
}
