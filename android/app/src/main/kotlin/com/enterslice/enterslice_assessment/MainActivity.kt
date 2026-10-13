package com.enterslice.enterslice_assessment

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

  private val methodChannelName = "enterslice_assessment/location_methods"
  private val eventChannelName = "enterslice_assessment/location_stream"

  private var pendingPermResult: MethodChannel.Result? = null
  private val reqFine = 101
  private val reqBackground = 102
  private val reqNotification = 103

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val dao = LocationDao(LocationDatabase(this))

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "startTracking" -> {
            val interval = call.argument<Int>("interval") ?: 30
            val intent = Intent(this, LocationService::class.java).putExtra("interval", interval)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
            else startService(intent)
            result.success(mapOf("success" to true))
          }

          "stopTracking" -> {
            stopService(Intent(this, LocationService::class.java))
            result.success(mapOf("success" to true))
          }

          "isTracking" -> result.success(mapOf("tracking" to LocationService.isRunning))
          "getLastLocation" -> result.success(dao.getLastLocation())
          "getHistory" -> result.success(dao.getHistory(50))
          "clearHistory" -> {
            val count = dao.remove_all()
            result.success(mapOf("success" to true, "deleted" to count))
          }

          "setInterval" -> {
            val interval = call.argument<Int>("interval") ?: 30
            LocationService.updateInterval(this, interval)
            result.success(mapOf("success" to true))
          }

          "checkPermissions" -> {
            result.success(currentPermissionState())
          }

          "requestFineLocation" -> {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
              == PackageManager.PERMISSION_GRANTED
            ) {
              result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            } else {
              pendingPermResult = result
              ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), reqFine
              )
            }
          }

          "requestBackgroundLocation" -> {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
              result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            } else if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
              )
              == PackageManager.PERMISSION_GRANTED
            ) {
              result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            } else {
              pendingPermResult = result
              ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), reqBackground
              )
            }
          }

          "requestNotifications" -> {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
              result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            } else if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
              )
              == PackageManager.PERMISSION_GRANTED
            ) {
              result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            } else {
              pendingPermResult = result
              ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), reqNotification
              )
            }
          }

          "openAppSettings" -> {
            startActivity(
              Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
              }
            )
            result.success(null)
          }

          else -> result.notImplemented()
        }
      }

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
      .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
          LocationService.locationSink = events
        }

        override fun onCancel(arguments: Any?) {
          LocationService.locationSink = null
        }
      })
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode !in listOf(reqFine, reqBackground, reqNotification)) return
    val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
    val canAskAgain =
      permissions.isNotEmpty() && shouldShowRequestPermissionRationale(permissions[0])
    pendingPermResult?.success(
      mapOf("granted" to granted, "permanentlyDenied" to (!granted && !canAskAgain))
    )
    pendingPermResult = null
  }

  private fun currentPermissionState(): Map<String, Boolean> {
    val fineGranted = ContextCompat.checkSelfPermission(
      this,
      Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
    val bgGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_BACKGROUND_LOCATION
      ) == PackageManager.PERMISSION_GRANTED
    } else true
    val notifGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.POST_NOTIFICATIONS
      ) == PackageManager.PERMISSION_GRANTED
    } else true
    return mapOf(
      "fineLocation" to fineGranted,
      "backgroundLocation" to bgGranted,
      "notifications" to notifGranted
    )
  }
}
