package fse.display
{
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.filters.*;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.utils.getQualifiedClassName;

import fse.conf.*;
import fse.core.FSE;
import fse.core.FSE_Manager;
import fse.utils.Hash;
import fse.utils.MD5;

/**
	 * 场景树节点 (Shadow Node) - 简化版
	 * 策略：
	 * 1. 容器节点 (MovieClip/Sprite): 仅负责结构和属性同步，不生成 BitmapData。
	 * 2. 叶子节点 (Shape/Bitmap): 负责生成 BitmapData，是实际的渲染内容。
	 */
	public class Node
	{
		public var source:DisplayObject;
		public var children:Vector.<Node>;
		
		// 只有叶子节点(Shape)会有这个数据，容器节点为null
		public var bitmapData:BitmapData;
		public var pivotX:Number = 0;
		public var pivotY:Number = 0;
		
		// ------ 上一帧的状态缓存 ------
		private var _lastX:Number;
		private var _lastY:Number;
		private var _lastScaleX:Number;
		private var _lastScaleY:Number;
		private var _lastWidth:Number;
		private var _lastHeight:Number;
		private var _lastRotation:Number;
		private var _lastAlpha:Number;
		private var _lastFrame:int = -1;
		// [新增] 当前的层级索引 (Visual Index)
		public var childIndex:int = -1;
		private var _lastChildIndex:int = -1; // 用于比对
		// [新增] 记录文本内容
		private var _lastText:String = null;
		// [新增] 记录可见性
		private var _lastVisible:Boolean;
		
		//位图哈希
		private var hash:String;
		
		private var nodeEnabled:Boolean = true;
		
		//回调
		private var _onDisposeArgs:Function;
		public var onDisposeRenderer:Function;
		
		
		// 定义操作类型常量
        public static const UPDATE_PROP:String = "prop";   // 属性变化(x,y,alpha...)
        public static const UPDATE_TEXTURE:String = "texture"; // 纹理内容变化(重绘)
        public static const UPDATE_HIERARCHY:String = "hierarchy"; // 层级/父子关系变化
		public static const UPDATE_FILTER:String = "filter"; //滤镜更新常量
		private var _lastFilterSig:String = ""; // 上一次的滤镜签名
		
		// [新增] 持有 Starling 层的对应显示对象
        // 使用 Object 类型以避免在 fse.display 包中引入 starling 包造成强耦合
        public var renderer:Object;
		
        // [新增] 钩子函数：当 Node 初始化完成需要创建视图时调用
        public static var onCreateRenderer:Function;
		
		// [新增] 渲染层回调，由 StarlingManager 注入
        // 签名: function(node:Node, type:String):void
        public var onUpdate:Function;
		
		public var parentNode:Node;
		
		public var _coldTime:int=0;
		public var _coldTimeMax:int=0;
		
		// [新增] 缓存开关：默认为 true (参与 Hash 缓存)
        // 如果设为 false，则每次都会生成全新的 Texture，且不通过 CacheManager 管理
        public var enableCache:Boolean = true;
		
		public function Node(src:DisplayObject, parentNode:Node , disposeCallback:Function , enableCache:Boolean = true)
		{
			
			this.parentNode = parentNode;
			this.source = src;
			this.children = new Vector.<Node>();
			this._onDisposeArgs = disposeCallback;
			this.enableCache=enableCache;
			
			if(src){
				if(!StatusSaver.hasVisible(src)){
					//初始逻辑可见性配置
					//setLogicalVisible(src.visible);
					setLogicalVisible(true);
					setOriginVisible(src.visible);
				}
				
				if(src.parent){
					//初始层级索引配置
					childIndex=src.parent.getChildIndex(src);
					_lastChildIndex=childIndex;
					//if(!(src is DisplayObjectContainer) && FSE.isIgnore(parentNode.source)){
				}
			}
			
			// 1. 记录初始状态
			recordState();
			
			// 2. 尝试生成快照 (只有 Shape 等叶子节点才会真正生成)
			updateSnapshot();
			
			if(FSE_Manager.watcher.isIgnore(src)){
				nodeEnabled=false;
				//死节点
				return;
			}
			
			if (onCreateRenderer != null) {
				// 将自己传出去，工厂创建完 Starling 对象后赋值给 this.renderer
				onCreateRenderer(this);
			}
		}
		public function enable():Boolean{
			return nodeEnabled;
		}
		
		
		/**
		 * [新增] 设置逻辑可见性 (由 Watcher 调用)
		 * 这使得 Node 知道 Controller 希望它显示还是隐藏
		 */
		
		public function restoreVisible():void{
			if(source){
				source.visible = getOriginVisible();
				trace(source.name)
			}
			for(var i:uint=0;i<children.length;i++){
				children[i].restoreVisible();
			}
		}
		
		public function setLogicalVisible(v:Boolean):void
		{
			if(source)StatusSaver.setLogicalVisible(source,v);
		}
	
		public function getLogicalVisible():Boolean
		{
			if(source)return StatusSaver.getLogicalVisible(source);
			trace("获取visible错误");
			return true;
		}
		public function setOriginVisible(v:Boolean):void
		{
			if(source)StatusSaver.setOriginVisible(source,v);
		}
	
		public function getOriginVisible():Boolean
		{
			if(source){
				return StatusSaver.getOriginVisible(source);
			}
			trace("获取OriginVisible错误");
			return true;
		}
		/**
		 * [简化版] 生成纹理快照
		 * 规则：容器不画，只有叶子节点画
		 */
		public function updateSnapshot():void
		{
			if(!source)return;
			
			// 先清理旧纹理
			if (this.bitmapData) {
				this.bitmapData.dispose();
				this.bitmapData = null;
			}
		
			// [新规则] 如果是容器 (MovieClip, Sprite)，直接跳过
			// 它的"肉"存在于它的子 Shape 节点中，不由它自己负责渲染
			if(source is DisplayObjectContainer)return;
			if(FSE_Manager.watcher.isIgnore(source)){
				return;
			}
			
			// --- 下面只针对 Shape / Bitmap 等非容器对象 ---
		
			// [新增] 现场保护：记录原始可见性
			// 无论 Flash 里这个对象是否隐藏，我们为了截图必须临时让它"可见"
			// 这样能保证 getBounds 和 draw 100% 正常工作
			
			// 强制开启显示 (有些特殊情况 alpha=0 也画不出来，视需求而定，这里只处理 visible)
		
			//var vis_temp:Boolean = source.visible;
			//source.visible = true;
			
			var bounds:Rectangle = source.getBounds(source);
			// 检查是否有内容
			if (!FSE.noGPU && !FSE.isIgnore(source) && bounds.width >= 1 && bounds.height >= 1)
			{
				try {
					var w:int = Math.ceil(bounds.width);
					var h:int = Math.ceil(bounds.height);
					
					var bmd:BitmapData = new BitmapData(w, h, true, 0x00000000);
					var mat:Matrix = new Matrix();
					mat.translate(-bounds.x, -bounds.y);
					
					bmd.draw(source, mat);
					
					this.pivotX = -bounds.x;
					this.pivotY = -bounds.y;
					
					var now_hash:String = MD5.getMD5(Hash.getHash(bmd));
					
				
					if(hash != now_hash){
						hash = now_hash;
						//真正意义上的位图更新
						this.bitmapData = bmd;
						if(Config.TRACE_NODE)trace("[Node] 生成Shape纹理: " + getName());
						if(onUpdate != null)onUpdate(this,UPDATE_TEXTURE);
					}
				}
				catch (e:Error) {
					if(Config.TRACE_NODE)trace("[Error] 纹理生成失败: " + getName());
				}
			}
			//source.visible = vis_temp;
		}

		/**
		 * 检查属性是否发生变化
		 */
		public function checkDiff():Boolean
		{
			
			if(!source)return false;
			if(FSE_Manager.watcher.isIgnore(source)){
				return false;
			}
			var isChanged:Boolean = false;
			var changes:Array = [];
			// --- 1. 基础变换属性 ---
			if (source.x != _lastX) { changes.push("x"); isChanged = true; }
			if (source.y != _lastY) { changes.push("y"); isChanged = true; }
			if (source.scaleX != _lastScaleX) { changes.push("scaleX"); isChanged = true; }
			if (source.scaleY != _lastScaleY) { changes.push("scaleY"); isChanged = true; }
			if (source.width != _lastWidth) { changes.push("width"); isChanged = true; }
			if (source.height != _lastHeight) { changes.push("height"); isChanged = true; }
			if (source.rotation != _lastRotation) { changes.push("rotation"); isChanged = true; }
			if (source.alpha != _lastAlpha) { changes.push("alpha"); isChanged = true; }
			
			// --- [新增] 滤镜变化检查 ---
			// 只有当对象是非容器(Shape/Bitmap) 或者 容器确实有滤镜时才检查
			// 为了性能，如果 source.filters 为空且 _lastFilterSig 为空，则快速跳过
			
			var currentFilters:Array = source.filters;
			if (currentFilters.length > 0 || _lastFilterSig != "")
			{
				var currentSig:String = getFilterSignature(currentFilters);
				if (currentSig != _lastFilterSig)
				{
					changes.push("filters"); // 压入变更队列
					isChanged = true;
					// 注意：这里先不更新 _lastFilterSig，而在 recordState 中统一更新
				}
			}
			
			// [新增] 可见性同步
			// ⚠️ 警告：如果 Controller 强制隐藏了 Flash 对象，这里会检测到 visible=false
			// 导致 Starling 对象也隐藏。
			if (getLogicalVisible() != _lastVisible)
			{
				changes.push("visible");
				isChanged = true;
			}
			
			
			// --- [新增] 层级变化检查 ---
			// childIndex 的数值由 Watcher 在遍历时赋值，这里只负责检测变化
			if(source.parent)childIndex=source.parent.getChildIndex(source);
			if(_lastChildIndex==-1){
				_lastChildIndex=childIndex;
			}
			if (childIndex != _lastChildIndex)
			{
				changes.push("childIndex");
				isChanged = true;
				if(Config.TRACE_NODE)trace("[Node] 层级调整: " + getName() + " " + _lastChildIndex + " -> " + childIndex);
			}
			
			
			// --- 2. 容器帧变化处理 ---
			//更新 这里我们不扫描帧变化
			
			if (source is MovieClip)
			{
				var mc:MovieClip = source as MovieClip;
				if (mc.currentFrame != _lastFrame)
				{
					//我认为帧变化时不需要isChanged同步的，因为帧变化了只需要同步Shape的内容
					//changes.push("frame:" + mc.currentFrame);
					//isChanged = true;
					// [核心逻辑] 帧变了 -> Flash 会销毁旧 Shape 创建新 Shape
					// 我们必须主动移除当前 Node 下的所有 Shape 子节点
					// Watcher 下一轮扫描时会发现新的 Shape 并为它们创建新 Node (执行 updateSnapshot)
					
					//removeShapeChildren();
					updateFrame();
					// 注意：这里不再调用 updateSnapshot()，因为 MC 自己不产生纹理
				}
			}
			
		
			// --- 3. [新增] 文本内容变化处理 (针对 TextField) ---
			// 只有当对象确实是 TextField 时才检查
			if (source is TextField)
			{
				var tf:TextField = source as TextField;
				// 比较当前文本和记录的文本
				if (tf.text != _lastText)
				{
					changes.push("text");
					isChanged = true;
					
					// 文本变了，必须重新截图！
					// 因为 TextField 实例没变，Watcher 不会把它当新对象，
					// 所以我们必须手动触发 updateSnapshot
					if(Config.TRACE_NODE)trace("[Node] 文本变化重绘: " + tf.text);
					updateSnapshot();
				}
			}
			
			if (isChanged)
			{
				_coldTimeMax=0;
				while(changes.length){
					onUpdateMovieClip(this,changes.pop());
				}
				
				recordState();
			}

			return isChanged;
		}
		
		private function onUpdateMovieClip(node:Node,type:String){
			//if(Config.TRACE_NODE)trace("[Node] 属性修改:"+node.getName(),'    '+type);
			if(type=="rotation" || type=="x" || type=="y" || type=="scaleX" || type=="scaleY" || type=="alpha" || type=="visible"){
				if(onUpdate != null)onUpdate(this, UPDATE_PROP);
			}
			if(type=="childIndex"){
				if(onUpdate != null)onUpdate(this, UPDATE_HIERARCHY);
			}
			// [新增] 响应滤镜变化
			if (type == "filters") {
				if (onUpdate != null) onUpdate(this, UPDATE_FILTER);
			}
		}
		
		//###############
		public function updateFrame():void
		{
			var mc:MovieClip = source as MovieClip;
			if (mc && mc.currentFrame != _lastFrame)
			{
				updateShapeChildren();
				_lastFrame = mc.currentFrame;
			}
		}
		
		private function updateShapeChildren():void
		{
			for (var i:int = children.length - 1; i >= 0; i--)
			{
				var childNode:Node = children[i];
				if (!(childNode.source is DisplayObjectContainer))
				{
					childNode.checkDiff();
					childNode.updateSnapshot();
				}
			}
		}
		
		/**
		 * 移除所有的 Shape/叶子 类型子节点
		 */
		private function removeShapeChildren():void
		{
			for (var i:int = children.length - 1; i >= 0; i--)
			{
				var childNode:Node = children[i];
				
				// 如果子节点不是容器（即它是 Shape/Bitmap 等内容节点）
				if (!(childNode.source is DisplayObjectContainer))
				{
					// trace("[Node] 帧清理: 移除旧 Shape 节点");
					childNode.dispose();
					children.splice(i, 1);
				}
			}
		}
	
		private function recordState():void
		{
			if(source){
				_lastX = source.x;
				_lastY = source.y;
				
				//if(source is DisplayObjectContainer){
					_lastScaleX = source.scaleX;
					_lastScaleY = source.scaleY;
				//}else{
					_lastWidth = source.width;
					_lastHeight = source.height;
				//}
				_lastRotation = source.rotation;
				_lastAlpha = source.alpha;
				// [新增] 记录滤镜签名
				_lastFilterSig = getFilterSignature(source.filters);
			}
			_lastVisible = getLogicalVisible();
			// [新增] 记录层级
			_lastChildIndex = childIndex;
			
			/*
			if (source is MovieClip)
			{
				_lastFrame = (source as MovieClip).currentFrame;
			}
			*/
		
			// [新增] 记录文本状态
			if (source is TextField)
			{
				_lastText = (source as TextField).text;
			}
		
			//if(Config.TRACE_NODE)trace("[Node] -> 对象: " + source.name, ' 属性刷新 ');
		}
		
		
		/**
		 * [新增] 生成滤镜签名字符串
		 * 格式示例: "Glow_0xFF0000_1_10_10|Blur_5_5|"
		 */
		private function getFilterSignature(filters:Array):String
		{
			if (!filters || filters.length == 0) return "";
			
			var sig:String = "";
			var len:int = filters.length;
			
			for (var i:int = 0; i < len; i++) {
				var f:* = filters[i];
				// 仅针对支持的滤镜生成详细签名，其他滤镜只记录类名
				if (f is GlowFilter) {
					sig += "Glow_" + f.color + "_" + f.alpha + "_" + f.blurX + "_" + f.blurY + "_" + f.strength + "_" + f.quality + "_" + f.inner + "_" + f.knockout + "|";
				} else if (f is BlurFilter) {
					sig += "Blur_" + f.blurX + "_" + f.blurY + "_" + f.quality + "|";
				} else if (f is DropShadowFilter) {
					sig += "Drop_" + f.distance + "_" + f.angle + "_" + f.color + "_" + f.alpha + "_" + f.blurX + "_" + f.blurY + "_" + f.strength + "_" + f.inner + "_" + f.knockout + "|";
				} else {
					// 对于不支持的复杂滤镜，直接记录类名。
					// 这样如果用户把复杂滤镜移除了，我们能检测到变化并清空。
					sig += "Other_" + getQualifiedClassName(f) + "|";
				}
			}
			return sig;
		}
		
		public function getName():String
		{
			return source.name;
		}
		
		public function dispose():void
		{
			if (_onDisposeArgs != null && source != null)
			{
				_onDisposeArgs(source);
				_onDisposeArgs = null;
			}
			// [新增] 核心修改：利用递归顺便销毁 Starling 对象
            if (renderer)
            {
				if (onDisposeRenderer != null)
				{
					onDisposeRenderer(this);
				}
			
                if (renderer.hasOwnProperty("dispose"))
                {
					renderer["removeFromParent"](false); // 从 Starling 舞台移除并 dispose
					// 或者直接 renderer["dispose"](); 视你的 Starling 版本而定
                }
                renderer = null;
            }
			if (children)
			{
				for (var j:int = children.length - 1; j >= 0; j--)
				{
					children[j].dispose();
				}
				children = null;
			}
			
			if (bitmapData){
				bitmapData.dispose();
				bitmapData = null;
			}
			source = null;
			onUpdate = null;
		}
	}
}