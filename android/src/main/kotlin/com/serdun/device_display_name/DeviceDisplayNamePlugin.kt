package com.serdun.device_display_name

import android.content.Context
import android.os.Build
import android.provider.Settings

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import java.lang.reflect.Method

/**
 * Reads what the device carries that can name it. Which keys, and which value wins, is decided on the
 * Dart side; this side only reads and leaves out what is empty or unreadable.
 */
class DeviceDisplayNamePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private companion object {
        const val METHOD_CHANNEL_NAME = "device_display_name"
        const val METHOD_READ = "read"
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == METHOD_READ) {
            val keys = keysFor(call.argument<Map<String?, Map<String, List<String>>>>("keysByMaker").orEmpty())
            val features = call.argument<List<String>>("features").orEmpty()
            result.success(read(keys["properties"].orEmpty(), keys["globalSettings"].orEmpty(), features))
        } else {
            result.notImplemented()
        }
    }

    // The Dart side sends the keys of every maker by lower-case brand; the entry under null is for a maker it does
    // not list. Picking here keeps it to one call and to the device's own maker's keys.
    private fun keysFor(keysByMaker: Map<String?, Map<String, List<String>>>): Map<String, List<String>> =
        keysByMaker[Build.BRAND.orEmpty().lowercase()]
            ?: keysByMaker[Build.MANUFACTURER.orEmpty().lowercase()]
            ?: keysByMaker[null]
            ?: emptyMap()

    private fun read(
        propertyKeys: List<String>,
        globalSettingKeys: List<String>,
        featureNames: List<String>,
    ): Map<String, Any> = mapOf(
        "manufacturer" to Build.MANUFACTURER.orEmpty(),
        "brand" to Build.BRAND.orEmpty(),
        "model" to Build.MODEL.orEmpty(),
        "device" to Build.DEVICE.orEmpty(),
        "product" to Build.PRODUCT.orEmpty(),
        "properties" to propertyKeys.mapNotNull { key -> SystemProperty.read(key)?.let { key to it } }.toMap(),
        "globalSettings" to globalSettingKeys.mapNotNull { key -> globalSetting(key)?.let { key to it } }.toMap(),
        // What kind of device it is: the features the Dart side tells the kind by, and the smallest screen width,
        // which is fixed per device whatever the orientation.
        "features" to featureNames.filter { feature -> hasFeature(feature) },
        "smallestScreenWidthDp" to context.resources.configuration.smallestScreenWidthDp,
        // The build says "tablet" on tablets narrower than 600 dp (the 8-inch Lenovo Tab M8 is 533 dp); the
        // property is labelled build_prop, which apps may read.
        "characteristics" to SystemProperty.read("ro.build.characteristics").orEmpty(),
    )

    private fun hasFeature(name: String): Boolean = try {
        context.packageManager.hasSystemFeature(name)
    } catch (e: Exception) {
        false
    }

    // Keys a maker adds to Settings.Global (Samsung default_device_name, Huawei
    // unified_default_device_name) are not covered by the @Readable restriction of Android 12, which
    // only applies to keys the platform itself declares. A key that is restricted after all throws a
    // SecurityException and counts as absent.
    private fun globalSetting(key: String): String? = try {
        Settings.Global.getString(context.contentResolver, key)?.takeIf { it.isNotBlank() }
    } catch (e: Exception) {
        null
    }
}

/**
 * System properties by key, through android.os.SystemProperties.
 *
 * The class is a system API, not on the hidden-API blocklist at any targetSdk, so reflection reaches it.
 * What it may return is decided by the SELinux label of each property: a label apps cannot read
 * (vendor_default_prop, and any unlabelled key since Android 12) gives an empty string, not an error.
 */
internal object SystemProperty {
    private val get: Method? = try {
        Class.forName("android.os.SystemProperties").getMethod("get", String::class.java)
    } catch (e: Exception) {
        null
    }

    fun read(key: String): String? = try {
        (get?.invoke(null, key) as String?)?.takeIf { it.isNotBlank() }
    } catch (e: Exception) {
        null
    }
}
