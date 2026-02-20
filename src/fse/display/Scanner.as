package fse.display
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.utils.getQualifiedClassName;
import flash.text.TextField;

import fse.core.FSE;
import fse.conf.*;
import fse.core.FSE_Manager;

/**
 * 场景扫描器 (从 Watcher 解耦)
 * 负责遍历显示列表，检测节点增删
 */
public class Scanner
{
	private var _watcher:Watcher;
	
	public function Scanner()
	{
	
	}
	
	public function setWatcher(watcher:Watcher):void
	{
		_watcher=watcher;
	}
	public function scan(targetRoot:DisplayObjectContainer):void
	{
		if (!_watcher.rootNode)
		{
			if(Config.TRACE_WATCHER) trace("[FSE Watcher] 初始化根节点: " + targetRoot.name);
			// 调用 Watcher 的 internal 方法创建根节点
			_watcher.rootNode = _watcher.createNode(targetRoot, null);
		}
		scanContainer(targetRoot, _watcher.rootNode);
	}
	
	public function scanContainer(container:DisplayObjectContainer, parentNode:Node,cold:Boolean = true):void
	{
		//!!!实验性内容 如果当前节点为肉则直接跳过(为了性能优化)
		//##将在这里进行扫描的CPU压力减弱优化
		if(!parentNode || !container || !parentNode.source) return;
		
		parentNode._coldTime++;
		if(container.name == FSE.keyRole || !cold) parentNode._coldTimeMax = 0;
		
		// 1. 检查当前容器自身的属性 (x, y, frame...)
		if(parentNode._coldTime > parentNode._coldTimeMax){
			parentNode.checkDiff();
		}
		
		// 2. 遍历子对象 (可能是 子MC，也可能是 Shape)
		//var currentFlashChildren:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		var num:int = container.numChildren;
		
		for (var i:int = 0; i < num; i++)
		{
			var child:DisplayObject = container.getChildAt(i);
			//currentFlashChildren.push(child);
			
			// 访问 Watcher 的 nodeMap
			var childNode:Node = _watcher.nodeMap[child];
			
			if(parentNode._coldTime > parentNode._coldTimeMax){
				
				// [Add] 新增节点逻辑
				if (!childNode)
				{
					if(Config.TRACE_WATCHER) trace(' ');
					if(Config.TRACE_WATCHER) trace(' ');
					if(Config.TRACE_WATCHER) trace("[FSE Watcher] ➕ 新对象: " + child.name + " [" + getQualifiedClassName(child) + "]" +" in "+parentNode.getName());
					
					// 创建Node (调用 Watcher 的方法)
					childNode = _watcher.createNode(child, parentNode);
					parentNode.children.push(childNode);
					
					// 对于MovieClip进行动画控制类操作
					if(child is MovieClip && _watcher.controller){
						_watcher.controller.register(child as MovieClip);
						if(StatusSaver.isPlaying(child)){
							_watcher.controller.play(child as MovieClip);
						}
					}
					
					
					// ban相关,继承父类的ban配置
					if(child is DisplayObjectContainer){
						// ...
					}else{
						// 可见性控制
						hide(child);
						
						// ban相关 如果是非容器剪辑 则对比Config表中的特例表来添加特例
						if(!StatusSaver.noIgnoreCache[child]) {
							var cr:Array = Config.case_render;
							for (var i_case:uint = 0; i_case < cr.length; i_case++) {
								if (cr[i_case](child)) {
									_watcher.addIgnore(child);
									StatusSaver.noIgnoreCache[child]=true;
									break;
								}
							}
						}
					}
					if(_watcher.isIgnore(container)){
						_watcher.addIgnore(child);
						return;
					}
				}
			}
			
			// [Recursion] 递归
			if (child is DisplayObjectContainer)
			{
				scanContainer(child as DisplayObjectContainer, childNode);
			}
			else
			{
				// 叶子节点 (肉)
				if(childNode && childNode.source && childNode.source is TextField){
					childNode._coldTime++;
					if(childNode._coldTime > childNode._coldTimeMax){
						childNode.checkDiff();
						if(childNode._coldTimeMax < Config.WATCHER_COLD_TIME){
							childNode._coldTimeMax++;
						}
						childNode._coldTime = int(Math.random() * childNode._coldTimeMax);
					}
				}
			}
		}
		
		if(parentNode._coldTime > parentNode._coldTimeMax){
			// [Remove] 检查是否有子节点在 Flash 显示列表中消失了
			for (var j:int = parentNode.children.length - 1; j >= 0; j--)
			{
				var existingNode:Node = parentNode.children[j];
				if (!existingNode.source || existingNode.source.parent != container)
				{
					if(Config.TRACE_WATCHER) trace("[FSE Watcher] ➖ 移除对象: " + existingNode.getName());
					
					if (_watcher.controller && existingNode.source is MovieClip)
					{
						_watcher.controller.unregister(existingNode.source as MovieClip);
					}
					
					existingNode.dispose();
					_watcher.deleteNodeFromMap(existingNode.source);
					parentNode.children.splice(j, 1);
				}
			}
			
			// 重置冷却时间
			if(parentNode._coldTimeMax < Config.WATCHER_COLD_TIME){
				parentNode._coldTimeMax++;
			}
			parentNode._coldTime = int(Math.random() * parentNode._coldTimeMax);
		}
	}
	
	
	private function hideAll(target:DisplayObject):void {
		function traverse(container:DisplayObjectContainer):void {
			if(!container || FSE.isIgnore(container)){
				return;
			}
			
			for (var i:int = 0; i < container.numChildren; i++) {
				var child:DisplayObject = container.getChildAt(i);
				
				if (child is DisplayObjectContainer) {
					traverse(child as DisplayObjectContainer);
				} else {
					hide(child);
				}
			}
		}
		if (target is DisplayObjectContainer) {
			traverse(target as DisplayObjectContainer);
		}else{
			hide(target);
		}
	}
	
	private function hide(target:DisplayObject):void
	{
		if (!FSE_Manager.noGPU && !FSE.isIgnore(target))
		{
			target.visible = false;
		}
	}
}
}