package flixel.addons.plugin;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;

#if FLX_KEYBOARD
import flixel.input.keyboard.FlxKey;
#end

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.JPEGEncoderOptions;
import openfl.display.PNGEncoderOptions;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

import lime.graphics.Image;
import lime.math.Rectangle as LimeRectangle;

import sys.FileSystem;
import sys.io.File;
import sys.thread.Deque;
import sys.thread.Thread;

#if !sys
#error "FlxScreenshotPlugin is only available in sys targets.";
#end

/**
 * Plugin allowing screenshots to be taken by the user directly within the game.
 * It is best to add a singular instance of this class into the `FlxG.plugins` registery.
 */
class FlxScreenshotPlugin extends FlxBasic {
	#if FLX_KEYBOARD
	/**
	 * Optional hotkeys for taking screenshots.
	 */
	public var hotKeys: Array<FlxKey> = [FlxKey.F2];
	#end

	/**
	 * File format to use when writing screenshots to disk.
	 */
	public var saveFormat(default, set): ScreenshotFileFormat = PNG;

	/**
	 * Directory in which screenshots are saved.
	 */
	public var screenshotFolder(default, set): String = "screenshots";

	/**
	 * Color of the flash effect.
	 */
	public var flashColor(default, set): FlxColor = 0xFFFFFFFF;

	/**
	 * Color of the outline around the screenshot preview.
	 */
	public var outlineColor(default, set): FlxColor = 0xFFFFFFFF;

	/**
	 * Optional sound asset to play when a screenshot is taken.
	 */
	public var sound(default, set): FlxSoundAsset = null;

	static inline final outlineSize: Int = 5;
	static inline final displayOffset: Int = 5;

	var _displayContainer: Sprite;
	var _flashSprite: Sprite;
	var _screenshotPreviewContainer: Sprite;
	var _screenshotPreview: Bitmap;
	var _screenshotPreviewOutline: Bitmap;
	var _screenshotDisplayTimer: Float = 0;

	var _flxSound: FlxSound;

	var _fileNameSuffix: String;
	var _imageEncoderOptions: Any;

	// ensure we only take the game display into the screenshot.
	var _screenshotRegion: LimeRectangle = new LimeRectangle();

	// some operations are very slow so we're offloading them to a separate thread.
	// we use this deque to send screenshot pixels to be processed by the thread.
	var _messageQueue: Deque<Image> = new Deque();
	
	public function new(): Void {
		super();

		_displayContainer = new Sprite();
		FlxG.addChildBelowMouse(_displayContainer);

		_screenshotPreviewContainer = new Sprite();
		_screenshotPreviewContainer.alpha = 0;
		
		_screenshotPreviewOutline = new Bitmap(new BitmapData(Std.int(FlxG.width / 5) + outlineSize, Std.int(FlxG.height / 5) + outlineSize, true, outlineColor));
		_screenshotPreviewOutline.x = displayOffset;
		_screenshotPreviewOutline.y = displayOffset;
		
		_screenshotPreview = new Bitmap();
		_screenshotPreview.x = displayOffset + outlineSize / 2;
		_screenshotPreview.y = displayOffset + outlineSize / 2;

		_screenshotPreviewContainer.addChild(_screenshotPreviewOutline);
		_screenshotPreviewContainer.addChild(_screenshotPreview);
		
		_flashSprite = new Sprite();
		_flashSprite.alpha = 0;

		_displayContainer.addChild(_screenshotPreviewContainer);
		_displayContainer.addChild(_flashSprite);

		_resizeDisplay();
		_setSaveFormat(saveFormat);
		_drawFlash(flashColor);

		FlxG.signals.gameResized.add(_resizeDisplay);

		Thread.create(_screenshotWorker_loop);
	}

	override function update(elapsed: Float): Void {
		#if FLX_KEYBOARD
		if (FlxG.keys.anyJustPressed(hotKeys))
			takeScreenshot();
		#end

		if (_flashSprite.alpha > 0)
			_flashSprite.alpha -= elapsed * 4;

		if (_screenshotDisplayTimer > 0)
			_screenshotDisplayTimer -= elapsed;
		else if (_screenshotPreviewContainer.alpha > 0)
			_screenshotPreviewContainer.alpha -= elapsed * 2;
	}

	public function takeScreenshot(): Void {
		_messageQueue.push(FlxG.stage.window.readPixels(_screenshotRegion));
	}

	function _screenshotWorker_loop(): Void {
		while (true) {
			var pixels: Image = _messageQueue.pop(true);

			if (pixels == null) {
				// we told the thread to stop, so break the loop.
				break;
			}

			var bitmapData: BitmapData = BitmapData.fromImage(pixels);
			var imageData: ByteArray = bitmapData.encode(bitmapData.rect, _imageEncoderOptions);

			var fileName: String = '${screenshotFolder}/Screenshot ' + DateTools.format(Date.now(), "%Y-%m-%d %H-%M-%S") + _fileNameSuffix;

			// ensure the parent directory exists before we write the screenshot into disk.
			if (!FileSystem.exists(screenshotFolder + "/"))
				FileSystem.createDirectory(screenshotFolder + "/");

			File.saveBytes(fileName, imageData);

			_screenshotPreview.bitmapData = bitmapData;
			_screenshotPreview.height = FlxG.height / 5;
		    _screenshotPreview.width = FlxG.width / 5;

			_flashSprite.alpha = 1;
		    _screenshotPreviewContainer.alpha = 1;
			_screenshotDisplayTimer = 0.5;

		    if (sound != null)
			    _flxSound.play(true);
		}
	}

	function _resizeDisplay(?_, ?_): Void {
		var scale: FlxPoint = FlxG.scaleMode.scale;
		var offset: FlxPoint = FlxG.scaleMode.offset;
		var gameSize: FlxPoint = FlxG.scaleMode.gameSize;

		_displayContainer.scaleX = scale.x;
		_displayContainer.scaleY = scale.y;

		_screenshotRegion.setTo(offset.x, offset.y, gameSize.x, gameSize.y);
	}

	function _setSaveFormat(format: ScreenshotFileFormat): Void {
		switch (format) {
			case PNG:
				_imageEncoderOptions = new PNGEncoderOptions(false);
				_fileNameSuffix = ".png";

			case JPEG(quality):
				_imageEncoderOptions = new JPEGEncoderOptions(quality);
				_fileNameSuffix = ".jpg";
		}
	}

	function _drawFlash(color: FlxColor): Void {
		_flashSprite.graphics.clear();
		_flashSprite.graphics.beginFill(color.rgb, color.alphaFloat);
		_flashSprite.graphics.drawRect(0, 0, FlxG.width, FlxG.height);
		_flashSprite.graphics.endFill();
	}

	function _drawOutline(color: FlxColor): Void {
		var bitmapData:BitmapData = _screenshotPreviewOutline.bitmapData;
		bitmapData.fillRect(new Rectangle(0, 0, bitmapData.width, bitmapData.height), color);
	}

	override function destroy(): Void {
		FlxG.signals.gameResized.remove(_resizeDisplay);
		FlxG.stage.removeChild(_displayContainer);

		// shutdown worker thread
		_messageQueue.push(null);

		sound = null;

		super.destroy();
	}

	function set_saveFormat(v: ScreenshotFileFormat): ScreenshotFileFormat {
		if (v == null) {
			FlxG.log.warn("[FlxScreenshotPlugin] Save format must be specified!");
			return saveFormat;
		}

		saveFormat = v;
		_setSaveFormat(v);
		return v;
	}

	function set_screenshotFolder(v: String): String {
		if (v == null || v.length == 0) {
			FlxG.log.warn("[FlxScreenshotPlugin] A screenshot folder must be specified!");
			return screenshotFolder;
		}

		return screenshotFolder = v;
	}

	function set_flashColor(v: FlxColor): FlxColor {
		flashColor = v;
		_drawFlash(v);
		return v;
	}

	function set_outlineColor(v: FlxColor): FlxColor {
		outlineColor = v;
		_drawOutline(v);
		return v;
	}

	function set_sound(v: FlxSoundAsset): FlxSoundAsset {
		if (v != null) {
			if (_flxSound == null)
				_flxSound = new FlxSound();
			_flxSound.loadEmbedded(v);
		} else if (_flxSound != null) {
			_flxSound.destroy();
			_flxSound = null;
		}

		return sound = v;
	}
}
