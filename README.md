<div align="center">

# flixel-screenshot-plugin
### A simple screenshot recorder for Flixel

<img src="preview.gif" width="400" />

</div>

# Installation
1. Make sure you have `flixel` and `openfl` installed.
2. Through a command prompt, install the library using:
    - `haxelib install flixel-screenshot-plugin` for latest stable release, or
    - `haxelib git flixel-screenshot-plugin http://github.com/sayofthelor/flixel-screenshot-plugin` to get the latest changes (may be unstable)
3. Add the library into your project file (`project.xml`/`project.hxp`):
```xml
<haxelib name="flixel-screenshot-plugin" />
```
4. In your project's main module, after initializing an `FlxGame` instance, initialize an instance of the plugin:
```haxe
flixel.FlxG.plugins.addPlugin(new flixel.addons.plugin.FlxScreenshotPlugin());
```
5. You're done!

The `FlxScreenshotPlugin` instance holds many properties you can change to customize the plugin.
