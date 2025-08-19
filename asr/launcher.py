#!/usr/bin/env python3
"""
ASR服务启动器
"""
import sys


def start_webservice():
    """启动ASR Web服务"""
    try:
        from app.webservice import start
        
        # 设置命令行参数
        sys.argv = ['launcher.py', '--host', '0.0.0.0', '--port', '9000']
        
        # 启动服务
        start()
        
    except KeyboardInterrupt:
        print("服务已停止")
    except Exception as e:
        print(f"启动失败: {e}")
        import traceback
        traceback.print_exc()


def main():
    """主函数"""
    start_webservice()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("用户中断")
    except Exception as e:
        print(f"启动器出错: {e}")
        import traceback
        traceback.print_exc() 