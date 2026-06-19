package com.sawitify.sawitify

import android.content.Context

import android.content.Intent

import android.media.AudioDeviceInfo

import android.media.AudioManager

import android.provider.Settings

import io.flutter.embedding.android.FlutterActivity

import io.flutter.embedding.engine.FlutterEngine

import io.flutter.plugin.common.MethodChannel

import androidx.mediarouter.media.MediaRouter
import androidx.mediarouter.media.MediaRouter.RouteInfo

class MainActivity : FlutterActivity() {

    companion object {

        private const val CHANNEL =
            "audio_output"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(
            flutterEngine
        )

        MethodChannel(

            flutterEngine.dartExecutor
                .binaryMessenger,

            CHANNEL

        ).setMethodCallHandler {

                call,
                result ->

            when (

                call.method

            ) {

                "getDevices" -> {

                    result.success(

                        getDevices()
                    )
                }

                "openBluetoothSettings" -> {

                    openBluetoothSettings()

                    result.success(
                        null
                    )
                }

                else -> {

                    result.notImplemented()
                }
            }
        }
    }

    private fun getDevices():

            List<Map<String, Any>> {

        val mediaRouter =

            MediaRouter.getInstance(
                this
            )

        val selected =

            mediaRouter
                .selectedRoute

        val name =

            selected.name
                .toString()

        val isPhone =

            selected.isDefault

        return listOf(

            mapOf(

                "name" to

                        if (

                            isPhone

                        ) {

                            android.os.Build.MODEL

                        } else {

                            name
                        },

                "isBluetooth" to

                        !isPhone
            )
        )
    }

    private fun openBluetoothSettings() {

        val intent =

            Intent(

                Settings
                    .ACTION_BLUETOOTH_SETTINGS
            )

        startActivity(
            intent
        )
    }
}