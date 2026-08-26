package com.phucdnh.navigationiq.garmin

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Listens for Bluetooth state changes.
 * When BT turns ON after being disabled, triggers GarminManager.restartConnection()
 * so the ConnectIQ SDK rediscovers the paired watch automatically.
 *
 * Registered/unregistered programmatically in NavNotificationService (not in manifest)
 * to avoid unnecessary wakeups when the service is not running.
 */
class BluetoothStateReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BluetoothStateReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return

        val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
        Log.d(TAG, "Bluetooth state changed: $state")

        when (state) {
            BluetoothAdapter.STATE_ON -> {
                Log.i(TAG, "Bluetooth ON – triggering Garmin reconnect")
                // Use applicationContext to avoid activity context leaks
                GarminManager.restartConnection(context.applicationContext)
            }
            BluetoothAdapter.STATE_OFF -> {
                Log.i(TAG, "Bluetooth OFF – Garmin connection will be lost")
                // GarminManager.onSdkShutDown will fire naturally; no action needed here
            }
        }
    }
}
