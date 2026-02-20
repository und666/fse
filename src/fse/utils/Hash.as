package fse.utils
{
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.geom.Matrix;
    import flash.geom.Point;
    
    public class Hash
    {
        public function Hash()
        {
        }
        
        
        
        
        
        /**
         * 极速位图哈希 (使用 FNV-1a 算法替代 MD5)
         */
        public static function getFastHash(bmd:BitmapData):String
        {
            if (!bmd) return "null";
            var width:int = bmd.width;
            var height:int = bmd.height;
            
            if (width <= 0 || height <= 0) return "empty";
            
            // FNV-1a 32-bit 初始化常数
            var hash:uint = 2166136261;
            hash ^= width;
            hash *= 16777619;
            hash ^= height;
            hash *= 16777619;
            
            var centerX:Number = width / 2;
            var centerY:Number = height / 2;
            var diag1StepX:Number = (width - 1) / 9;
            var diag1StepY:Number = (height - 1) / 9;
            var diag2StartX:Number = width - 1;
            var diag2StepX:Number = -(diag2StartX / 9);
            var diag2StepY:Number = (height - 1) / 9;
            
            // 纯数学遍历，零字符串拼接
            for (var i:int = 0; i < 10; i++)
            {
                var p1:int = Math.round((height / 9) * i);
                var p2:int = Math.round((width / 9) * i);
                var dx1:int = Math.round(diag1StepX * i);
                var dy1:int = Math.round(diag1StepY * i);
                var dx2:int = Math.round(diag2StartX + diag2StepX * i);
                var dy2:int = Math.round(diag2StepY * i);
                
                // 1. 垂直线
                hash ^= (p1 >= 0 && p1 < height) ? bmd.getPixel(centerX, p1) : 0;
                hash *= 16777619;
                // 2. 水平线
                hash ^= (p2 >= 0 && p2 < width) ? bmd.getPixel(p2, centerY) : 0;
                hash *= 16777619;
                // 3. 主对角
                hash ^= (dx1 >= 0 && dx1 < width && dy1 >= 0 && dy1 < height) ? bmd.getPixel(dx1, dy1) : 0;
                hash *= 16777619;
                // 4. 副对角
                hash ^= (dx2 >= 0 && dx2 < width && dy2 >= 0 && dy2 < height) ? bmd.getPixel(dx2, dy2) : 0;
                hash *= 16777619;
            }
            
            // 最终只输出一次短小精悍的 16 进制字符串作为 Key
            return hash.toString(16);
        }
        
        /**
         * 获取位图的哈希值
         * @param bmd 位图数据
         * @return 哈希字符串
         */
        public static function getHash(bmd:BitmapData):String
        {
            if (!bmd) return "";
            
            var width:int = bmd.width;
            var height:int = bmd.height;
            
            if (width <= 0 || height <= 0) return "";
            
            // 存储40个像素点的颜色值
            var pixelValues:Array = [];
            
            // 1. 垂直平分线 (x = width/2)
            var centerX:Number = width / 2;
            for (var i:int = 0; i < 10; i++)
            {
                var y1:Number = (height / 9) * i;
                var pixelY1:int = Math.round(y1);
                if (pixelY1 >= 0 && pixelY1 < height)
                {
                    pixelValues.push(bmd.getPixel(centerX, pixelY1));
                }
                else
                {
                    pixelValues.push(0);
                }
            }
            
            // 2. 水平平分线 (y = height/2)
            var centerY:Number = height / 2;
            for (i = 0; i < 10; i++)
            {
                var x1:Number = (width / 9) * i;
                var pixelX1:int = Math.round(x1);
                if (pixelX1 >= 0 && pixelX1 < width)
                {
                    pixelValues.push(bmd.getPixel(pixelX1, centerY));
                }
                else
                {
                    pixelValues.push(0);
                }
            }
            
            // 3. 主对角线 (从左上到右下)
            var diag1StepX:Number = (width - 1) / 9;
            var diag1StepY:Number = (height - 1) / 9;
            
            for (i = 0; i < 10; i++)
            {
                var diagX1:Number = diag1StepX * i;
                var diagY1:Number = diag1StepY * i;
                var pixelDiagX1:int = Math.round(diagX1);
                var pixelDiagY1:int = Math.round(diagY1);
                
                if (pixelDiagX1 >= 0 && pixelDiagX1 < width && 
                    pixelDiagY1 >= 0 && pixelDiagY1 < height)
                {
                    pixelValues.push(bmd.getPixel(pixelDiagX1, pixelDiagY1));
                }
                else
                {
                    pixelValues.push(0);
                }
            }
            
            // 4. 副对角线 (从右上到左下)
            var diag2StartX:Number = width - 1;
            var diag2StepX:Number = -(diag2StartX / 9);
            var diag2StepY:Number = (height - 1) / 9;
            
            for (i = 0; i < 10; i++)
            {
                var diagX2:Number = diag2StartX + diag2StepX * i;
                var diagY2:Number = diag2StepY * i;
                var pixelDiagX2:int = Math.round(diagX2);
                var pixelDiagY2:int = Math.round(diagY2);
                
                if (pixelDiagX2 >= 0 && pixelDiagX2 < width && 
                    pixelDiagY2 >= 0 && pixelDiagY2 < height)
                {
                    pixelValues.push(bmd.getPixel(pixelDiagX2, pixelDiagY2));
                }
                else
                {
                    pixelValues.push(0);
                }
            }
            
            // 构建哈希字符串: 宽,高,像素值1,像素值2,...
            var hash:String = width + "," + height;
            for each (var pixel:int in pixelValues)
            {
                hash += "," + pixel;
            }
            
            return hash;
        }
        
        /**
         * 从显示对象获取哈希值
         * @param target 显示对象
         * @param scale 缩放比例（可选，用于控制精度）
         * @return 哈希字符串
         */
        public static function getHashFromDisplayObject(target:DisplayObject, scale:Number = 1.0):String
        {
            if (!target) return "";
            
            // 获取显示对象的边界
            var bounds = target.getBounds(target);
            if (bounds.width <= 0 || bounds.height <= 0) return "";
            
            // 创建临时的位图数据
            var bmd:BitmapData = new BitmapData(
                Math.ceil(bounds.width * scale), 
                Math.ceil(bounds.height * scale), 
                true, 0x00FFFFFF
            );
            
            try
            {
                // 创建变换矩阵
                var matrix:Matrix = new Matrix();
                matrix.translate(-bounds.x, -bounds.y);
                matrix.scale(scale, scale);
                
                // 将显示对象绘制到位图上
                bmd.draw(target, matrix, null, null, null, true);
                
                // 获取哈希值
                return getHash(bmd);
            }
            catch (error:Error)
            {
                trace("获取哈希值失败:", error.message);
                return "";
            }
            finally
            {
                // 清理资源
                if (bmd)
                {
                    bmd.dispose();
                }
            }
			return "";
        }
        
        /**
         * 比较两个哈希字符串的相似度
         * @param hash1 第一个哈希
         * @param hash2 第二个哈希
         * @return 相似度百分比 (0-1)
         */
        public static function compareHash(hash1:String, hash2:String):Number
        {
            if (!hash1 || !hash2) return 0;
            
            var hash1Parts:Array = hash1.split(",");
            var hash2Parts:Array = hash2.split(",");
            
            // 检查宽高是否匹配
            if (hash1Parts.length < 2 || hash2Parts.length < 2) return 0;
            
            // 如果宽高差异太大，直接认为不相似
            var width1:int = parseInt(hash1Parts[0]);
            var height1:int = parseInt(hash1Parts[1]);
            var width2:int = parseInt(hash2Parts[0]);
            var height2:int = parseInt(hash2Parts[1]);
            
            var widthRatio:Number = Math.min(width1, width2) / Math.max(width1, width2);
            var heightRatio:Number = Math.min(height1, height2) / Math.max(height1, height2);
            
            if (widthRatio < 0.8 || heightRatio < 0.8) return 0;
            
            // 比较像素点
            var matchCount:int = 0;
            var totalPoints:int = Math.min(hash1Parts.length, hash2Parts.length) - 2;
            
            for (var i:int = 2; i < Math.min(hash1Parts.length, hash2Parts.length); i++)
            {
                var pixel1:int = parseInt(hash1Parts[i]);
                var pixel2:int = parseInt(hash2Parts[i]);
                
                // 允许一定的颜色差异
                if (Math.abs(pixel1 - pixel2) < 0x101010) // 约RGB各16的差异
                {
                    matchCount++;
                }
            }
            return matchCount / totalPoints;
        }
    }
}