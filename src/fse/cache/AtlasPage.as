package fse.cache
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.textures.RenderTexture;
	import starling.textures.SubTexture;
	import starling.textures.Texture;

	/**
	 * 单个图集页面 (修复版：Guillotine算法 + 自动擦除)
	 * 解决：纹理重叠、残影、画面错乱问题
	 */
	public class AtlasPage
	{
		private var _rootTexture:RenderTexture;
		private var _freeRects:Vector.<Rectangle>;
		private var _usedRects:Object;
		
		private var _width:int;
		private var _height:int;

		// 纹理间隔 (防出血)
		private static const PADDING:int = 2;
		
		// 橡皮擦工具 (复用以节省性能)
		private var _eraserHelper:Quad;
		
		public function AtlasPage(width:int = 2048, height:int = 2048)
		{
			_width = width;
			_height = height;
			_freeRects = new Vector.<Rectangle>();
			_usedRects = {};
			
			// 初始化橡皮擦 (黑色，BlendMode.ERASE)
			_eraserHelper = new Quad(32, 32, 0x0);
			_eraserHelper.blendMode = BlendMode.ERASE;
			
			_freeRects.push(new Rectangle(0, 0, width, height));
			
			_rootTexture = new RenderTexture(width, height, true);
		}
		
		
		// [新增] 矩形对象池与渲染复用工具
		private static var _rectPool:Vector.<Rectangle> = new Vector.<Rectangle>();
		private static var _drawHelper:Image;
		
		private function getRect(x:Number, y:Number, w:Number, h:Number):Rectangle {
			if (_rectPool.length > 0) {
				var r:Rectangle = _rectPool.pop();
				r.setTo(x, y, w, h);
				return r;
			}
			return new Rectangle(x, y, w, h);
		}
		
		private function recycleRect(r:Rectangle):void {
			if (r) _rectPool.push(r);
		}
		
		public function insert(bmd:BitmapData, key:String):SubTexture
		{
			var w:int = bmd.width;
			var h:int = bmd.height;
			var neededW:int = w + PADDING;
			var neededH:int = h + PADDING;
			
			// --- 1. 寻找空位 (Best-Fit 算法) ---
			var bestRect:Rectangle = null;
			var bestShortSideFit:int = int.MAX_VALUE;
			var bestRectIndex:int = -1;
			
			for (var i:int = 0; i < _freeRects.length; i++)
			{
				var free:Rectangle = _freeRects[i];
				
				if (free.width >= neededW && free.height >= neededH)
				{
					var leftoverHoriz:int = Math.abs(free.width - neededW);
					var leftoverVert:int = Math.abs(free.height - neededH);
					var shortSideFit:int = Math.min(leftoverHoriz, leftoverVert);
					
					if (shortSideFit < bestShortSideFit)
					{
						bestRect = free;
						bestShortSideFit = shortSideFit;
						bestRectIndex = i;
					}
				}
			}
			
			if (bestRect == null) return null;
			
			// 🚀 [优化 1] 从池中获取锁定区域，而不是 new Rectangle
			var placedRect:Rectangle = getRect(bestRect.x, bestRect.y, neededW, neededH);
			
			// --- 2. 橡皮擦操作 ---
			_eraserHelper.width = placedRect.width;
			_eraserHelper.height = placedRect.height;
			_eraserHelper.x = placedRect.x;
			_eraserHelper.y = placedRect.y;
			_rootTexture.draw(_eraserHelper);
			
			// --- 3. 绘制新图 (🚀 核心优化 2：复用 _drawHelper) ---
			var tempTex:Texture = Texture.fromBitmapData(bmd, false);
			
			// 不再 new Image，而是反复利用全局唯一的 _drawHelper
			if (!_drawHelper) {
				_drawHelper = new Image(tempTex);
			} else {
				_drawHelper.texture = tempTex;
				_drawHelper.readjustSize(); // 纹理换了，必须重置尺寸
			}
			_drawHelper.x = placedRect.x;
			_drawHelper.y = placedRect.y;
			
			_rootTexture.draw(_drawHelper); // 绘制！
			
			// ⚠️ 极其重要：画完后必须解除纹理引用，防止内存泄漏报错
			_drawHelper.texture = null;
			tempTex.dispose(); // 物理销毁临时上传的 GPU 显存
			
			// --- 4. 空间切割 (Guillotine Split) ---
			_freeRects.splice(bestRectIndex, 1);
			performGuillotineSplit(bestRect, placedRect);
			
			_usedRects[key] = placedRect;
			
			// 返回 (注：这个区域交给 Starling 外部使用，为了安全这里保留一个 new 斩断引用)
			var subRegion:Rectangle = new Rectangle(placedRect.x, placedRect.y, w, h);
			return new SubTexture(_rootTexture, subRegion);
		}
		
		public function release(key:String):void
		{
			var rect:Rectangle = _usedRects[key];
			if (rect)
			{
				_freeRects.push(rect);
				delete _usedRects[key];
				// 优化：尝试合并相邻的 freeRects (为了代码稳定性，暂不实现，靠大图集硬抗)
			}
		}
		
		public function get isEmpty():Boolean
		{
			for (var k:String in _usedRects) return false;
			return true;
		}
		
		private function performGuillotineSplit(freeRect:Rectangle, placedRect:Rectangle):void
		{
			var wRemain:int = freeRect.width - placedRect.width;
			var hRemain:int = freeRect.height - placedRect.height;
			
			if (wRemain > hRemain)
			{
				if (wRemain > 0) _freeRects.push(getRect(freeRect.x + placedRect.width, freeRect.y, wRemain, freeRect.height));
				if (hRemain > 0) _freeRects.push(getRect(freeRect.x, freeRect.y + placedRect.height, placedRect.width, hRemain));
			}
			else
			{
				if (hRemain > 0) _freeRects.push(getRect(freeRect.x, freeRect.y + placedRect.height, freeRect.width, hRemain));
				if (wRemain > 0) _freeRects.push(getRect(freeRect.x + placedRect.width, freeRect.y, wRemain, placedRect.height));
			}
			// 🚀 [核心] 切碎后，把用完的母矩形洗净入池
			recycleRect(freeRect);
		}
		
		public function dispose():void
		{
			if (_rootTexture) _rootTexture.dispose();
			if (_eraserHelper) _eraserHelper.dispose();
			
			// 🚀 [核心] 销毁图集时，将内部遗留的所有矩形全部打入冷宫回收
			for each (var r1:Rectangle in _freeRects) recycleRect(r1);
			for each (var r2:Rectangle in _usedRects) recycleRect(r2);
			
			_freeRects = null;
			_usedRects = null;
		}
	}
}