package com.enterslice.enterslice_assessment

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
    val prefs = context.getSharedPreferences("all_prefs", Context.MODE_PRIVATE)
    if (!prefs.getBoolean("is_tracking", false)) return
    val interval = prefs.getInt("interval", 30)
    val serviceIntent = Intent(context, LocationService::class.java).putExtra("interval", interval)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      context.startForegroundService(serviceIntent)
    } else {
      context.startService(serviceIntent)
    }
  }
}
