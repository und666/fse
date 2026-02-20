<div align="center">

# FSE (Flash Starling Enhance) 混合渲染框架

**FSE是一个用于Flash AS3的轻量GPU混合渲染框架。旨在使用传统Flash开发方法快速构建能够与Unity体验相近的2D高帧率应用。**

[![GitHub stars](https://img.shields.io/github/stars/und666/FlashStarlingEnhance?style=social)](https://github.com/und666/FlashStarlingEnhance/stargazers)
![visitors](https://visitor-badge.laobi.icu/badge?page_id=FlashStarlingEnhance&left_color=green&right_color=red)


github: https://github.com/und666/FlashStarlingEnhance


</div>

## 特点

- 快速开始,与传统AS3项目对接
- 不同写Starling代码即可轻松创建Starling项目
- 适用于个人级别轻量化富位图的高帧率GPU项目快速开发
- 支持传统Flash的窗口自适应策略
- 支持传统发光，模糊，投影滤镜

## 碎碎念

- 今夕是何年？没错，现在是2026年，距离Flash技术正式退出历史舞台已有五年之久。正是在这样的时间点上，FSE（Flash Starling Enhance）混合渲染框架如一次跨越时空的技术“回响”，悄然诞生。
  
- 我是一名来自中国的热爱独立游戏创作的大三学生，正在逐步向Unity技术栈转型。今年恰是我接触ActionScript 3.0开发的第十年。这些年间，我始终怀有一种愧疚——虽对这一技术有了相当地了解，却未曾用它创作出什么令人瞩目的作品。

- 前段时间，我沉浸于Starling Wiki和GitHub中大量关于Starling框架的资料，同时也陷入了某种瓶颈。我逐渐意识到，在如今的环境中用Flash做出优秀作品实属不易。但作为一个Aser，我仍想为年轻的自己、也为这段技术旅程画上一个更完整的句点。

- 有时候，我们需要寻找一种方式与自己和解，不是吗？这个框架便是我的答案。

- **好吧，用白话说：这个框架只是我本人以学习为目的开发,欢迎学习讨论。**

## 前言
  如果你是一位资深的Flash开发工程师，那么你大概率了解过Adobe AIR SDK的GPU模式\
  我先简单介绍一个这个模式，在AIR for Android/AIR for IOS配置中,GPU设置是可用的\
  选择了这个模式以后确实可以让整个画面看起来更流畅，但帧率依然只能限制在60FPS，以及滤镜等一些功能存在兼容性BUG\
  对于AIR for Desktop，GPU模式竟然直接被隐藏了，据小道消息貌似是Adobe推行了一半但因为很多兼容性BUG所以放弃推行了。\
  并且在传统的Flash IDE的导出设置里是没有这个模式选择的

  -------------------可爱的分界线----------------------\
  \
  那么作为一个Aser，要快速构建高性能高帧率的Flash应用，我们常常会遇到这些问题。\
  **Flash IDEA开发**的传统应用体验不佳{**帧率限制60，帧率不稳定**,**大分辨率场景位图移动直接跳帧**} \
  而转向**Starling 框架** 后，性能虽然上来了，但制作动画却变得异常棘手——**缺乏成熟、可视化的动画解决方案**，这几乎是致命的短板。\
  那有没有一种可能，在制作个人级别的**手机、桌面应用或是游戏**时能够兼顾**GPU的高帧渲染效率**，又能够享受到**Flash IDE现有的动画方案**呢？\
  答案：有的兄弟，有的~ **FSE正式进入舞台(一语双关)**

## 开始指南
**1. 首先，准备好FSE框架**
- 一共包含3个文件
  ```
  fse
  starling
  fse.as
  (注意,这个starling包是经过我调整过的,与官方版本starling不兼容)
  (fse.as这个文件是FSE.as的快捷入口文件)
  ```
\
**2. 将FSE框架复制到你的项目中**
- Flash IDE工程中
  ```
  /your_project_path
  ===========================
  fse
  starling
  fse.as
  ===========================
  xxx.fla
  xxx.swf
  ``` 

- IDEA/FB/FD工程中
  ```
  /your_project_path/src
  ===========================
  fse
  starling
  fse.as
  ===========================
  YourMainClass.as
  ```
\
**3. 在你的项目中注入Starling框架。**
- Flash IDE工程中
  ```haxe
  //在舞台根目录第一帧上
  import fse.core.FSE;
  FSE.init(stage,this);
  //这两行等效于
  fse.init(stage,this);
  
  //请确保你给出的第二个参数为舞台容器剪辑根
  ```

- IDEA/FB/FD工程中
  ```haxe
  //在你的类文件中
  package {
      import flash.display.Sprite;
      import flash.events.Event;
      import fse.core.FSE;

      public class Main extends Sprite {
          
          public function Main() {
             if (stage) {
                 onAddedToStage();
              } else {
                  addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
              }
          }
          private function onAddedToStage(event:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            FSE.init(stage,this);
            //你的代码
          }
      }
  }
  ```

## API
- **特性**
  - FSE接管后所有MovieClip都会默认强制暂停播放
  - 播放由FSE内置的动画管理器驱动
  - 默认情况下，FSE会自动管理所有MovieClip的播放，但你可以通过以下方式来手动控制播放

- **常用API**
  ```haxe
  //=====初始化================================================================

  fse.init(stage,Object(root));
  //常规初始化

  fse.init(stage,Object(root),false);
  //特殊初始化，不进行GPU渲染，只提帧并接管动画系统


  //=====动画控制================================================================

  mc.play();
  //必须改写成
  fse.play(mc);
  //播放动画

  mc.stop();
  //必须改写成
  fse.stop(mc);
  //停止播放动画

  mc.gotoAndStop(index);
  //必须改写成
  fse.gotoAndStop(mc,index);
  //跳转到指定帧

  mc.gotoAndPlay(index);
  //必须改写成
  fse.gotoAndPlay(mc,index);
  //跳转到指定帧并播放

  var v:Boolean = mc.visible;
  //必须改写成
  var v:Boolean = fse.getVisible(mc);
  //获取MovieClip对象可见性
  
  mc.visible=false;
  //必须改写成
  fse.visible(mc,false);
  //改变MovieClip对象可见性
  
  //=====循环控制================================================================
  
  //高频循环 (在240帧的情况下每秒刷新240次)
  
  //开启
  mc.addEventListener(Event.ENTER_FRAME,Update);
  
  //关闭
  mc.removeEventListener(Event.ENTER_FRAME,Update);
  
  
  //低频循环 (无论在什么情况下都以60次每秒运行[频率在Config.as中可调])
  
  //开启
  fse.addEventListener(mc,FSE_Event.FIX_ENTER_FRAME,Update);
  fse.addLoop(mc,Update);
  fse.loop(Update);
  //3句等效
  
  //关闭
  fse.removeEventListener(mc,FSE_Event.FIX_ENTER_FRAME,Update);
  fse.removeLoop(mc,Update);
  fse.stopLoop(Update);
  //3句等效
  ```
- **层级 “三明治” 问题**
  ```
    在 Flash Player / AIR 的运行时架构中：
    顶层 (Top): 原生 Display List (CPU)。
    底层 (Bottom): Stage3D (GPU/Starling)。
    视频层: StageVideo (如果有的话，通常在最最底层)。

    所以FSE框架的实现在此基础上将Stage3D层分成了3层
    每一层级都是一个starling.display.Sprite容器

    在舞台的第1层，也就是最底层，会有一层底层用户操作层，使用fse.starlingRootBack进行访问
    在舞台的第2层，就是最核心的映射层，fse框架会将你的舞台结构映射到此层
    在舞台的第3层，会有一层底层用户操作层，使用fse.starlingRoot进行访问
    在CPU渲染层，也就是最顶层，因为CPU层覆盖在GPU渲染层之上，一些存在兼容性问题的元件可以使用cpu层来进行渲染
  ```

- **高级API**
  ```haxe
  fse.cpu(mc:MovieClip);
  fse.ban(mc:MovieClip); //与上一行等效
  fse.isIgnore(mc:MovieClip):Boolean //获取mc对象的特例状态
  //使用cpu渲染
  /*
	  为了解决某些兼容性问题,
	  被用户标记的剪辑将不会在FSE的Starling舞台上被渲染,而是直接在传统舞台上渲染
	  注意，这么做会导致mc始终显示在GPU层的上方
  */
  


  fse.setKeyRole(mc:MovieClip);
  //将当前的影片剪辑设置为关键角色
  fse.getKeyRole():String
  //获取设置过的关键角色
  /*
	  fse框架允许用户注册一个关键角色剪辑,一旦这个剪辑产生变化Starling马上渲染下一帧
	  这个方法一般应用与哪些与玩家输入操作相关的剪辑,比如鼠标跟随,键盘控制移动等
	  用于实现用户一输入就马上相应的效果
  */
  


  fse.setNodeCached(mc:MovieClip,v:Boolean);
  //设置缓存特例
  /*
	  设置特例后，这个对象的以及当前容器节点的所有肉子节点(Bitmap、Shape)都不参与缓存系统
  */
  



  fse.gpuClear();
  //强制清楚缓存面板上的所有缓存
  



  //=====与Starling混用============================================================
  fse.starlingRoot:starling.display.Sprite
  //为用户提供的Starling舞台根容器顶层(推荐用于添加粒子效果以及特效)

  fse.starlingRootBack:starling.display.Sprite
  //为用户提供的Starling舞台根容器底层(推荐用于添加背景等底层内容元件)

  ```

## Config.as
```
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
		public static const WATCHER_COLD_TIME:uint = 20;
		
		
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
        
		private static var _case_render:Array = [isInputText,isSimpleButton]; //经过这些断言判断为真的话不用starling渲染
		
		//输入文本断言
		private static function isInputText(obj:DisplayObject):Boolean {
			if (obj is TextField) {
				var textField:TextField = obj as TextField;
				// TextFieldType.INPUT 是静态常量，值为 "input"
				return textField.type == TextFieldType.INPUT;
			}
			return false;
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
```
## 注意事项
- 如果你的项目中出现兼容性问题,请按需求添加渲染特例

## 基本原理
- 我们都知道，使用starling的flash项目,传统的cpu渲染会在starling的上层，并且一旦开始GPU渲染,flash项目帧限会从60fps到与刷新率同步例如,在400hz的电脑上可以跑到400fps
  
- 那么我们做一个游戏混合渲染方案
  - 像**简单静态的内容**，比如高清背景图片等，或者简单移动的场景图片，我打算使用**starling进行渲染**。
  - 如果**复杂的动态内容**，比如动画中右嵌套的动画，比如枪械开火动画绑定在人物手部动画上，那我们将使用传统的Flash cpu的方式渲染，但我们会将cpu渲染层所有的传统剪辑强制隐藏(visible=false)，只有当flash.display.movieclip更新（其中某个影片剪辑或者子剪辑的帧发生变化）后则更新draw出位图数据作为显示纹理，再由starling进行渲染。
  
- 那么到了这里肯定会有小朋友要问了
  - “Starling框架不使用图集并高频率上传纹理不会导致性能爆炸吗？”
  - “怎么说好呢，我们这个框架本来就不是用来开发专业应用的，对于个人级别的项目，如果您的游戏中能保证动态更新部分较少，并且能控制纹理大小（控制在几百像素以内），那么我认为不会影响性能
  况且，我制作的框架具有一些性能优化算法，能解决一部分你的疑虑”
   
- 这么说来的话，我实际做的也就是这几件事情
  -  **逻辑驱动控制**
     -  比如一些预期的动画只能由60fps播放
     -  一些逻辑代码只能以60fps执行
     -  使用框架后的一切逻辑和动画都要由新的60帧逻辑驱动
     -  不能因为主观设备（屏幕刷新率）的不同导致程序运行效果/动画效果有出入
  
  - **舞台监控**
     -  对Flash传统Stage生成实时管理的场景结构树
     -  场景树上的每一个节点对应着一个flash.display.DisplayObject对象，并存储他们的所有状态(例如currentFrame,visible,alpha,x,y,scaleX,scaleY,rotation等)，最关键的，**锚点信息**
     -  对场景树进行遍历检查，并比对每个子剪辑是否发生变化，**变化分为两种**
        -  **1. 形变（影片剪辑的帧数，子剪辑集合改变，内容改变等）**
        -  **2. 属性值改变（transfer属性改变，同步数值即可）**

  - **Starling渲染**
    - 对于flash传统stage生成实时管理的场景树，Starling舞台要实时同步场景树上影片剪辑发生的变化，同步到Starling舞台上
    - 在同一父剪辑内的所有starling.display.DisplayObject对象的图层顺序可以按照传统剪辑同步过来的childrenIndex值按照大小进行显示图层排序

  - **纹理缓存管理**
    - 为了减少DrawCalls，本框架使用MaxRects算法进行二维空间uv装箱
    - 对场景里的每帧/每个DisplayObject对象，都生成纹理相应的唯一哈希字符串

  - **输入事件转发**
    - 由于CPU层的所有内容被隐藏,这意味着注册在他们身上的鼠标点击事件都将失效
    - 我设计的输入转发器可以转发鼠标输入事件到对应的flash.display.DisplayObject身上

## 框架
- 包类结构为
- **fse**
  - **core包**
    - **FSE** (核心静态类，接口封装)
    - **FSE_Kernel** (核心静态类的真身)
    - **FSE_Manager** (脏活累活都他干，此类需要实例化，使用单例模式)
    - **FSE_Input** (输入事件转发器)
  - **display包**
    - **Watcher** (场景树监控)
    - **Node** (存储单个影片剪辑详细信息，并包含Node子集)
    - **Scanner** (用于扫描传统舞台上的场景树)
    - **Controller** (动画剪辑逻辑控制器)
    - **StatusSaver** (状态保存器)
  - **events包**
    - **FSE_Event** (这个其实作用不大，就是写一些事件常量,比如FIX_ENTER_FRAME)
  - **conf包**
    - **Config** (配置类)
  - **starling包**
    - **StarlingMain** (初始化Starling舞台)
    - **StarlingVO** (Starling影片剪辑根)
    - **StarlingManager** (负责同步并管理)
  - **cache包**
    - **AtlasPage** (图集分页管理器)
    - **CacheManager** (纹理缓存管理器)
    - **Cache** (纹理缓存实体类)
  - **utils包**
    - **Hash** (BitmapData快速哈希)
    - **MD5** (散列加密)


## 联系作者
- 作者: undefined (一位有理想的独立游戏制作人)
- 微信: hbx098hbx123 (欢迎交朋友)
- 邮箱: 2199182141@qq.com
- 你可以添加作者微信，反馈BUG或者建议

---
> 祝大家2026年马到成功，**代码会老，但创造的心永远年轻。**\
> 如果这个框架，能让你在未来的某天，更轻盈、更自由地做出心中所想，那便是它全部的意义。\
> 感谢 AS3，感谢仍在这里的你。\
> **2026.1.29**\
> 于一个即将春暖花开的日子前

