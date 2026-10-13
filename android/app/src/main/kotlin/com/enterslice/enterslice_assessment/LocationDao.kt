package com.enterslice.enterslice_assessment

import android.content.ContentValues
import android.database.Cursor

class LocationDao(private val db: LocationDatabase) {
  fun insert(lat: Double, lng: Double, accuracy: Float, timestamp: Long): Long {
    val values = ContentValues().apply {
      put("latitude", lat)
      put("longitude", lng)
      put("accuracy", accuracy)
      put("timestamp", timestamp)
    }
    return db.writableDatabase.insert("locations", null, values)
  }

  fun getLastLocation(): Map<String, Any>? {
    val cursor =
      db.readableDatabase.query("locations", null, null, null, null, null, "timestamp DESC", "1")
    return cursor.use { if (it.moveToFirst()) it.toMap() else null }
  }

  fun getHistory(limit: Int): List<Map<String, Any>> {
    val cursor = db.readableDatabase.query(
      "locations",
      null,
      null,
      null,
      null,
      null,
      "timestamp DESC",
      limit.toString()
    )
    return cursor.use { c ->
      val list = mutableListOf<Map<String, Any>>()
      while (c.moveToNext()) list.add(c.toMap())
      list
    }
  }

  fun remove_all(): Int = db.writableDatabase.delete("locations", null, null)
  private fun Cursor.toMap(): Map<String, Any> = mapOf(
    "id" to getLong(getColumnIndexOrThrow("id")),
    "latitude" to getDouble(getColumnIndexOrThrow("latitude")),
    "longitude" to getDouble(getColumnIndexOrThrow("longitude")),
    "accuracy" to getFloat(getColumnIndexOrThrow("accuracy")).toDouble(),
    "timestamp" to getLong(getColumnIndexOrThrow("timestamp"))
  )
}
