package flixel.addons.plugin;

/**
 * Enum which determines the file format used by an `FlxScreenshotPlugin` instance to write screenshots to disk.
 */
enum ScreenshotFileFormat {
    /**
     * Screenshots are written to disk as `.png` files.
     */
    PNG;

    /**
     * Screenshots are written to disk as `.jpg` files.
     * The quality parameter should be a value between 1 and 100,
     * where 1 means the lowest quality and 100 means the highest quality.
     * The higher the value, the larger the file size.
     */
    JPEG(quality: Int);
}
