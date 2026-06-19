package com.example.safescan

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.example.safescan/wifi"
    private val wifiPermissionRequest = 7301

    private var permissionResult: MethodChannel.Result? = null
    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var wifiConnectResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentSsid" -> result.success(getCurrentSsid())
                "requestWifiPermissions" -> requestWifiPermissions(result)
                "connectToWifi" -> {
                    val ssid = call.argument<String>("ssid").orEmpty()
                    val password = call.argument<String>("password").orEmpty()
                    if (ssid.isBlank()) {
                        result.error("invalid_ssid", "SSID vacío", null)
                    } else {
                        connectToWifi(ssid, password, result)
                    }
                }
                "openWifiSettings" -> {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                    result.success(true)
                }
                "bindActiveWifi" -> bindActiveWifi(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestWifiPermissions(result: MethodChannel.Result) {
        val missing = requiredWifiPermissions().filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isEmpty()) {
            result.success(mapOf("granted" to true, "missing" to emptyList<String>()))
            return
        }

        if (permissionResult != null) {
            result.error(
                "permission_request_active",
                "Ya hay una solicitud de permisos activa",
                null
            )
            return
        }

        permissionResult = result
        requestPermissions(missing.toTypedArray(), wifiPermissionRequest)
    }

    private fun requiredWifiPermissions(): List<String> {
        val permissions = mutableListOf(Manifest.permission.ACCESS_FINE_LOCATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }
        return permissions
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != wifiPermissionRequest) return

        val denied = permissions.filterIndexed { index, _ ->
            grantResults.getOrNull(index) != PackageManager.PERMISSION_GRANTED
        }
        permissionResult?.success(
            mapOf(
                "granted" to denied.isEmpty(),
                "missing" to denied
            )
        )
        permissionResult = null
    }

    private fun connectToWifi(
        ssid: String,
        password: String,
        result: MethodChannel.Result
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            connectToWifiWithSpecifier(ssid, password, result)
        } else {
            connectToWifiLegacy(ssid, password, result)
        }
    }

    private fun connectToWifiWithSpecifier(
        ssid: String,
        password: String,
        result: MethodChannel.Result
    ) {
        val connectivityManager = connectivityManager()

        releaseWifiNetwork()
        wifiConnectResult = result

        val specifierBuilder = WifiNetworkSpecifier.Builder().setSsid(ssid)
        if (password.isNotBlank()) {
            specifierBuilder.setWpa2Passphrase(password)
        }

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifierBuilder.build())
            .build()

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                connectivityManager.bindProcessToNetwork(network)
                runOnUiThread {
                    wifiConnectResult?.success(
                        mapOf("connected" to true, "ssid" to ssid)
                    )
                    wifiConnectResult = null
                }
            }

            override fun onUnavailable() {
                runOnUiThread {
                    wifiConnectResult?.success(
                        mapOf(
                            "connected" to false,
                            "message" to "Android no aprobó la conexión WiFi"
                        )
                    )
                    wifiConnectResult = null
                    wifiNetworkCallback = null
                }
            }

            override fun onLost(network: Network) {
                connectivityManager.bindProcessToNetwork(null)
                wifiNetworkCallback = null
            }
        }

        wifiNetworkCallback = callback

        try {
            connectivityManager.requestNetwork(request, callback, 30_000)
        } catch (error: SecurityException) {
            wifiConnectResult = null
            wifiNetworkCallback = null
            result.error(
                "wifi_permission_denied",
                "Faltan permisos para conectarse por WiFi",
                error.message
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun connectToWifiLegacy(
        ssid: String,
        password: String,
        result: MethodChannel.Result
    ) {
        val wifiManager = applicationContext
            .getSystemService(Context.WIFI_SERVICE) as WifiManager

        if (!wifiManager.isWifiEnabled) {
            wifiManager.isWifiEnabled = true
        }

        val quotedSsid = quote(ssid)
        var networkId = wifiManager.configuredNetworks
            ?.firstOrNull { it.SSID == quotedSsid }
            ?.networkId ?: -1

        if (networkId == -1) {
            val config = WifiConfiguration().apply {
                SSID = quotedSsid
                if (password.isBlank()) {
                    allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                } else {
                    preSharedKey = quote(password)
                }
            }
            networkId = wifiManager.addNetwork(config)
        }

        if (networkId == -1) {
            result.success(
                mapOf(
                    "connected" to false,
                    "message" to "No se pudo guardar la red WiFi"
                )
            )
            return
        }

        wifiManager.disconnect()
        val enabled = wifiManager.enableNetwork(networkId, true)
        val reconnected = wifiManager.reconnect()
        result.success(mapOf("connected" to (enabled && reconnected), "ssid" to ssid))
    }

    private fun bindActiveWifi(result: MethodChannel.Result) {
        try {
            val connectivityManager = connectivityManager()
            val activeNetwork = connectivityManager.activeNetwork
            if (activeNetwork == null) {
                result.success(
                    mapOf(
                        "bound" to false,
                        "message" to "No hay red activa en el teléfono"
                    )
                )
                return
            }

            val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
            if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) != true) {
                result.success(
                    mapOf(
                        "bound" to false,
                        "message" to "La red activa no es WiFi"
                    )
                )
                return
            }

            val bound = connectivityManager.bindProcessToNetwork(activeNetwork)
            result.success(
                mapOf(
                    "bound" to bound,
                    "ssid" to getCurrentSsid()
                )
            )
        } catch (error: SecurityException) {
            result.error(
                "wifi_permission_denied",
                "Faltan permisos para usar la red WiFi activa",
                error.message
            )
        }
    }

    private fun releaseWifiNetwork() {
        val callback = wifiNetworkCallback ?: return
        try {
            connectivityManager().unregisterNetworkCallback(callback)
        } catch (_: Exception) {
        } finally {
            wifiNetworkCallback = null
            connectivityManager().bindProcessToNetwork(null)
        }
    }

    private fun getCurrentSsid(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val activeNetwork = connectivityManager().activeNetwork
            val capabilities = connectivityManager().getNetworkCapabilities(activeNetwork)
            val wifiInfo = capabilities?.transportInfo as? WifiInfo
            normalizeSsid(wifiInfo?.ssid).takeIf { it.isNotBlank() }?.let {
                return it
            }
        }

        val wifiManager = applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return ""
        return normalizeSsid(wifiManager.connectionInfo?.ssid)
    }

    private fun normalizeSsid(rawSsid: String?): String {
        var ssid = rawSsid.orEmpty()
        if (ssid == "<unknown ssid>") return ""
        if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid = ssid.substring(1, ssid.length - 1)
        }
        return ssid
    }

    private fun connectivityManager(): ConnectivityManager {
        return applicationContext
            .getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }

    private fun quote(value: String): String = "\"$value\""
}
