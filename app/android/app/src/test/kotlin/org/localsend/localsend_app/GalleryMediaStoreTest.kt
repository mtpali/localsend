package org.localsend.localsend_app

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import android.database.sqlite.SQLiteQueryBuilder
import android.net.Uri
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.core.utils.DBUtils
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowContentResolver
import java.io.File

/** Runs the real photo_manager query and cursor conversion against Android's
 * SQLite API. The provider supplies MediaStore-shaped rows; no SQL fragments or
 * plugin query results are mocked. This does not emulate OEM permission policy.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 29, 34], manifest = Config.NONE)
class GalleryMediaStoreTest {
    private lateinit var provider: MediaProvider
    private lateinit var manager: PhotoManager
    private lateinit var option: FilterOption
    private val expectedIds = listOf(50L, 40L, 30L, 20L, 10L, 5L)

    @Before
    fun setUp() {
        val context = RuntimeEnvironment.getApplication()
        provider = MediaProvider(context)
        ShadowContentResolver.registerProviderInternal("media", provider)
        manager = PhotoManager(context)
        option = readOption("gallery-query.json")
    }

    private fun readOption(name: String): FilterOption {
        val resource = javaClass.classLoader!!.getResourceAsStream(name)
            ?: error("Run the gallery Flutter test with EXPORT_MEDIA_QUERY=true first")
        val arguments = resource.bufferedReader().use { JSONObject(it.readText()).toMap() }
        return ConvertUtils.convertToFilterOptions(arguments)!!
    }

    @After
    fun tearDown() = provider.close()

    @Test
    @Config(sdk = [28])
    fun absentFilterReproducesThePreviousGalleryFailure() {
        // Android's SQLiteQueryBuilder inserts ORDER BY before the supplied
        // sortOrder. An absent filter from the old screen generated LIMIT alone.
        val error = assertThrows(SQLiteException::class.java) {
            manager.getAssetListPaged(PhotoManager.ALL_ID, 3, 0, 80, null)
        }
        assertTrue(error.message.orEmpty(), error.message.orEmpty().contains("LIMIT"))
    }

    @Test
    fun actualDartFilterLoadsPhotosAndVideosAndCountsAllMedia() {
        val albums = manager.getAssetPathList(3, true, true, option)
        assertEquals(1, albums.size)
        assertEquals(6, albums.single().assetCount)
        val assets = manager.getAssetListPaged(albums.single().id, 3, 0, 80, option)
        assertEquals(expectedIds, assets.map { it.id })
        assertEquals(listOf(2, 2, 2, 2, 1, 1), assets.map { it.type })
    }

    @Test
    fun pagingRemainsStableWhenMediaHaveEqualOrFutureTimestamps() {
        val pages = (0..6).map { page ->
            manager.getAssetListPaged(PhotoManager.ALL_ID, 3, page, 1, option)
        }
        assertEquals(expectedIds, pages.flatten().map { it.id })
        assertTrue(pages.last().isEmpty())
    }

    @Test
    fun anUnknownAlbumNameDoesNotPreventLoadingItsMedia() {
        val assets = manager.getAssetListPaged("7", 3, 0, 80, option)
        assertEquals(expectedIds, assets.map { it.id })
    }

    @Test
    fun previousFilterHidLongVideosAndVideosWithUnknownDuration() {
        val previous = manager.getAssetListPaged(PhotoManager.ALL_ID, 3, 0, 80, readOption("gallery-previous-query.json"))
        assertEquals(listOf(20L, 10L, 5L), previous.map { it.id })
        val current = manager.getAssetListPaged(PhotoManager.ALL_ID, 3, 0, 80, option)
        assertEquals(expectedIds, current.map { it.id })
        assertEquals(0L, current.first { it.id == 30L }.duration)
        assertEquals(172800000L, current.first { it.id == 40L }.duration)
        assertEquals(2592000000L, current.first { it.id == 50L }.duration)
    }

    private fun JSONObject.toMap(): Map<String, Any?> = keys().asSequence().associateWith { key -> convert(get(key)) }

    private fun convert(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> value.toMap()
        is JSONArray -> (0 until value.length()).map { convert(value.get(it)) }
        else -> value
    }

    private class MediaProvider(context: Context) : ContentProvider() {
        private val database = SQLiteDatabase.create(null)
        private val files = mutableListOf<File>()

        init {
            val textColumns = setOf("_data", "_display_name", "title", "bucket_display_name", "mime_type", "relative_path")
            val columns = (DBUtils.keys().toList() + "relative_path").distinct()
            database.execSQL("CREATE TABLE files (${columns.joinToString { column ->
                "\"$column\" ${if (column in textColumns) "TEXT" else "INTEGER"}"
            }})")
            for ((id, type) in listOf(5L to 1, 10L to 1, 20L to 3, 30L to 3, 40L to 3, 50L to 3, 100L to 2)) {
                val file = File(context.cacheDir, "gallery-native-test-$id").apply { writeText("media fixture") }
                files.add(file)
                val row = ContentValues().apply {
                    columns.filterNot { it in textColumns }.forEach { put(it, 0) }
                    put("_id", id)
                    put("media_type", type)
                    put("_data", file.absolutePath)
                    put("_display_name", file.name)
                    put("title", file.name)
                    put("bucket_id", 7)
                    putNull("bucket_display_name")
                    put("width", 400)
                    put("height", 300)
                    when (id) {
                        30L -> putNull("duration")
                        40L -> put("duration", 172800000L)
                        50L -> put("duration", 2592000000L)
                        else -> put("duration", 5000)
                    }
                    put("date_added", 4102444800L) // Future/equal timestamps must not hide media.
                    put("date_modified", 4102444800L)
                    put("datetaken", 4102444800000L)
                    put("mime_type", if (type == 3) "video/mp4" else "image/jpeg")
                    put("relative_path", "Pictures/")
                }
                database.insertOrThrow("files", null, row)
            }
        }

        override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor =
            SQLiteQueryBuilder().apply { tables = "files" }.query(database, projection, selection, selectionArgs, null, null, sortOrder)

        override fun onCreate() = true
        override fun getType(uri: Uri): String = "vnd.android.cursor.dir/media"
        override fun insert(uri: Uri, values: ContentValues?): Uri? = throw UnsupportedOperationException()
        override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = throw UnsupportedOperationException()
        override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = throw UnsupportedOperationException()

        fun close() {
            database.close()
            files.forEach { it.delete() }
        }
    }
}
