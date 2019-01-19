# !/bin/bash

# 手动打包使用方法:
# Step1 : 将HSBAutomation整个文件夹拖入到项目根目录
# Step2 : 打开HSBAutoPackageScript.sh文件,修改 "项目自定义部分", 配置好项目参数
# Step3 : 打开终端, cd到HSBAutomation文件夹 (ps:在终端中先输入cd, 直接拖入HSBAutomation文件夹, 回车)
# Step4 : 输入命令: "sh HSBAutoPackageScript.sh" 回车, 开始执行此打包脚本


# ===============================项目自定义部分(自定义好下列参数后再执行该脚本)============================= #

# 计时
SECONDS=0
# 是否编译工作空间 (例:若是用Cocopods管理的.xcworkspace项目,赋值true;用Xcode默认创建的.xcodeproj,赋值false)
is_workspace="true"

# 指定项目的scheme名称
# (注意: 因为shell定义变量时,=号两边不能留空格,若scheme_name与info_plist_name有空格,脚本运行会失败)
scheme_name="HSBATM"

# 工程中Target对应的配置plist文件名称, Xcode默认的配置文件为Info.plist
info_plist_name="Info"

# 指定要打包编译的方式 : Release,Debug...
build_configuration="Release"


# ===============================自动打包部分(如果Info.plist文件位置有变动需要修改"info_plist_path")============================= #

# 导出ipa所需要的plist文件路径 (默认打企业包: "EnterpriseExportOptionsPlist.plist", 如果需要打包上传AppStore则是: "AppStoreExportOptionsPlist.plist")
ExportOptionsPlistPath="./HSBAutomation/EnterpriseExportOptionsPlist.plist"

# 返回上一级目录,进入项目工程目录
cd ..

# 获取项目名称
project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

# 获取版本号,内部版本号,bundleID
info_plist_path="$project_name/SupportingFiles/$info_plist_name.plist"
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $info_plist_path`
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $info_plist_path`
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $info_plist_path`

#时间戳
formattedDate=$(date "+%Y%m%d%H%M%S")

# 指定输出ipa名称 : 项目名字 + 分支名字 + 版本号 + 时间戳
ipa_name="$scheme_name-${GIT_BRANCH#*/}-V$bundle_version-$formattedDate"

# 删除旧.xcarchive文件
#rm -rf ~/Desktop/$scheme_name-IPA/$scheme_name.xcarchive

# 指定输出ipa路径
export_path=~/IPA/$scheme_name/$ipa_name

# 指定输出归档文件地址
export_archive_path="$export_path/$ipa_name.xcarchive"

# 指定输出ipa地址
export_ipa_path="$export_path"


# AdHoc,AppStore,Enterprise三种打包方式的区别: http://blog.csdn.net/lwjok2007/article/details/46379945
echo "\033[请选择打包方式(输入序号, 按回车即可)]\033"
echo "\033[1. AdHoc       ]\033"
echo "\033[2. AppStore    ]\033"
echo "\033[3. Enterprise  ]\033"
echo "\033[4. Development ]\033"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
# if [ -n "$method" ]
# then
#     if [ "$method" = "1" ] ; then
#     ExportOptionsPlistPath="./HSBAutomation/AdHocExportOptionsPlist.plist"
#     elif [ "$method" = "2" ] ; then
#     ExportOptionsPlistPath="./HSBAutomation/AppStoreExportOptionsPlist.plist"
#     elif [ "$method" = "3" ] ; then
#     ExportOptionsPlistPath="./HSBAutomation/EnterpriseExportOptionsPlist.plist"
#     elif [ "$method" = "4" ] ; then
#     ExportOptionsPlistPath="./HSBAutomation/DevelopmentExportOptionsPlist.plist"
#     else
#     echo "输入的参数无效!!!"
#     exit 1
#     fi
# fi

echo "\033[*************************  开始构建项目  *************************]\033"
# 指定输出文件目录不存在则创建
if [ -d "$export_path" ] ; then
echo $export_path
else
mkdir -pv $export_path
fi

# 判断编译的项目类型是workspace还是project
if $is_workspace ; then
# 编译前清理工程
xcodebuild clean -workspace ${project_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${project_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
else
# 编译前清理工程
xcodebuild clean -project ${project_name}.xcodeproj \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -project ${project_name}.xcodeproj \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
fi

#  检查是否构建成功
#  xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$export_archive_path" ] ; then
echo "\033[项目构建成功 🚀 🚀 🚀] \033"
else
echo "\033[项目构建失败 😢 😢 😢] \033"
exit 1
fi

echo "\033[*************************  开始导出ipa文件  *************************]\033"
xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${ExportOptionsPlistPath}

# 修改ipa文件名称
mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

# 检查文件是否存在
if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
echo "\033[导出 ${ipa_name}.ipa 包成功 🎉  🎉  🎉 ]\033"
open $export_path
else
echo "\033[导出 ${ipa_name}.ipa 包失败 😢 😢 😢 ]\033"

# 相关的解决方法
echo "\033[PS:以下类型的错误可以参考对应的链接]\033"
echo "\033[1.\"error: exportArchive: No applicable devices found.\" --> 可能是ruby版本过低导致,升级最新版ruby再试,升级方法自行百度/谷歌,GitHub issue: https://github.com/jkpang/HSBAutomation/issues/1#issuecomment-297589697"
echo "\033[2.\"No valid iOS Distribution signing identities belonging to team 6F4Q87T7VD were found.\" --> http://fight4j.github.io/2016/11/21/xcodebuild/]\033"
exit 1
fi
# 输出打包总用时
echo "\033[使用HSBAutomation打包总用时: ${SECONDS}s]\033"



# ============================上传到蒲公英部分(如需修改请自行替换蒲公英API Key和User Key)================================ #

echo "\033[*************************  上传到蒲公英  *************************]\033"
# open $export_path

# 蒲公英上的User Key
uKey="30fba42c76c0d492b8fb1e363d2152a2"
 
# 蒲公英上的API Key
apiKey="40d4ceb3c6feabdbde9cdbbe95bb8b8f"
 
# 要上传的ipa文件路径
IPA_PATH="$export_ipa_path/$ipa_name.ipa"
 
# 本机开机密码
PASSWORD="123456"

MSG=git log -1 --pretty=%B
 
# 执行上传至蒲公英的命令
echo "[************************* uploading *************************]"

curl -F "file=@${IPA_PATH}" -F "uKey=${uKey}" -F "_api_key=${apiKey}" -F "updateDescription=${MSG}" -F "password=${PASSWORD}" http://www.pgyer.com/apiv1/app/upload


