package fse.conf
{
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	
	import starling.textures.TextureSmoothing;
	
    /**
     * FSE 全局配置类
     * 用于统一管理逻辑帧率、渲染精度等静态参数
     */
    public class Config
    {
		
		// -------------------------------------------------
		// 舞台显示相关(Stage Display)
		// -------------------------------------------------
		public static const DEVICE_W:uint = Capabilities.screenResolutionX; //设备窗口大小
		public static const DEVICE_H:uint = Capabilities.screenResolutionY;
		
		public static const FULL_SCREEN:Boolean = false;
		public static var AUTO_ADAPT:String = "AUTO"; //舞台自适应方案
		// ***可选项
		//"FULL" 填满视窗适配，无论如何填满视窗（不保证舞台比例）
		//"SYN_HEIGHT" 舞台画面紧贴屏幕上下两边，并保证舞台比例
		//"SYN_WIDTH"舞台画面紧贴屏幕左右两边，并保证舞台比例
		// "AUTO" 缩放边界自动决定，始终保持舞台比例
		// "NONE" 框架不干预适配行为，但依然会控制渲染窗口和舞台高宽同步（我也不知道这个选项有什么用）
		
		
		//舞台对齐，除非有特殊开发需要不然一般不修改此项设置
		//特殊说明，如果舞台自适应方案与此项冲突，则此项设置无效（比如你的舞台始终紧贴左右两边，那你又设置了左对齐，那就失去意义了）
		public static var ALIGN_X:String = "CENTER";
		// ***可选项
		//"CENTER" 锚定屏幕中央位置，这是最推荐的设置
		//"LEFT" 紧贴屏幕左侧
		//"RIGHT" 紧贴屏幕右侧
		
		
		public static var ALIGN_Y:String = "CENTER";
		// ***可选项
		//"CENTER" 锚定屏幕中央位置，这是最推荐的设置
		//"TOP" 紧贴屏幕上侧
		//"BOTTOM" 紧贴屏幕下侧
		
		
		public static const BG_COLOR:uint=0x211F20; //背景颜色
	
		public static const EXT_FPS:uint=400; //Starling 最高帧限(通常设置为超过大多数屏幕刷新率)
		
		
		
		// -------------------------------------------------
		// 画面配置相关(Quality)
		// -------------------------------------------------
		public static var TEXTURE_SMOOTHING:String = TextureSmoothing.BILINEAR; //纹理平滑设置
		// ***可选项
		//TextureSmoothing.NONE (不平滑/最近邻插值) ###如果你的游戏的像素风格游戏推荐使用这个选项
		//TextureSmoothing.BILINEAR (双线性过滤 - 默认值)
		//TextureSmoothing.TRILINEAR (三线性过滤)
		
		
		
		// -------------------------------------------------
		// 缓存策略相关(Cache)
		// -------------------------------------------------
		public static const CACHE_THRESHOLD:uint = 3; //持久化阈值：如果场景同时出现超过这个数的同样纹理，那么这个纹理将被持久化存入缓存
		public static const WATCHER_COLD_TIME:uint = 15;
		
		
		// -------------------------------------------------
		// 调试相关(Debug)
		// -------------------------------------------------
		public static const TRACE_CORE:Boolean = false; //无关紧要的一些启动信息
		public static const TRACE_DEBUG:Boolean = true; //Starling GPU性能信息
		public static const TRACE_WATCHER:Boolean = false; //节点数监控调试信息
		public static const TRACE_NODE:Boolean = false; //单个节点行为调试信息
		public static const TRACE_CACHE:Boolean = false; //缓存器信息
		
        // ------------------------------------------------
        // 游戏配置 (Game)
        // ------------------------------------------------
		public static const STOP_ALL:Boolean = true; //在接管后默认暂停所有影片剪辑
		
        private static var _logicFrameRate:int = 60; //逻辑帧率
        private static var _logicTimestep:Number = 1000.0 / _logicFrameRate;
        
		private static var _case_render:Array = [isText,isSimpleButton]; //经过这些断言判断为真的话不用starling渲染
		
		
		//输入文本断言
		private static function isInputText(obj:DisplayObject):Boolean {
			if (obj is TextField) {
				var textField:TextField = obj as TextField;
				// TextFieldType.INPUT 是静态常量，值为 "input"
				return textField.type == TextFieldType.INPUT;
			}
			return false;
		}
		
		//文本断言
		private static function isText(obj:DisplayObject):Boolean {
			return obj is TextField;
		}
		//按钮断言
		private static function isSimpleButton(obj:*):Boolean{
			// 检查是否为flash.display.SimpleButton实例
			return obj is SimpleButton;
		}
        // ------------------------------------------------
        // 公共参数
        // ------------------------------------------------
        
        /**
         * 最大的追赶时间 (毫秒)
         * 如果设备极度卡顿，每一帧最多只处理这么长时间的逻辑，防止死循环
         * 默认 200ms (即最差情况每帧追赶约 12 个逻辑帧)
         */
        public static var maxAccumulator:Number = 200;

        /**
         * 纹理缩放系数 (未来用于支持 Retina/高清屏)
         * 1 = 原倍, 2 = 2倍高清
         */
        public static var contentScaleFactor:Number = 1.0;

        // ------------------------------------------------
        // Getter / Setter
        // ------------------------------------------------
		
		public static function get case_render():Array{
			return _case_render;
		}
        /**
         * 目标逻辑帧率 (默认为 60)
         * 修改此值会自动更新 timestep
         */
        public static function get logicFrameRate():int
        {
            return _logicFrameRate;
        }

        public static function set logicFrameRate(value:int):void
        {
            if (value < 1) value = 1; // 安全限制
            if (_logicFrameRate == value) return;

            _logicFrameRate = value;
            _logicTimestep = 1000.0 / _logicFrameRate;
            
            trace("[FSE_Config] Logic FPS set to: " + _logicFrameRate + " (Timestep: " + _logicTimestep.toFixed(2) + "ms)");
        }

        /**
         * [只读] 每一逻辑帧的时间步长 (毫秒)
         * 例如 60fps = 16.666ms
         */
        public static function get logicTimestep():Number
        {
            return _logicTimestep;
        }
    }
}