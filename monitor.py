#!/usr/bin/env python3
import logging
import psutil
import time

# ===== 设置日志 =====
def setup_logging():
    """配置日志系统"""
    # 创建logger - 日志记录器
    logger = logging.getLogger("SystemManager")

    # 设置日志级别为INFO，只记录INFO及以上级别的信息
    # 如果设为DEBUG，会记录所有信息（包括DEBUG）
    logger.setLevel(logging.INFO)
    # logger.setLevel(logging.WARNING)

    # 2、创建文件处理器（写日志到文件）
    file_handler = logging.FileHandler("system-manager.log",encoding="utf-8")

    # 3、创建控制台处理器（同时在屏幕上显示）
    # # StreamHandler就像"屏幕快递员"，负责把日志显示在屏幕上
    console_handler = logging.StreamHandler()

    # 4. 设置日志格式
    """
         %(asctime)s：时间，如"2024-01-15 10:30:00"

         %(name)s：logger名称，如"SystemMonitor"

         %(levelname)s：日志级别，如"INFO"、"WARNING"

         %(message)s：日志内容，如"CPU使用率: 45.2%"  或者传入其他参数
       """
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    #  Formatter就像"信封格式"，规定日志怎么写
    # 告诉两个"快递员"都用这个格式
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    # 5. 添加处理器到logger
    logger.addHandler(file_handler)  # 告诉邮局：有文件快递员
    logger.addHandler(console_handler)  # 告诉邮局：有屏幕快递员

    #  # 返回配置好的logger
    return logger


"""创建监控类 记录查询的信息并记录"""
class SimpleMonitor:
    # # 保存logger，以后都用它记录日志
    def __init__(self,logger):
        self.logger = logger

    # 检查CPU
    def check_cpu(self):
        # interval=1：采样1秒内的CPU平均使用率
        cpu_usage = psutil.cpu_percent(interval=1)
        self.logger.info(f"CPU使用率：{cpu_usage}%")

        if cpu_usage > 90:
            self.logger.info(f"CPU使用率过高: {cpu_usage}%")

        return cpu_usage

    # 检查内存
    def check_memory(self):
        # 获取内存信息对象
        memory = psutil.virtual_memory()
        self.logger.info(f"内存使用率：{memory.percent}%")

        if memory.percent > 90:
            self.logger.info(f"内存使用率过高: {memory.percent}%")

        return memory.percent

    # 检查磁盘
    def check_disk(self):
        alerts = []  # 存储磁盘告警信息
        for  partition in psutil.disk_partitions(all=True):
            try:
                usage = psutil.disk_usage(partition.mountpoint)  # 获取分区使用信息
                self.logger.info(f"磁盘 {partition.mountpoint} 使用率: {usage.percent}%")

                if usage.percent > 90:
                    alert = f"磁盘 {partition.mountpoint} 空间不足: {usage.percent}%"
                    self.logger.warning(alert)  #如果空间不够就会报warning警告信息，可能有潜在问题
                    alerts.append(alert)

            except PermissionError:
                # 明确捕获权限异常，避免静默忽略所有异常（更严谨）
                self.logger.info(f"⚠️  无权限访问分区 {partition.mountpoint}，跳过")
                continue
            except Exception as e:
                # 捕获其他未知异常并打印提示
                self.logger.info(f"❌ 访问分区 {partition.mountpoint} 失败：{str(e)}，跳过")
                continue
        return  alerts

if __name__ == "__main__":
    # 1. 初始化日志
    logger = setup_logging()
    logger.info("%s", "="*50)
    logger.info("=== 监控系统启动 ===")
    logger.info("日志会同时显示在屏幕和保存到文件")

    logger.info("="*50)
    # 2. 创建监控器实例   将日志传入进去监控
    monitor = SimpleMonitor(logger)

    try:
        for i in range(1,3):
            logger.info(f"第{i}次检查")
            # 3. 执行各项检查
            cpu = monitor.check_cpu()
            memory = monitor.check_memory()
            disk_alerts = monitor.check_disk()

            # 4. 汇总异常：CPU/内存/磁盘任一异常则告警
            if disk_alerts or cpu > 90 or memory > 90:
                logger.warning("本次检查发现异常")
            else:
                logger.info("本次检查一切正常")

            logger.info(f"检查完成，等待3秒...")
            time.sleep(3)  # 间隔5秒

    except KeyboardInterrupt:  # 捕获用户Ctrl+C中断
        logger.info("用户中断监控")
    finally:  # 无论是否异常，最终都会执行
        logger.info("=== 监控系统停止 ===")
        logger.info("%s", "=" * 50)
        logger.info("📝 日志已保存到 system_monitor.log")
        logger.info("用以下命令查看日志:")
        logger.info("cat system_monitor.log")
        logger.info("%s", "=" * 50)