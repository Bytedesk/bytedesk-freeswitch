#!/bin/bash

echo "=== FreeSWITCH 通话功能测试 ==="
echo "时间: $(date)"
echo ""

# 检查FreeSWITCH进程状态
echo "1. 检查FreeSWITCH进程状态:"
if pgrep -f freeswitch > /dev/null; then
    echo "   ✓ FreeSWITCH 正在运行"
    echo "   进程ID: $(pgrep -f freeswitch)"
else
    echo "   ✗ FreeSWITCH 未运行"
    exit 1
fi

# 检查SIP端口监听状态
echo ""
echo "2. 检查SIP端口监听状态:"
if netstat -tlnp | grep ":5060" > /dev/null; then
    echo "   ✓ SIP端口5060正在监听"
    netstat -tlnp | grep ":5060"
else
    echo "   ✗ SIP端口5060未监听"
fi

# 检查RTP端口范围
echo ""
echo "3. 检查RTP端口范围:"
if netstat -tlnp | grep -E ":(16384|16385|16386)" > /dev/null; then
    echo "   ✓ RTP端口范围正常"
else
    echo "   - RTP端口范围检查中..."
fi

# 检查配置文件
echo ""
echo "4. 检查配置文件:"
if [ -f "conf/sip_profiles/internal.xml" ]; then
    echo "   ✓ internal.xml 配置文件存在"
else
    echo "   ✗ internal.xml 配置文件不存在"
fi

if [ -f "conf/dialplan/default.xml" ]; then
    echo "   ✓ default.xml 拨号计划存在"
else
    echo "   ✗ default.xml 拨号计划不存在"
fi

if [ -f "conf/dialplan/default/user_calling.xml" ]; then
    echo "   ✓ user_calling.xml 用户通话配置存在"
else
    echo "   ✗ user_calling.xml 用户通话配置不存在"
fi

# 检查用户目录
echo ""
echo "5. 检查用户目录:"
if [ -f "conf/directory/default/1001.xml" ]; then
    echo "   ✓ 用户1001配置存在"
else
    echo "   ✗ 用户1001配置不存在"
fi

if [ -f "conf/directory/default/1002.xml" ]; then
    echo "   ✓ 用户1002配置存在"
else
    echo "   ✗ 用户1002配置不存在"
fi

# 检查日志中的错误
echo ""
echo "6. 检查最近的日志错误:"
echo "   最近的错误信息:"
tail -50 log/freeswitch.log | grep -E "(ERROR|WARNING|FAIL|error|fail)" | tail -5

# 检查拨号计划加载
echo ""
echo "7. 检查拨号计划加载状态:"
echo "   拨号计划加载信息:"
tail -100 log/freeswitch.log | grep -E "(dialplan|extension|context)" | tail -3

echo ""
echo "=== 测试完成 ==="
echo ""
echo "如果所有检查都通过，现在可以测试:"
echo "1. 1001 拨打 9196 (回声测试)"
echo "2. 1001 拨打 1002 (用户间通话)"
echo ""
echo "注意: 确保SIP客户端已正确配置并注册到FreeSWITCH"
