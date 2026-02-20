package fse.cache
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import starling.textures.Texture;
	import starling.textures.SubTexture;
	
	import fse.utils.Hash;
	import fse.utils.MD5;
	import fse.conf.Config;

	public class CacheManager
	{
		private static var _instance:CacheManager;
		
		// 存储纹理 (可能是 SubTexture，也可能是独立的 ConcreteTexture)
		private var _cache:Dictionary;
		
		// 图集页面管理
		private var _atlasPages:Vector.<AtlasPage>;
		private var _keyToPageMap:Dictionary; // Key -> AtlasPage

		// 引用计数
		private var _historyMaxCount:Dictionary;
		private var _currentRefCount:Dictionary;

		public static var PERSIST_THRESHOLD:int = Config.CACHE_THRESHOLD;
		
		// [新增] 只有小于此尺寸的图片才进图集，大的单独管理
		// 建议：2048 (图集最大尺寸) 或者 512 (根据你的业务决定)
		// 如果一张图占据了图集 1/4 以上的空间，进图集的意义其实不大了
		public static const MAX_ATLAS_ITEM_SIZE:int = 1024; 
		public static const ATLAS_SIZE:int = 2048;

		public function CacheManager()
		{
			if (_instance) throw new Error("Singleton");
			_cache = new Dictionary();
			_historyMaxCount = new Dictionary();
			_currentRefCount = new Dictionary();
			_atlasPages = new Vector.<AtlasPage>();
			_keyToPageMap = new Dictionary();
		}

		public static function get instance():CacheManager
		{
			if (!_instance) _instance = new CacheManager();
			return _instance;
		}

		public function getTexture(bmd:BitmapData):Object
		{
			if (!bmd) return null;
			
			var key:String = Hash.getFastHash(bmd);
			var tex:Texture;

			// 1. 命中缓存 (无论是图集里的还是独立的，都在这里取)
			if (_cache[key])
			{
				tex = _cache[key];
				if(Config.TRACE_CACHE) trace("[CacheManager] ✅ 命中: " + key.substr(0, 6));
			}
			else
			{
				if(Config.TRACE_CACHE) trace("[CacheManager] 🆕 创建: " + key.substr(0, 6));
				
				// 2. [新增] 尺寸检查：分流策略
				if (bmd.width > MAX_ATLAS_ITEM_SIZE || bmd.height > MAX_ATLAS_ITEM_SIZE)
				{
					// --- 策略 A: 大图 (Standalone) ---
					if(Config.TRACE_CACHE) trace("   -> 尺寸过大 ("+bmd.width+"x"+bmd.height+")，作为独立纹理管理");
					
					// 直接创建独立纹理，不进图集
					tex = Texture.fromBitmapData(bmd, false);
					
					// 不需要存入 _keyToPageMap，因为它不属于任何 Page
				}
				else
				{
					// --- 策略 B: 小图 (Atlas Packing) ---
					var success:Boolean = false;
					
					// 遍历现有页
					for each (var page:AtlasPage in _atlasPages)
					{
						tex = page.insert(bmd, key);
						if (tex)
						{
							_keyToPageMap[key] = page;
							success = true;
							break;
						}
					}
					
					// 所有页都满了，开新房
					if (!success)
					{
						if(Config.TRACE_CACHE) trace("   -> 创建新图集页 (Page " + (_atlasPages.length + 1) + ")");
						var newPage:AtlasPage = new AtlasPage(ATLAS_SIZE, ATLAS_SIZE); 
						_atlasPages.push(newPage);
						
						tex = newPage.insert(bmd, key);
						_keyToPageMap[key] = newPage;
					}
				}
				
				// 3. 统一入库
				_cache[key] = tex;
				
				if (!_historyMaxCount[key]) _historyMaxCount[key] = 0;
				if (!_currentRefCount[key]) _currentRefCount[key] = 0;
			}

			incrementReference(key);
			return { texture: tex, key: key };
		}
		
		public function releaseTexture(key:String):void
		{
			if (!key || !_cache[key]) return;
			
			if (_currentRefCount[key] > 0) _currentRefCount[key]--;
			
			var current:int = _currentRefCount[key];
			var max:int = _historyMaxCount[key];

			if (current <= 0)
			{
				// 无论是独立纹理还是图集纹理，策略都是一样的：不热就销毁
				if (max < PERSIST_THRESHOLD)
				{
					realDispose(key);
				}
				else
				{
					if(Config.TRACE_CACHE) trace("[Cache] ❄️ 休眠: " + key.substr(0, 6));
				}
			}
		}

		public function tryDisposeSpecific(key:String):void
		{
			if (!_cache[key]) return;
			if (_currentRefCount[key] <= 0) realDispose(key);
		}

		public function purge():void
		{
			if(Config.TRACE_CACHE) trace("[CacheManager] 🔥 PURGE");
			
			var keysToDelete:Vector.<String> = new Vector.<String>();
			for (var key:String in _cache)
			{
				if (_currentRefCount[key] <= 0) keysToDelete.push(key);
			}
			
			for each (var k:String in keysToDelete) realDispose(k);
			
			cleanupEmptyPages();
		}
		
		private function incrementReference(key:String):void
		{
			_currentRefCount[key]++;
			if (_currentRefCount[key] > _historyMaxCount[key])
			{
				_historyMaxCount[key] = _currentRefCount[key];
			}
		}

		/**
		 * 物理销毁 (核心修改点)
		 */
		private function realDispose(key:String):void
		{
			var tex:Texture = _cache[key];
			var page:AtlasPage = _keyToPageMap[key];
			
			if (tex)
			{
				if (page)
				{
					// 情况 A: 这是一个图集里的 SubTexture
					// 1. 通知图集回收空间
					page.release(key);
					// 2. 销毁 SubTexture 引用 (不销毁显存)
					tex.dispose();
					// 3. 清理映射
					delete _keyToPageMap[key];
					if(Config.TRACE_CACHE) trace("[Cache] ♻️ 回收图集区域: " + key.substr(0, 6));
				}
				else
				{
					// 情况 B: 这是一个独立的大纹理
					// 直接销毁显存
					tex.dispose();
					if(Config.TRACE_CACHE) trace("[Cache] 💀 销毁独立纹理: " + key.substr(0, 6));
				}
				
				delete _cache[key];
				delete _currentRefCount[key];
				delete _historyMaxCount[key];
			}
		}
		
		private function cleanupEmptyPages():void
		{
			for (var i:int = _atlasPages.length - 1; i >= 0; i--)
			{
				var page:AtlasPage = _atlasPages[i];
				if (page.isEmpty)
				{
					if(Config.TRACE_CACHE) trace("[Cache] 🗑️ 移除空图集页: " + i);
					page.dispose();
					_atlasPages.splice(i, 1);
				}
			}
		}
	}
}